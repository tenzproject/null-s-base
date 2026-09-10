function createDigitRoller(elementId, digitHeight) {
    const roller = document.querySelector(`#${elementId} .digit-roller`);
    roller.innerHTML = '';
    for (let i = 0; i < 3; i++) {
        for (let d = 0; d <= 9; d++) {
            const el = document.createElement('div');
            el.className = 'digit';
            el.textContent = d;
            roller.appendChild(el);
        }
    }
    return { roller, digitHeight };
}

const priceIds = ['price-1', 'price-2', 'price-3', 'price-4'];
const fuelIds = ['fuel-1', 'fuel-2', 'fuel-3'];

const priceRollers = priceIds.map(id => createDigitRoller(id, 220));
const fuelRollers = fuelIds.map(id => createDigitRoller(id, 220));

function rollTo(item, target, instant = false) {
    const total = 30;
    const finalPos = -((total - 10 + target) % 10) * item.digitHeight;
    item.roller.style.transition = instant ? 'none' : 'top 0.6s cubic-bezier(0.25, 1, 0.5, 1)';
    item.roller.style.top = `${finalPos}px`;
}

function updateDisplay(price, fuel, instant = false) {
    const priceStr = Math.floor(price).toString().padStart(4, '0');
    const fuelStr = Math.floor(fuel).toString().padStart(3, '0');
    priceRollers.forEach((r, i) => rollTo(r, parseInt(priceStr[i]), instant));
    fuelRollers.forEach((r, i) => rollTo(r, parseInt(fuelStr[i]), instant));
}

window.addEventListener('DOMContentLoaded', () => {
    document.body.style.display = 'none';
    const params = new URLSearchParams(window.location.search);
    const price = parseFloat(params.get('price')) || 0;
    const fuel = parseFloat(params.get('fuel')) || 0;
    updateDisplay(price, fuel, true);
});

window.addEventListener('message', (event) => {
    const data = event.data;
    if (data.type === 'updateFuelStation') {
        document.body.style.display = 'flex';
        updateDisplay(data.price, data.fuel);
    } else if (data.type === 'hideFuelStation') {
        document.body.style.display = 'none';
    }
});
