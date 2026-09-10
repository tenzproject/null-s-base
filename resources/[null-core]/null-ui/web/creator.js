// Character Creator JavaScript
let creatorData = {};
let currentCreatorCategory = 'identity';

function initCreator() {
    // Set identity panel as narrower by default
    $('.creator .main-panel').addClass('identity-panel');
    
    // Initialize creator navigation
    $('.creator .sidebar li').off('click').on('click', function() {
        const category = $(this).data('category');
        if (!category) return;
        
        // Update active state
        $('.creator .sidebar li').removeClass('active');
        $(this).addClass('active');
        
        // Show/hide category content
        $('.creator .category-content').addClass('hidden');
        $(`#section-${category}`).removeClass('hidden');
        
        currentCreatorCategory = category;
        
        // Toggle narrower panel for identity section
        if (category === 'identity') {
            $('.creator .main-panel').addClass('identity-panel');
        } else {
            $('.creator .main-panel').removeClass('identity-panel');
        }
        
        // Notify server of category change
        $.post('https://' + GetParentResourceName() + '/creatorCategoryChange', JSON.stringify({
            category: category
        }));
    });
    
    // Camera buttons
    $('.creator .cam-btn').off('click').on('click', function() {
        const cam = $(this).data('cam');
        $('.creator .cam-btn').removeClass('active');
        $(this).addClass('active');
        
        $.post('https://' + GetParentResourceName() + '/creatorCameraChange', JSON.stringify({
            camera: cam
        }));
    });
    
    // Sex selector - uses charInfo callback
    $('.sex-btn').off('click').on('click', function() {
        const sex = $(this).data('sex');
        $('.sex-btn').removeClass('active');
        $(this).addClass('active');
        
        $.post('https://' + GetParentResourceName() + '/charInfo', JSON.stringify({
            sex: parseInt(sex)
        }));
    });
    
    // Height slider
    $('#height').off('input').on('input', function() {
        const value = $(this).val();
        $(this).siblings('.range-value').text(value + 'cm');
        
        $.post('https://' + GetParentResourceName() + '/updateHeight', JSON.stringify({
            height: parseInt(value)
        }));
    });
    
    // Face sliders - send directly to the specific callback based on type
    $('.face-slider').off('input').on('input', function() {
        const type = $(this).data('type');
        const rawValue = parseFloat($(this).val());
        const normalizedValue = rawValue / 100.0;
        $(this).siblings('.range-value').text(Math.round(rawValue));
        
        $.post('https://' + GetParentResourceName() + '/' + type, JSON.stringify(normalizedValue));
    });
    
    // Face mix slider
    $('#faceMix').off('input').on('input', function() {
        const value = $(this).val();
        $(this).siblings('.range-value').text(Math.round(value * 100) + '%');
        
        $.post('https://' + GetParentResourceName() + '/faceMix', JSON.stringify(parseFloat(value)));
    });
    
    // Style sliders
    $('#hair-style-slider').off('input').on('input', function() {
        const value = parseInt($(this).val());
        $('#hair-style-value').text(value);
        $.post('https://' + GetParentResourceName() + '/hairstyle', JSON.stringify(value));
    });
    
    $('#beard-style-slider').off('input').on('input', function() {
        const value = parseInt($(this).val());
        $('#beard-style-value').text(value);
        $.post('https://' + GetParentResourceName() + '/beardStyle', JSON.stringify(value));
    });
    
    $('#eyebrow-style-slider').off('input').on('input', function() {
        const value = parseInt($(this).val());
        $('#eyebrow-style-value').text(value);
        $.post('https://' + GetParentResourceName() + '/eyebrowStyle', JSON.stringify(value));
    });
    
    $('#chest-hair-style-slider').off('input').on('input', function() {
        const value = parseInt($(this).val());
        $('#chest-hair-style-value').text(value);
        $.post('https://' + GetParentResourceName() + '/chestHair', JSON.stringify(value));
    });
    
    $('#blemishes-style-slider').off('input').on('input', function() {
        const value = parseInt($(this).val());
        $('#blemishes-style-value').text(value);
        $.post('https://' + GetParentResourceName() + '/blemishesStyle', JSON.stringify(value));
    });
    
    $('#lipstick-style-slider').off('input').on('input', function() {
        const value = parseInt($(this).val());
        $('#lipstick-style-value').text(value);
        $.post('https://' + GetParentResourceName() + '/lipstickStyle', JSON.stringify(value));
    });
    
    // Beard opacity
    $('#beard-opacity').off('input').on('input', function() {
        const value = $(this).val();
        $(this).siblings('.range-value').text(value + '%');
        
        $.post('https://' + GetParentResourceName() + '/beard-opacity', JSON.stringify(parseInt(value)));
    });
    
    // Eyebrows opacity
    $('#eyebrows-opacity').off('input').on('input', function() {
        const value = $(this).val();
        $(this).siblings('.range-value').text(value + '%');
        
        $.post('https://' + GetParentResourceName() + '/eyebrows-opacity', JSON.stringify(parseInt(value)));
    });
    
    // Chest hair opacity
    $('#chest-hair-opacity').off('input').on('input', function() {
        const value = $(this).val();
        $(this).siblings('.range-value').text(value + '%');
        
        $.post('https://' + GetParentResourceName() + '/chest-hair-opacity', JSON.stringify(parseInt(value)));
    });
    
    // Blemishes opacity
    $('#blemishes-opacity').off('input').on('input', function() {
        const value = $(this).val();
        $(this).siblings('.range-value').text(value + '%');
        
        $.post('https://' + GetParentResourceName() + '/blemishes-opacity', JSON.stringify(parseInt(value)));
    });
    
    // Lipstick opacity
    $('#lipstick-opacity').off('input').on('input', function() {
        const value = $(this).val();
        $(this).siblings('.range-value').text(value + '%');
        
        $.post('https://' + GetParentResourceName() + '/lipstick-opacity', JSON.stringify(parseInt(value)));
    });
    
    $(document).on('click', '#outfits-grid .grid-item', function() {
        $('#outfits-grid .grid-item').removeClass('selected');
        $(this).addClass('selected');
        
        $.post('https://' + GetParentResourceName() + '/updateFeature', JSON.stringify({
            feature: 'outfits-grid',
            value: $(this).data('value')
        }));
    });
    
    // Reset button
    $('#resetCreator').off('click').on('click', function() {
        $.post('https://' + GetParentResourceName() + '/resetCreator', JSON.stringify({}));
    });

    // Finish button
    $('#finishCreator').off('click').on('click', function() {
        const firstname = $('#firstname').val();
        const lastname = $('#lastname').val();
        const birthdate = $('#birthdate').val();
        
        if (!firstname || !lastname || !birthdate) {
            boutiqueManager.notification("Veuillez remplir tous les champs obligatoires");
            return;
        }
        
        $.post('https://' + GetParentResourceName() + '/finishCreator', JSON.stringify({
            firstname: firstname,
            lastname: lastname,
            birthdate: birthdate,
            data: creatorData
        }));
    });
    
    // Generate heritage grids
    generateHeritageGrids();
    generateColorGrids();
    generateEyeColors();
    generateOutfits();
}

function updateOutfitsGrid(outfits) {
    const outfitsGrid = $('#outfits-grid');
    outfitsGrid.empty();
    Object.entries(outfits).forEach(([key, outfit]) => {
        outfitsGrid.append(`
            <div class="grid-item" data-value="${key}">
                <img src="images/outfits/${playerSex}/${key}.webp" alt="Tenue ${key}">
            </div>
        `);
    });
}

window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'updateCreatorData') {
        if (data.outfits) {
            updateOutfitsGrid(data.outfits);
        }
    }
});


window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'updateCreatorData') {
        if (data.gender) {
            if (data.gender === "m") {
                playerSex = "male";
            } else if (data.gender === "f") {
                playerSex = "female";
            }
        }

        if (data.outfits) {
            updateOutfitsGrid(data.outfits);
        }

        if (data.maxValues) {
            updateMaxValues(data.maxValues);
        }
    }
}); 

function updateMaxValues(maxValues) {
    const sliderMap = {
        hairstyle: { slider: '#hair-style-slider', value: '#hair-style-value' },
        beard: { slider: '#beard-style-slider', value: '#beard-style-value' },
        eyebrows: { slider: '#eyebrow-style-slider', value: '#eyebrow-style-value' },
        chestHair: { slider: '#chest-hair-style-slider', value: '#chest-hair-style-value' },
        blemishes: { slider: '#blemishes-style-slider', value: '#blemishes-style-value' },
        lipstickStyle: { slider: '#lipstick-style-slider', value: '#lipstick-style-value' }
    };
    
    for (const [key, ids] of Object.entries(sliderMap)) {
        if (maxValues[key] !== undefined) {
            const slider = $(ids.slider);
            slider.attr('max', maxValues[key]);
            if (parseInt(slider.val()) > maxValues[key]) {
                slider.val(0);
                $(ids.value).text('0');
            }
        }
    }
}


function generateHeritageGrids() {
    // GTA V parent names mapped to heritage image filenames
    const fatherNames = [
        'Benjamin', 'Daniel', 'Joshua', 'Noah', 'Andrew',
        'Juan', 'Alex', 'Isaac', 'Evan', 'Ethan',
        'Vincent', 'Angel', 'Diego', 'Adrian', 'Gabriel',
        'Michael', 'Santiago', 'Kevin', 'Louis', 'Samuel',
        'Anthony', 'Claude', 'Niko', 'John'
    ];
    
    const motherNames = [
        'Hannah', 'Audrey', 'Jasmine', 'Giselle', 'Amelia',
        'Isabella', 'Zoe', 'Ava', 'Camila', 'Violet',
        'Sophia', 'Evelyn', 'Nicole', 'Ashley', 'Grace',
        'Brianna', 'Natalie', 'Olivia', 'Avery', 'Elizabeth',
        'Charlotte', 'Emma', 'Misty'
    ];

    // Heritage image filename lookup
    const heritageImages = {};
    const allHeritage = [
        'CharacterCreator-GTAO-Parent-Male-Adrian-CSzS7KUi.png',
        'CharacterCreator-GTAO-Parent-Male-Alex-Bok7s0XD.png',
        'CharacterCreator-GTAO-Parent-Male-Andrew-Cj0N5SMr.png',
        'CharacterCreator-GTAO-Parent-Male-Angel-dhRSJSTv.png',
        'CharacterCreator-GTAO-Parent-Male-Anthony-BFTI4PDs.png',
        'CharacterCreator-GTAO-Parent-Male-Benjamin-C1CN4zvZ.png',
        'CharacterCreator-GTAO-Parent-Male-Claude-DIKAgmXk.png',
        'CharacterCreator-GTAO-Parent-Male-Daniel-BHzM6IXW.png',
        'CharacterCreator-GTAO-Parent-Male-Diego-DuGYmLdN.png',
        'CharacterCreator-GTAO-Parent-Male-Ethan-ibukmW9T.png',
        'CharacterCreator-GTAO-Parent-Male-Evan-DQiBrDeu.png',
        'CharacterCreator-GTAO-Parent-Male-Gabriel-BKzqh_xd.png',
        'CharacterCreator-GTAO-Parent-Male-Isaac-D_uV5yGp.png',
        'CharacterCreator-GTAO-Parent-Male-John-CpCfz2Ey.png',
        'CharacterCreator-GTAO-Parent-Male-Joshua-Dkol9-0v.png',
        'CharacterCreator-GTAO-Parent-Male-Juan-BHareFhc.png',
        'CharacterCreator-GTAO-Parent-Male-Kevin-DYDxO4Si.png',
        'CharacterCreator-GTAO-Parent-Male-Louis-BFxkSGS0.png',
        'CharacterCreator-GTAO-Parent-Male-Michael-DDbXVQ2L.png',
        'CharacterCreator-GTAO-Parent-Male-Niko-CC1a4mep.png',
        'CharacterCreator-GTAO-Parent-Male-Noah-Bj1cSF7D.png',
        'CharacterCreator-GTAO-Parent-Male-Samuel-CrDxS97X.png',
        'CharacterCreator-GTAO-Parent-Male-Santiago-hqWmHXQb.png',
        'CharacterCreator-GTAO-Parent-Male-Vincent-uDhbkPgI.png',
        'CharacterCreator-GTAO-Parent-Female-Amelia-CZFWXTO2.png',
        'CharacterCreator-GTAO-Parent-Female-Ashley-DNtz2M4Y.png',
        'CharacterCreator-GTAO-Parent-Female-Audrey-B6u_8ume.png',
        'CharacterCreator-GTAO-Parent-Female-Ava-BHNcd7Sk.png',
        'CharacterCreator-GTAO-Parent-Female-Brianna-Bg3-hTMU.png',
        'CharacterCreator-GTAO-Parent-Female-Camila-PLwPW9HL.png',
        'CharacterCreator-GTAO-Parent-Female-Charlotte-dYcKWPaI.png',
        'CharacterCreator-GTAO-Parent-Female-Elizabeth-B7-qIrOq.png',
        'CharacterCreator-GTAO-Parent-Female-Emma-muOrblXv.png',
        'CharacterCreator-GTAO-Parent-Female-Evelyn-DT7PStFk.png',
        'CharacterCreator-GTAO-Parent-Female-Giselle-BOMc0mWW.png',
        'CharacterCreator-GTAO-Parent-Female-Grace-C5hsdwN8.png',
        'CharacterCreator-GTAO-Parent-Female-Hannah-B6yFivh8.png',
        'CharacterCreator-GTAO-Parent-Female-Isabella-DWpUCbBa.png',
        'CharacterCreator-GTAO-Parent-Female-Jasmine-DYeuHw8V.png',
        'CharacterCreator-GTAO-Parent-Female-Misty-Cpy7Nvuu.png',
        'CharacterCreator-GTAO-Parent-Female-Natalie-CZP5GtIX.png',
        'CharacterCreator-GTAO-Parent-Female-Nicole-DIs67_JI.png',
        'CharacterCreator-GTAO-Parent-Female-Olivia-ChV1ttn9.png',
        'CharacterCreator-GTAO-Parent-Female-Sophia-B5GPRRdP.png',
        'CharacterCreator-GTAO-Parent-Female-Violet-CCkWvSjr.png',
        'CharacterCreator-GTAO-Parent-Female-Zoe-CarTP6Jt.png'
    ];
    allHeritage.forEach(f => {
        const match = f.match(/Parent-(Male|Female)-(\w+)-/);
        if (match) heritageImages[match[1] + '-' + match[2]] = f;
    });

    function getHeritageImg(gender, name) {
        const key = gender + '-' + name;
        return heritageImages[key] ? 'images/heritage/' + heritageImages[key] : '';
    }

    // Face father grid
    const faceFatherGrid = $('#face-father-grid');
    faceFatherGrid.empty();
    fatherNames.forEach((name, i) => {
        const index = i;
        const imgSrc = getHeritageImg('Male', name);
        const item = $(`<div class="parent-item" data-value="${index}"><img src="${imgSrc}" alt="${name}"><span class="parent-name">${name}</span></div>`);
        item.on('click', function() {
            faceFatherGrid.find('.parent-item').removeClass('active');
            $(this).addClass('active');
            $.post('https://' + GetParentResourceName() + '/faceFather', JSON.stringify(index));
        });
        faceFatherGrid.append(item);
    });
    
    // Face mother grid
    const faceMotherGrid = $('#face-mother-grid');
    faceMotherGrid.empty();
    motherNames.forEach((name, i) => {
        const index = i;
        const imgSrc = getHeritageImg('Female', name);
        const item = $(`<div class="parent-item" data-value="${index}"><img src="${imgSrc}" alt="${name}"><span class="parent-name">${name}</span></div>`);
        item.on('click', function() {
            faceMotherGrid.find('.parent-item').removeClass('active');
            $(this).addClass('active');
            $.post('https://' + GetParentResourceName() + '/faceMother', JSON.stringify(index));
        });
        faceMotherGrid.append(item);
    });
    
    // Skin tone grid
    const skinToneGrid = $('#skin-tone-grid');
    skinToneGrid.empty();
    for (let i = 0; i < 46; i++) {
        const index = i;
        const item = $(`<div class="parent-item" data-value="${index}" style="background-color: hsl(${30 - index * 0.5}, ${50 + index}%, ${70 - index}%);"></div>`);
        item.on('click', function() {
            skinToneGrid.find('.parent-item').removeClass('active');
            $(this).addClass('active');
            $.post('https://' + GetParentResourceName() + '/skinTone', JSON.stringify(index));
        });
        skinToneGrid.append(item);
    }
}

function generateColorGrids() {
    generateColorGrid('#hair-color-grid', 'hairColor');
    generateColorGrid('#hair-highlight-grid', 'hairHighlight');
    generateColorGrid('#beard-color-grid', 'beardColor');
    generateColorGrid('#eyebrow-color-grid', 'eyebrowColor');
    generateColorGrid('#chest-hair-color-grid', 'chestHairColor');
    generateColorGrid('#lipstick-color-grid', 'lipstickColor');
}

function generateEyeColors() {
    const eyeColorGrid = $('#eye-color-grid');
    eyeColorGrid.empty();
    const eyeColors = [
        '#8B4513', '#654321', '#4A3728', '#2C1810',
        '#1E90FF', '#4169E1', '#0000CD', '#000080',
        '#228B22', '#32CD32', '#00FF00', '#ADFF2F',
        '#808080', '#A9A9A9', '#C0C0C0', '#D3D3D3'
    ];
    
    eyeColors.forEach((color, index) => {
        const item = $(`<div class="color-item" data-value="${index}" style="background-color: ${color};"></div>`);
        item.on('click', function() {
            eyeColorGrid.find('.color-item').removeClass('active');
            $(this).addClass('active');
            $.post('https://' + GetParentResourceName() + '/eyeColor', JSON.stringify(index));
        });
        eyeColorGrid.append(item);
    });
}


function generateColorGrid(selector, eventName) {
    const colorGrid = $(selector);
    colorGrid.empty();
    
    const gtaHairColors = [
        '#18191A', '#2B2622', '#5A5751', '#FFFCF1', '#E5C5A5', '#DEB7A5',
        '#C5A587', '#B18C6A', '#A37453', '#8C6342', '#6F4E37', '#4A3728',
        '#3B2F2F', '#1B1B1B', '#1C1C1C', '#1F1F1F', '#2C2C2C', '#3A3A3A',
        '#4A4A4A', '#5C5C5C', '#6E6E6E', '#808080', '#929292', '#A4A4A4',
        '#B6B6B6', '#C8C8C8', '#DADADA', '#ECECEC', '#8B4513', '#A0522D',
        '#CD853F', '#DEB887', '#F4A460', '#D2691E', '#8B0000', '#A52A2A',
        '#B22222', '#DC143C', '#FF0000', '#FF6347', '#FF7F50', '#FFA07A',
        '#E9967A', '#FA8072', '#FFC0CB', '#FFB6C1', '#FF69B4', '#FF1493',
        '#C71585', '#DB7093', '#8B008B', '#9370DB', '#8A2BE2', '#9400D3',
        '#9932CC', '#BA55D3', '#DA70D6', '#EE82EE', '#DDA0DD', '#D8BFD8',
        '#4B0082', '#483D8B'
    ];
    
    const colorsToUse = gtaHairColors.length;
    for (let i = 0; i < colorsToUse; i++) {
        const index = i;
        const color = gtaHairColors[i];
        const item = $(`<div class="color-item" data-value="${index}" style="background-color: ${color};"></div>`);
        item.on('click', function() {
            colorGrid.find('.color-item').removeClass('active');
            $(this).addClass('active');
            $.post('https://' + GetParentResourceName() + '/' + eventName, JSON.stringify(index));
        });
        colorGrid.append(item);
    }
}

function generateOutfits() {
    const outfitsGrid = $('#outfits-grid');
    outfitsGrid.empty();
    
    $.post('https://' + GetParentResourceName() + '/getOutfits', JSON.stringify({}), function(outfits) {
        if (outfits && outfits.length > 0) {
            outfits.forEach((outfit, index) => {
                const item = $(`<div class="grid-item" data-value="${index}">
                    <img src="${outfit.image || 'images/creator/outfits/' + index + '.webp'}" alt="${outfit.label}">
                    <span>${outfit.label}</span>
                </div>`);
                item.on('click', function() {
                    outfitsGrid.find('.grid-item').removeClass('active');
                    $(this).addClass('active');
                    $.post('https://' + GetParentResourceName() + '/selectOutfit', JSON.stringify({ outfit: outfit }));
                });
                outfitsGrid.append(item);
            });
        }
    });
}
