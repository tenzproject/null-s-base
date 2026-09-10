/// <reference types="@citizenfx/server" />

const IJS = require('image-js');
const fs = require('fs');
const path = require('path');

// Base paths - write to own resource directory
const IMAGES_PATH = 'resources/[null-core]/null-cache/images';
const TEMP_PATH = 'resources/[null-core]/null-cache/temp';

// Ensure temp directory exists
try { if (!fs.existsSync(TEMP_PATH)) fs.mkdirSync(TEMP_PATH, { recursive: true }); } catch(e) {}

// ============================================================================
// CACHE VERSION SYSTEM
// ============================================================================

let cacheVersion = Date.now();

function bumpCacheVersion() {
    cacheVersion = Date.now();
    emitNet('null:cache:versionChanged', -1, cacheVersion);
}

onNet('null:cache:requestVersion', () => {
    emitNet('null:cache:versionChanged', source, cacheVersion);
});

exports('getCacheVersion', () => cacheVersion);

// ============================================================================
// HELPERS
// ============================================================================

function ensureDir(dirPath) {
    try {
        if (!fs.existsSync(dirPath)) {
            fs.mkdirSync(dirPath, { recursive: true });
        }
    } catch(e) {
        console.error(`[null-cache] Failed to create dir: ${dirPath}`, e.message);
    }
}

function getTargetPath(type, filename) {
    switch(type) {
        case 'vehicle':
            return `${IMAGES_PATH}/vehicles/${filename}.webp`;
        case 'weapon':
            return `${IMAGES_PATH}/weapons/${filename}.webp`;
        case 'ped':
            return `${IMAGES_PATH}/peds/${filename}.webp`;
        case 'prop':
            return `${IMAGES_PATH}/props/${filename}.webp`;
        case 'clothing':
            return `${IMAGES_PATH}/clothes/${filename}.webp`;
        case 'utils':
            // filename contient déjà "{gender}/{utilsType}/{id_or_nameHash}"
            // ex: "male/hair/12" ou "female/tattoos/MP_Buis_F_Chest_000"
            return `${IMAGES_PATH}/clothes/utils/${filename}.webp`;
        default:
            return `${TEMP_PATH}/${filename}.webp`;
    }
}

function getTempPath(filename) {
    return `${TEMP_PATH}/${filename.replace(/[\/]/g, '_')}_${Date.now()}.png`;
}

async function processAndSave(tempPngPath, finalPath, greenRemoval) {
    try {
        let image = await IJS.Image.load(tempPngPath);

        // Crop to center-right region
        const cropX = Math.floor(image.width / 4.5);
        const cropWidth = Math.min(image.height, image.width - cropX);
        const cropped = image.crop({ x: cropX, width: cropWidth });

        if (greenRemoval) {
            // Remove green screen pixels
            for (let x = 0; x < cropped.width; x++) {
                for (let y = 0; y < cropped.height; y++) {
                    const px = cropped.getPixelXY(x, y);
                    const r = px[0], g = px[1], b = px[2];
                    if (g > r + b) {
                        cropped.setPixelXY(x, y, [255, 255, 255, 0]);
                    }
                }
            }
        }

        // Save as PNG (image-js outputs PNG; CEF detects format from magic bytes)
        ensureDir(path.dirname(finalPath));
        const pngBuffer = cropped.toBuffer({ format: 'png' });
        fs.writeFileSync(finalPath, pngBuffer);

        // Cleanup temp file
        try { fs.unlinkSync(tempPngPath); } catch(e) {}

        return true;
    } catch(e) {
        console.error(`[null-cache] Process error: ${e.message}`);
        try { fs.unlinkSync(tempPngPath); } catch(e2) {}
        return false;
    }
}

// ============================================================================
// SCREENSHOT CAPTURE EVENT
// ============================================================================

onNet('null:imagemaker:capture', async (type, filename, greenRemoval) => {
    const src = source;
    const targetPath = getTargetPath(type, filename);
    const tempPath = getTempPath(filename);

    // Ensure directories exist
    ensureDir(path.dirname(targetPath));
    ensureDir(TEMP_PATH);

    try {
        exports['screenshot-basic'].requestClientScreenshot(
            src,
            {
                fileName: tempPath,
                encoding: 'png',
                quality: 1.0,
            },
            async (err, savedPath) => {
                if (err) {
                    console.error(`[null-cache] Screenshot error: ${err}`);
                    emitNet('null:imagemaker:captureResult', src, false, filename, type);
                    return;
                }

                const processed = await processAndSave(savedPath, targetPath, greenRemoval !== false);
                if (processed) bumpCacheVersion();
                emitNet('null:imagemaker:captureResult', src, processed, filename, type);
            }
        );
    } catch(e) {
        console.error(`[null-cache] Capture error: ${e.message}`);
        emitNet('null:imagemaker:captureResult', src, false, filename, type);
    }
});

// ============================================================================
// SCAN EXISTING IMAGES
// ============================================================================

function scanDirectory(dirPath, extension) {
    const results = [];
    try {
        if (!fs.existsSync(dirPath)) return results;
        const entries = fs.readdirSync(dirPath);
        for (const entry of entries) {
            if (entry.endsWith(extension) || entry.endsWith('.png') || entry.endsWith('.webp')) {
                results.push(entry.replace(/\.(png|webp|jpg)$/i, ''));
            }
        }
    } catch(e) {}
    return results;
}

function scanClothingDir(gender) {
    const basePath = `${IMAGES_PATH}/clothes/${gender}`;
    const result = {};
    try {
        if (!fs.existsSync(basePath)) return result;
        const categories = fs.readdirSync(basePath);
        for (const cat of categories) {
            const catPath = `${basePath}/${cat}`;
            try {
                const stat = fs.statSync(catPath);
                if (stat.isDirectory()) {
                    result[cat] = scanDirectory(catPath, '.webp');
                }
            } catch(e) {}
        }
    } catch(e) {}
    return result;
}

// Scan clothes/utils/{gender}/{type}/*.webp
//   Renvoie { hair: [...], beard: [...], tattoos: [nameHash, ...], ... }
function scanUtilsDir(gender) {
    const basePath = `${IMAGES_PATH}/clothes/utils/${gender}`;
    const result = {};
    try {
        if (!fs.existsSync(basePath)) return result;
        const types = fs.readdirSync(basePath);
        for (const type of types) {
            const typePath = `${basePath}/${type}`;
            try {
                const stat = fs.statSync(typePath);
                if (stat.isDirectory()) {
                    result[type] = scanDirectory(typePath, '.webp');
                }
            } catch(e) {}
        }
    } catch(e) {}
    return result;
}

onNet('null:imagemaker:scanImages', () => {
    const src = source;

    const data = {
        vehicles: scanDirectory(`${IMAGES_PATH}/vehicles`, '.webp'),
        weapons: scanDirectory(`${IMAGES_PATH}/weapons`, '.webp'),
        peds: scanDirectory(`${IMAGES_PATH}/peds`, '.webp'),
        props: scanDirectory(`${IMAGES_PATH}/props`, '.webp'),
        clothing: {
            male: scanClothingDir('male'),
            female: scanClothingDir('female'),
        },
        utils: {
            male: scanUtilsDir('male'),
            female: scanUtilsDir('female'),
        }
    };

    emitNet('null:imagemaker:scanResult', src, data);
});

// ============================================================================
// DELETE IMAGE
// ============================================================================

onNet('null:imagemaker:deleteImage', (type, filename) => {
    const src = source;
    const targetPath = getTargetPath(type, filename);
    const pngPath = targetPath.replace(/\.webp$/, '.png');

    try {
        if (fs.existsSync(targetPath)) fs.unlinkSync(targetPath);
        if (fs.existsSync(pngPath)) fs.unlinkSync(pngPath);
        bumpCacheVersion();
        emitNet('null:imagemaker:deleteResult', src, true, filename, type);
    } catch(e) {
        emitNet('null:imagemaker:deleteResult', src, false, filename, type);
    }
});

console.log('[null-cache] Image server loaded');
