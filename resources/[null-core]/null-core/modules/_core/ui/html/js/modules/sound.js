/**
 * Null UI - Module Sound
 * Système de lecture audio (URL, YouTube, 3D positionnel)
 */

const NullSound = {
    // Sons enregistrés
    _sounds: {},
    
    // Intervalle de mise à jour du volume 3D
    _updateInterval: null,

    /**
     * Initialiser le module
     */
    init() {
        NullEvents.on('url', (data) => this.play(data.name, data.url, data.volume, data.loop, data.dynamic, data.x, data.y, data.z));
        NullEvents.on('play', (data) => this.resume(data.name));
        NullEvents.on('pause', (data) => this.pause(data.name));
        NullEvents.on('resume', (data) => this.resume(data.name));
        NullEvents.on('delete', (data) => this.destroy(data.name));
        NullEvents.on('volume', (data) => this.setVolume(data.name, data.volume));
        NullEvents.on('max_volume', (data) => this.setMaxVolume(data.name, data.volume));
        NullEvents.on('distance', (data) => this.setDistance(data.name, data.distance));
        NullEvents.on('soundPosition', (data) => this.setPosition(data.name, data.x, data.y, data.z));

        this._startVolumeUpdate();
    },

    /**
     * Jouer un son
     * @param {string} name - Nom unique du son
     * @param {string} url - URL du son (fichier ou YouTube)
     * @param {number} volume - Volume (0-1)
     * @param {boolean} loop - Boucle
     * @param {boolean} dynamic - Son 3D positionnel
     * @param {number} x - Position X
     * @param {number} y - Position Y
     * @param {number} z - Position Z
     */
    play(name, url, volume = 1.0, loop = false, dynamic = false, x = 0, y = 0, z = 0) {
        // Détruire si existe déjà
        if (this._sounds[name]) {
            this.destroy(name);
        }

        const sound = new NullAudioPlayer({
            name,
            url,
            volume,
            loop,
            dynamic,
            position: [x, y, z]
        });

        this._sounds[name] = sound;
        sound.play();
    },

    /**
     * Mettre en pause un son
     * @param {string} name - Nom du son
     */
    pause(name) {
        if (this._sounds[name]) {
            this._sounds[name].pause();
        }
    },

    /**
     * Reprendre un son
     * @param {string} name - Nom du son
     */
    resume(name) {
        if (this._sounds[name]) {
            this._sounds[name].resume();
        }
    },

    /**
     * Détruire un son
     * @param {string} name - Nom du son
     */
    destroy(name) {
        if (this._sounds[name]) {
            this._sounds[name].destroy();
            delete this._sounds[name];
        }
    },

    /**
     * Définir le volume d'un son
     * @param {string} name - Nom du son
     * @param {number} volume - Volume (0-1)
     */
    setVolume(name, volume) {
        if (this._sounds[name]) {
            this._sounds[name].setVolume(volume);
        }
    },

    /**
     * Définir le volume maximum d'un son
     * @param {string} name - Nom du son
     * @param {number} volume - Volume max (0-1)
     */
    setMaxVolume(name, volume) {
        if (this._sounds[name]) {
            this._sounds[name].setMaxVolume(volume);
        }
    },

    /**
     * Définir la distance d'un son 3D
     * @param {string} name - Nom du son
     * @param {number} distance - Distance max
     */
    setDistance(name, distance) {
        if (this._sounds[name]) {
            this._sounds[name].setDistance(distance);
        }
    },

    /**
     * Définir la position d'un son 3D
     * @param {string} name - Nom du son
     * @param {number} x - Position X
     * @param {number} y - Position Y
     * @param {number} z - Position Z
     */
    setPosition(name, x, y, z) {
        if (this._sounds[name]) {
            this._sounds[name].setPosition(x, y, z);
        }
    },

    /**
     * Vérifier si un son existe
     * @param {string} name - Nom du son
     * @returns {boolean}
     */
    exists(name) {
        return !!this._sounds[name];
    },

    /**
     * Obtenir les infos d'un son
     * @param {string} name - Nom du son
     * @returns {Object|null}
     */
    getInfo(name) {
        return this._sounds[name] ? this._sounds[name].getInfo() : null;
    },

    /**
     * Démarrer la mise à jour du volume 3D
     */
    _startVolumeUpdate() {
        this._updateInterval = setInterval(() => {
            const playerPos = NullState.getPlayerPosition();
            
            for (const name in this._sounds) {
                const sound = this._sounds[name];
                if (sound.isDynamic()) {
                    sound.updateVolume3D(playerPos);
                }
            }
        }, 100);
    },

    /**
     * Arrêter tous les sons
     */
    stopAll() {
        for (const name in this._sounds) {
            this.destroy(name);
        }
    }
};

/**
 * Classe AudioPlayer interne
 */
class NullAudioPlayer {
    constructor(options) {
        this.name = options.name;
        this.url = options.url;
        this.volume = options.volume || 1.0;
        this.maxVolume = options.volume || 1.0;
        this.loop = options.loop || false;
        this.dynamic = options.dynamic || false;
        this.position = options.position || [0, 0, 0];
        this.distance = options.distance || 50;
        this.playing = false;
        this.paused = false;
        
        this.divId = NullUtils.generateId('audio');
        this.isYoutube = false;
        this.youtubeReady = false;
        this.yPlayer = null;
        this.audioElement = null;
    }

    play() {
        const youtubeId = NullUtils.getYoutubeId(this.url);
        
        if (youtubeId) {
            this._createYoutube(youtubeId);
        } else {
            this._createAudio();
        }
        
        this.playing = true;
        this.paused = false;
    }

    _createAudio() {
        this.isYoutube = false;
        
        this.audioElement = document.createElement('audio');
        this.audioElement.id = this.divId;
        this.audioElement.src = this.url;
        this.audioElement.volume = this.volume;
        this.audioElement.loop = this.loop;
        
        if (!this.loop) {
            this.audioElement.onended = () => {
                NullEvents.post('sound_finished', { name: this.name });
                this.destroy();
            };
        }
        
        document.body.appendChild(this.audioElement);
        this.audioElement.play().catch(() => {});
    }

    _createYoutube(videoId) {
        this.isYoutube = true;
        this.youtubeReady = false;
        
        const div = document.createElement('div');
        div.id = this.divId;
        div.style.display = 'none';
        document.body.appendChild(div);
        
        // Vérifier si l'API YouTube est chargée
        if (typeof YT === 'undefined' || typeof YT.Player === 'undefined') {
            console.warn('[NullSound] YouTube API not loaded');
            return;
        }
        
        this.yPlayer = new YT.Player(this.divId, {
            width: '0',
            height: '0',
            videoId: videoId,
            events: {
                onReady: (event) => {
                    this.youtubeReady = true;
                    event.target.playVideo();
                    this.setVolume(this.volume);
                },
                onStateChange: (event) => {
                    if (event.data === YT.PlayerState.ENDED) {
                        if (this.loop) {
                            event.target.playVideo();
                        } else {
                            NullEvents.post('sound_finished', { name: this.name });
                        }
                    }
                }
            }
        });
    }

    pause() {
        if (this.isYoutube && this.yPlayer && this.youtubeReady) {
            this.yPlayer.pauseVideo();
        } else if (this.audioElement) {
            this.audioElement.pause();
        }
        this.playing = false;
        this.paused = true;
    }

    resume() {
        if (this.isYoutube && this.yPlayer && this.youtubeReady) {
            this.yPlayer.playVideo();
        } else if (this.audioElement) {
            this.audioElement.play().catch(() => {});
        }
        this.playing = true;
        this.paused = false;
    }

    destroy() {
        if (this.isYoutube && this.yPlayer) {
            try {
                this.yPlayer.stopVideo();
                this.yPlayer.destroy();
            } catch (e) {}
            this.yPlayer = null;
        }
        
        const element = document.getElementById(this.divId);
        if (element) {
            element.remove();
        }
        
        this.audioElement = null;
        this.playing = false;
    }

    setVolume(vol) {
        this.volume = NullUtils.clamp(vol, 0, 1);
        
        if (this.maxVolume > 0 && this.volume > this.maxVolume) {
            this.volume = this.maxVolume;
        }
        
        if (this.isYoutube && this.yPlayer && this.youtubeReady) {
            this.yPlayer.setVolume(this.volume * 100);
        } else if (this.audioElement) {
            this.audioElement.volume = this.volume;
        }
    }

    setMaxVolume(vol) {
        this.maxVolume = NullUtils.clamp(vol, 0, 1);
    }

    setDistance(dist) {
        this.distance = dist;
    }

    setPosition(x, y, z) {
        this.position = [x, y, z];
    }

    isDynamic() {
        return this.dynamic;
    }

    updateVolume3D(playerPos) {
        if (!this.dynamic) return;
        
        const dist = NullUtils.distance3D(playerPos, this.position);
        
        if (dist < this.distance) {
            const ratio = 1 - (dist / this.distance);
            const vol = this.maxVolume * ratio;
            this.setVolume(vol);
        } else {
            this.setVolume(0);
        }
    }

    getInfo() {
        return {
            name: this.name,
            url: this.url,
            volume: this.volume,
            maxVolume: this.maxVolume,
            loop: this.loop,
            dynamic: this.dynamic,
            position: this.position,
            distance: this.distance,
            playing: this.playing,
            paused: this.paused
        };
    }
}

// Export global
window.NullSound = NullSound;
