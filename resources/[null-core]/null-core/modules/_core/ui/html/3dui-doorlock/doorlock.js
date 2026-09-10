const prompt = document.getElementById('prompt');
const icon = document.getElementById('icon');
const label = document.getElementById('label');
const status = document.getElementById('status');
const action = document.getElementById('action');
const key = document.getElementById('key');
const actionText = document.getElementById('actionText');

const lockIcon = 'nui://null-core/modules/ui/web/src/modules/doorlock/lock.png';
const unlockIcon = 'nui://null-core/modules/ui/web/src/modules/doorlock/unlock.png';

function setVisible(visible) {
  prompt.classList.toggle('is-hidden', !visible);
}

function update(data) {
  const locked = data.locked !== false;
  const canInteract = data.canInteract === true;
  const hasCode = data.hasCode === true;

  prompt.classList.toggle('is-locked', locked);
  prompt.classList.toggle('is-unlocked', !locked);

  icon.src = locked ? lockIcon : unlockIcon;
  label.textContent = data.label || 'Porte';
  status.textContent = locked ? 'Verrouillee' : 'Deverrouillee';
  key.textContent = data.interactKey || 'E';
  actionText.textContent = locked ? 'Deverrouiller' : 'Verrouiller';

  if (hasCode) {
    actionText.textContent += ' · G code';
  }

  action.classList.toggle('is-muted', !canInteract);
  setVisible(data.show !== false);
}

window.addEventListener('message', (event) => {
  const data = event.data || {};
  if (data.type === 'updateDoorPrompt') {
    update(data);
  }
  if (data.type === 'hideDoorPrompt') {
    setVisible(false);
  }
});
