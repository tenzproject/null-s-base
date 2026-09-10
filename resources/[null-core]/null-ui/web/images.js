function showImage(url, x, y, width, height) {
    const container = document.getElementById('dynamic-image-container');

    const img = document.createElement('img');
    img.className = 'dynamic-image';
    img.src = url;
    img.style.left = `${x}px`;
    img.style.top = `${y}px`;
    img.style.width = `${width}px`;
    img.style.height = `${height}px`;
    
    container.appendChild(img);
    
    return img;
}

function removeImage() {
    const container = document.getElementById('dynamic-image-container');
    if (container) {
        container.innerHTML = '';
    }
}

$(document).ready(function() {
    removeImage();
    window.addEventListener('message', function(event) {
        if (event.data.type === 'SHOW_IMAGE') {
            showImage(event.data.url, event.data.x, event.data.y, event.data.width, event.data.height);
        } else if (event.data.type === 'REMOVE_IMAGE') {
            removeImage();
        }
    });
});
