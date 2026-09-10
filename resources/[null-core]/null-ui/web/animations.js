let animationsData = {
    favorites: [],
    emotes: {},
    dances: {},
    shared: {},
    props: {},
    walks: {},
    expressions: {},
    animals: {}
};

let currentCategory = 'favorites';
let currentAnimation = null;

function initAnimations() {
    
    // Category buttons
    $('.animations .category-btn').off('click').on('click', function() {
        const category = $(this).data('category');
        changeAnimationCategory(category);
    });

    // Close button
    $('#closeAnimations').off('click').on('click', function() {
        closeAnimationsMenu();
    });

    // Stop animation button
    $('#stopAnimation').off('click').on('click', function() {
        $.post('https://' + GetParentResourceName() + '/stopAnimation', JSON.stringify({}));
    });

    // Search functionality
    $('#animationSearch').off('input').on('input', function() {
        const searchTerm = $(this).val().toLowerCase();
        filterAnimations(searchTerm);
    });
}

function changeAnimationCategory(category) {
    currentCategory = category;
    
    // Update active button
    $('.animations .category-btn').removeClass('active');
    $(`.animations .category-btn[data-category="${category}"]`).addClass('active');
    
    // Hide all content sections
    $('.animation-content').hide();
    
    // Show selected category
    $(`#${category}-content`).show();
    
    // Update title
    const titles = {
        'favorites': 'Favoris',
        'emotes': 'Émotes',
        'dances': 'Danses',
        'shared': 'Animations Partagées',
        'props': 'Animations avec Objets',
        'walks': 'Démarches',
        'expressions': 'Expressions Faciales',
        'animals': 'Animations Animaux'
    };
    $('#animationCategoryTitle').text(titles[category] || category);
    
    // Clear search
    $('#animationSearch').val('');
}

function updateAnimationsData(data) {
    if (data.favorites) animationsData.favorites = data.favorites;
    if (data.emotes) animationsData.emotes = data.emotes;
    if (data.dances) animationsData.dances = data.dances;
    if (data.shared) animationsData.shared = data.shared;
    if (data.props) animationsData.props = data.props;
    if (data.walks) animationsData.walks = data.walks;
    if (data.expressions) animationsData.expressions = data.expressions;
    if (data.animals) animationsData.animals = data.animals;
    
    // Populate grids
    populateAnimationGrid('emotes', animationsData.emotes);
    populateAnimationGrid('dances', animationsData.dances);
    populateAnimationGrid('shared', animationsData.shared);
    populateAnimationGrid('props', animationsData.props);
    populateAnimationGrid('walks', animationsData.walks);
    populateAnimationGrid('expressions', animationsData.expressions);
    populateAnimationGrid('animals', animationsData.animals);
    populateFavorites();
}

function populateAnimationGrid(category, animations) {
    const grid = $(`#${category}-grid`);
    grid.empty();
    
    if (!animations || Object.keys(animations).length === 0) {
        grid.append(`
            <div class="empty-state">
                <i class="fas fa-box-open"></i>
                <p>Aucune animation disponible</p>
            </div>
        `);
        return;
    }
    
    for (const [key, anim] of Object.entries(animations)) {
        const isFavorite = animationsData.favorites.includes(key);
        const animName = anim.label || anim.name || key;
        const animCommand = anim.command || key;
        
        const item = $(`
            <div class="animation-item" data-anim="${key}" data-category="${category}">
                <div class="animation-icon">
                    <i class="fas fa-play"></i>
                </div>
                <div class="animation-info">
                    <span class="animation-name">${animName}</span>
                    <span class="animation-command">/e ${animCommand}</span>
                </div>
                <button class="favorite-btn ${isFavorite ? 'active' : ''}" data-anim="${key}">
                    <i class="fas fa-star"></i>
                </button>
            </div>
        `);
        
        // Play animation on click
        item.find('.animation-icon, .animation-info').on('click', function() {
            playAnimation(key, category);
        });
        
        // Toggle favorite
        item.find('.favorite-btn').on('click', function(e) {
            e.stopPropagation();
            toggleFavorite(key);
        });
        
        grid.append(item);
    }
}

function populateFavorites() {
    const grid = $('#favorites-grid');
    grid.empty();
    
    if (animationsData.favorites.length === 0) {
        $('.empty-state').show();
        return;
    }
    
    $('.empty-state').hide();
    
    // Collect all animations from all categories
    const allAnimations = {
        ...animationsData.emotes,
        ...animationsData.dances,
        ...animationsData.shared,
        ...animationsData.props,
        ...animationsData.walks,
        ...animationsData.expressions,
        ...animationsData.animals
    };
    
    animationsData.favorites.forEach(key => {
        const anim = allAnimations[key];
        if (!anim) return;
        
        const animName = anim.label || anim.name || key;
        const animCommand = anim.command || key;
        const category = anim.category || 'emotes';
        
        const item = $(`
            <div class="animation-item" data-anim="${key}" data-category="${category}">
                <div class="animation-icon">
                    <i class="fas fa-play"></i>
                </div>
                <div class="animation-info">
                    <span class="animation-name">${animName}</span>
                    <span class="animation-command">/e ${animCommand}</span>
                </div>
                <button class="favorite-btn active" data-anim="${key}">
                    <i class="fas fa-star"></i>
                </button>
            </div>
        `);
        
        item.find('.animation-icon, .animation-info').on('click', function() {
            playAnimation(key, category);
        });
        
        item.find('.favorite-btn').on('click', function(e) {
            e.stopPropagation();
            toggleFavorite(key);
        });
        
        grid.append(item);
    });
}

function playAnimation(animKey, category) {
    currentAnimation = animKey;
    
    // Highlight active animation
    $('.animation-item').removeClass('playing');
    $(`.animation-item[data-anim="${animKey}"]`).addClass('playing');
    
    $.post('https://' + GetParentResourceName() + '/playAnimation', JSON.stringify({
        animation: animKey,
        category: category
    }));
}

function toggleFavorite(animKey) {
    const index = animationsData.favorites.indexOf(animKey);
    
    if (index > -1) {
        // Remove from favorites
        animationsData.favorites.splice(index, 1);
        $(`.favorite-btn[data-anim="${animKey}"]`).removeClass('active');
    } else {
        // Add to favorites
        animationsData.favorites.push(animKey);
        $(`.favorite-btn[data-anim="${animKey}"]`).addClass('active');
    }
    
    // Update favorites grid
    populateFavorites();
    
    // Save to server
    $.post('https://' + GetParentResourceName() + '/updateFavorites', JSON.stringify({
        favorites: animationsData.favorites
    }));
}

function filterAnimations(searchTerm) {
    if (!searchTerm) {
        $('.animation-item').show();
        return;
    }
    
    $(`.animation-content:visible .animation-item`).each(function() {
        const name = $(this).find('.animation-name').text().toLowerCase();
        const command = $(this).find('.animation-command').text().toLowerCase();
        
        if (name.includes(searchTerm) || command.includes(searchTerm)) {
            $(this).show();
        } else {
            $(this).hide();
        }
    });
}

function closeAnimationsMenu() {
    $('.animations').hide();
    $.post('https://' + GetParentResourceName() + '/closeAnimations', JSON.stringify({}));
}

// Export for global access
window.initAnimations = initAnimations;
window.updateAnimationsData = updateAnimationsData;
window.closeAnimationsMenu = closeAnimationsMenu;
