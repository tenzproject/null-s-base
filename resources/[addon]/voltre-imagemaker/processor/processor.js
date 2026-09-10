const chokidar = require('chokidar');
const fs = require('fs').promises;
const path = require('path');
const { removeBackground } = require('@imgly/background-removal-node');

const RAW_IMAGES_DIR = path.join(__dirname, '..', 'raw_images');
const OUTPUT_BASE_DIR = path.join(__dirname, '..', 'images');

const CATEGORY_MAPPING = {
    'hair_male': 'hair/male',
    'hair_female': 'hair/female',
    'beard': 'beard',
    'eyebrows': 'eyebrows',
    'chest_hair': 'chest_hair',
    'lipstick': 'lipstick',
    'tattoos': 'tattoos'
};

let processingQueue = [];
let isProcessing = false;
let stats = {
    processed: 0,
    failed: 0,
    startTime: null
};

async function ensureDirectoryExists(dirPath) {
    try {
        await fs.access(dirPath);
    } catch {
        await fs.mkdir(dirPath, { recursive: true });
        console.log(`✓ Dossier créé: ${dirPath}`);
    }
}

async function deleteFile(filePath) {
    try {
        await fs.unlink(filePath);
        console.log(`🗑️  Fichier supprimé: ${path.basename(filePath)}`);
    } catch (error) {
        console.error(`❌ Erreur lors de la suppression de ${filePath}:`, error.message);
    }
}

function parseFilename(filename) {
    const nameWithoutExt = filename.replace('.png', '');
    const parts = nameWithoutExt.split('_');
    
    if (parts.length < 2) {
        return null;
    }
    
    const category = parts[0];
    let gender = null;
    let index = null;
    
    if (parts.length === 3) {
        gender = parts[1];
        index = parts[2];
    } else if (parts.length === 2) {
        index = parts[1];
    } else {
        return null;
    }
    
    return { category, gender, index };
}

function getOutputPath(category, gender, index) {
    let categoryPath;
    
    if (gender && category === 'hair') {
        categoryPath = CATEGORY_MAPPING[`${category}_${gender}`];
    } else {
        categoryPath = CATEGORY_MAPPING[category];
    }
    
    if (!categoryPath) {
        console.error(`❌ Catégorie inconnue: ${category}`);
        return null;
    }
    
    const outputDir = path.join(OUTPUT_BASE_DIR, categoryPath);
    const outputFile = path.join(outputDir, `${index}.png`);
    
    return { outputDir, outputFile };
}

async function processImage(filePath) {
    const filename = path.basename(filePath);
    console.log(`\n🔄 Traitement: ${filename}`);
    
    try {
        const fileStats = await fs.stat(filePath);
        if (fileStats.size === 0) {
            throw new Error('Fichier vide');
        }
        
        const parsedInfo = parseFilename(filename);
        if (!parsedInfo) {
            throw new Error('Format de nom de fichier invalide');
        }
        
        const { category, gender, index } = parsedInfo;
        const pathInfo = getOutputPath(category, gender, index);
        
        if (!pathInfo) {
            throw new Error('Impossible de déterminer le chemin de sortie');
        }
        
        const { outputDir, outputFile } = pathInfo;
        
        await ensureDirectoryExists(outputDir);
        
        console.log(`   📸 Lecture de l'image...`);
        const imageBuffer = await fs.readFile(filePath);
        
        console.log(`   🎨 Suppression du fond...`);
        const blob = await removeBackground(imageBuffer, {
            model: 'medium',
            output: {
                format: 'png',
                quality: 1.0
            }
        });
        
        const buffer = Buffer.from(await blob.arrayBuffer());
        
        console.log(`   💾 Sauvegarde: ${path.relative(__dirname, outputFile)}`);
        await fs.writeFile(outputFile, buffer);
        
        await deleteFile(filePath);
        
        stats.processed++;
        console.log(`✅ Succès: ${filename} → ${index}.png (${stats.processed} traités)`);
        
        return true;
        
    } catch (error) {
        stats.failed++;
        console.error(`❌ Erreur lors du traitement de ${filename}:`, error.message);
        
        try {
            await deleteFile(filePath);
        } catch (deleteError) {
            console.error(`❌ Impossible de supprimer le fichier corrompu:`, deleteError.message);
        }
        
        return false;
    }
}

async function processQueue() {
    if (isProcessing || processingQueue.length === 0) {
        return;
    }
    
    isProcessing = true;
    const filePath = processingQueue.shift();
    
    await processImage(filePath);
    
    isProcessing = false;
    
    if (processingQueue.length > 0) {
        setTimeout(processQueue, 100);
    } else {
        console.log(`\n📊 Statistiques:`);
        console.log(`   ✅ Traités avec succès: ${stats.processed}`);
        console.log(`   ❌ Échecs: ${stats.failed}`);
        if (stats.startTime) {
            const elapsed = ((Date.now() - stats.startTime) / 1000).toFixed(1);
            console.log(`   ⏱️  Temps écoulé: ${elapsed}s`);
        }
        console.log(`\n👀 En attente de nouvelles images...\n`);
    }
}

function addToQueue(filePath) {
    if (!processingQueue.includes(filePath)) {
        processingQueue.push(filePath);
        
        if (!stats.startTime) {
            stats.startTime = Date.now();
        }
        
        if (!isProcessing) {
            processQueue();
        }
    }
}

async function initialize() {
    console.log('╔════════════════════════════════════════════════════════╗');
    console.log('║     null IMAGE MAKER - Processeur d\'images          ║');
    console.log('╚════════════════════════════════════════════════════════╝\n');
    
    await ensureDirectoryExists(RAW_IMAGES_DIR);
    await ensureDirectoryExists(OUTPUT_BASE_DIR);
    
    for (const [key, value] of Object.entries(CATEGORY_MAPPING)) {
        await ensureDirectoryExists(path.join(OUTPUT_BASE_DIR, value));
    }
    
    console.log('✓ Dossiers initialisés\n');
    
    const existingFiles = await fs.readdir(RAW_IMAGES_DIR);
    const pngFiles = existingFiles.filter(f => f.endsWith('.png'));
    
    if (pngFiles.length > 0) {
        console.log(`📁 ${pngFiles.length} fichier(s) existant(s) détecté(s)\n`);
        for (const file of pngFiles) {
            addToQueue(path.join(RAW_IMAGES_DIR, file));
        }
    }
    
    const watcher = chokidar.watch(RAW_IMAGES_DIR, {
        ignored: /(^|[\/\\])\../,
        persistent: true,
        ignoreInitial: true,
        awaitWriteFinish: {
            stabilityThreshold: 2000,
            pollInterval: 100
        }
    });
    
    watcher.on('add', (filePath) => {
        if (path.extname(filePath) === '.png') {
            console.log(`\n📥 Nouveau fichier détecté: ${path.basename(filePath)}`);
            addToQueue(filePath);
        }
    });
    
    watcher.on('error', (error) => {
        console.error('❌ Erreur du watcher:', error);
    });
    
    console.log('👀 Surveillance active du dossier raw_images/');
    console.log('📌 Appuyez sur Ctrl+C pour arrêter\n');
}

process.on('SIGINT', () => {
    console.log('\n\n🛑 Arrêt du processeur...');
    console.log(`📊 Total traité: ${stats.processed}`);
    console.log(`❌ Total échoué: ${stats.failed}`);
    process.exit(0);
});

process.on('unhandledRejection', (error) => {
    console.error('❌ Erreur non gérée:', error);
});

initialize().catch((error) => {
    console.error('❌ Erreur fatale lors de l\'initialisation:', error);
    process.exit(1);
});
