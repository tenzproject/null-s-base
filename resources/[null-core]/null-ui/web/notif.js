const BulletinContainers = {};
const audio = document.createElement("audio");
let MaxQueue = 5
let styled = false;
let pinned = {};

let serverColorIsLight = null;

function isColorLight() {
    if (serverColorIsLight === null) {
        let rgb = document.documentElement.style.getPropertyValue("--global-main-color");
        let match = rgb.match(/^rgb\((\d+),\s*(\d+),\s*(\d+)\)$/);
        if (match) {
            let [, r, g, b] = match.map(Number);
            const luminance = (0.299*r + 0.587*g + 0.114*b) / 255;
            serverColorIsLight = luminance > 0.6; // >0.6 = couleur claire
            return serverColorIsLight;
        } else {
            return true;
        }
    } else {
        return serverColorIsLight;
    }
}

/**
 *
 *
 * @class NotificationContainer
 */
class NotificationContainer {
    /**
     * Creates an instance of NotificationContainer.
     * @param {string} position
     * @memberof NotificationContainer
     */
    constructor(position) {
        this.container = document.getElementById("notifY_container");
        this.el = document.createElement("div");
        this.el.classList.add("notifY-notification-container", `notification-container-${position}`);
        this.notifications = [];
        this.offset = 0;
        this.running = false;
        this.spacing = 10;
        this.queue = 0;
        this.maxQueue = MaxQueue;
        this.canAdd = true;
    }

    /**
     *
     *
     * @param {object} notification
     * @memberof NotificationContainer
     */
    addNotification(notification) {

        if (!notification.pin_id) {
            this.queue++;
        }

        this.el.appendChild(notification.el);

        this.notifications.unshift(notification);

        if ( this.queue >= this.maxQueue ) {
            this.canAdd = false;
        }
    }

    /**
     *
     *
     * @param {object} notification
     * @memberof NotificationContainer
     */
    removeNotification(notification) {

        PostData("removed", {
            id: notification.id
        });

        this.el.removeChild(notification.el);

        const index = this.notifications.indexOf(notification);

        if (index > -1) {
            this.notifications.splice(index, 1);
        }

        this.queue--;

        if (this.queue == 0) {
            this.canAdd = true;
        }
    }

    /**
     *
     *
     * @memberof NotificationContainer
     */
    add() {
        if (!this.container.contains(this.el)) {
            this.container.appendChild(this.el);
        }
    }

    /**
     *
     *
     * @memberof NotificationContainer
     */
    remove() {
        this.container.removeChild(this.el);
    }

    /**
     *
     *
     * @return {boolean} 
     * @memberof NotificationContainer
     */
    empty() {
        return this.el.children.length < 1;
    }
}

/**
 *
 *
 * @class Notification
 */
class Notification {
    constructor(cfg, id, message, couleurProgress, interval, position, progress = false, theme = "default", exitAnim = "fadeOut", flash = false, pin_id = false, title, subject, icon) {
        this.cfg = cfg
        this.id = id;
        this.message = message;
        this.couleurProgress = couleurProgress;
        this.interval = interval;
        this.position = position;
        this.title = title;
        this.subject = subject;
        this.message = message;
        this.couleurProgress = couleurProgress;
        this.icon = icon;
        this.progress = progress;
        this.offset = 0;
        this.theme = theme;
        this.exitAnim = exitAnim;
        this.flash = flash;
        this.count = 1;

        if ( pin_id ) {
            this.pin_id = pin_id;
            pinned[pin_id] = this;
        }

        this.el = document.createElement("div");
        this.el.classList.add("notifY-notification");
        this.el.classList.toggle("flash", this.flash);
        this.el.classList.toggle("pinned", this.pin_id != undefined);
        this.el.classList.add(this.theme);      

        this.init();
    }

    /**
     *
     *
     * @memberof Notification
     */
    show() {
        this.bottom = (typeof this.position === 'string' && this.position.toLowerCase().includes("bottom"));

        if (this.position in BulletinContainers) {
            this.container = BulletinContainers[this.position];
        } else {
            this.container = new NotificationContainer(this.position);
            BulletinContainers[this.position] = this.container;
        }

        if (!this.container.running && this.container.canAdd) {

            if (this.cfg.SoundFile && audio.paused) {
                audio.setAttribute("src", `audio/${this.cfg.SoundFile}`);
                audio.volume        = this.cfg.SoundVolume;
                audio.currentTime   = 0;
                audio.play();
            }

            this.container.add();

            this.container.addNotification(this);

            this.el.classList.add("active");

            if (this.bottom) {
                this.el.style.bottom = `${this.container.offset}px`;
            } else {
                this.el.style.top = `${this.container.offset}px`;
            }

            if (this.progress) {
                this.el.classList.add("progress");
                this.barEl.style.animationDuration = `${this.interval}ms`;
            }

            const r = this.el.getBoundingClientRect();

            for (const n of this.container.notifications) {
                if (n != this) {
                    if (this.bottom) {
                        n.moveUp(r.height, true);
                    } else {
                        n.moveDown(r.height, true);
                    }
                }
            }

            if ( !this.pin_id ) {
                this.hide();
            }
        } else {
            setTimeout(() => {
                this.show();
            }, 250);
        }
    }

    /**
     *
     *
     * @memberof Notification
     */
    hide() {
        const r = this.el.getBoundingClientRect();

        this.timeout = setTimeout(() => {
            this.el.classList.remove("active");
            this.el.classList.add("hiding");
            this.hiding = true;
            
            if ( this.exitAnim ) {
                this.el.style.animationName = this.exitAnim;
            }

            setTimeout(() => {
                const index = this.container.notifications.indexOf(this);

                for (var i = this.container.notifications.length - 1; i > index; i--) {
                    const n = this.container.notifications[i];

                    if (this.bottom) {
                        n.moveDown(r.height);
                    } else {
                        n.moveUp(r.height);
                    }
                }

                setTimeout(() => {
                    this.container.removeNotification(this);
                }, 100);
            }, this.cfg.AnimationTime);
        }, this.interval);
    }

    /**
     *
     *
     * @memberof Notification
     */
    unpin() {
        const r = this.el.getBoundingClientRect();

        this.el.classList.remove("active");
        this.el.classList.add("hiding");
        this.hiding = true;
        
        if ( this.exitAnim ) {
            this.el.style.animationName = this.exitAnim;
        }

        setTimeout(() => {
            const index = this.container.notifications.indexOf(this);

            for (var i = this.container.notifications.length - 1; i > index; i--) {
                const n = this.container.notifications[i];

                if (this.bottom) {
                    n.moveDown(r.height);
                } else {
                    n.moveUp(r.height);
                }
            }

            setTimeout(() => {
                this.container.removeNotification(this);

                delete pinned[this.pin_id];
            }, 100);
        }, this.cfg.AnimationTime);
    }

    /**
     *
     *
     * @memberof Notification
     */
    stack() {
        clearTimeout(this.timeout);

        const r = this.el.getBoundingClientRect();

        this.el.classList.remove("progress");
        void this.el.offsetWidth;
        this.el.classList.add("progress");

        this.count += 1;
        if ( this.cfg.ShowStackedCount ) {
            this.el.classList.add("stacked");
            this.el.dataset.count = this.count;
        }

        this.hide();
    }

    /**
     *
     *
     * @param {float} h
     * @param {boolean} [run=false]
     * @memberof Notification
     */
    moveUp(h, run = false) {
        const offset = h + this.container.spacing;

        if (this.bottom) {
            this.offset += offset;
        } else {
            this.offset -= offset;
        }
        this.el.style.transition = `transform 250ms ease 0ms`;
        this.el.style.transform = `translate3d(0px, ${-offset}px, 0px)`;

        this.container.running = run;

        setTimeout(() => {
            if (run) {
                this.container.running = false;
            }
            this.el.style.transition = ``;
            this.el.style.transform = ``;
            if (this.bottom) {
                this.el.style.bottom = `${this.container.offset + this.offset}px`;
            } else {
                this.el.style.top = `${this.container.offset + this.offset}px`;
            }
        }, 250);
    }

    /**
     *
     *
     * @param {float} h
     * @param {boolean} [run=false]
     * @memberof Notification
     */
    moveDown(h, run = false) {
        const offset = h + this.container.spacing;

        if (this.bottom) {
            this.offset -= offset;
        } else {
            this.offset += offset;
        }
        this.el.style.transition = `transform 250ms ease 0ms`;
        this.el.style.transform = `translate3d(0px, ${offset}px, 0px)`;

        this.container.running = run;

        setTimeout(() => {
            if (run) {
                this.container.running = false;
            }
            this.el.style.transition = ``;
            this.el.style.transform = ``;

            if (this.bottom) {
                this.el.style.bottom = `${this.container.offset + this.offset}px`;
            } else {
                this.el.style.top = `${this.container.offset + this.offset}px`;
            }
        }, 250);
    }

    /**
     *
     *
     * @param {string} message
     * @return {string} 
     * @memberof Notification
     */
    parseMessage(message) {
        const regexColor = /~([^h])~([^~]+)/g;	
        const regexBold = /~([h])~([^~]+)/g;	
        const regexStop = /~s~/g;	
        const regexLine = /\n/g;	
    
        message = message.replace(regexColor, "<span class='$1'>$2</span>").replace(regexBold, "<span class='$1'>$2</span>").replace(regexStop, "").replace(regexLine, "<br />");
			
        return message;
    }

    update(options) {
        if ( this.type == 'advanced' ) {
            if ( options.hasOwnProperty('title') ) {
                this.title = this.parseMessage(options.title);
            }

            if ( options.hasOwnProperty('subject') && this.subject != undefined ) {
                this.subject = this.parseMessage(options.subject);
            }

            if ( options.hasOwnProperty('message') ) {
                this.message = this.parseMessage(options.message);
            }

            if ( options.hasOwnProperty('icon') ) {
                this.iconEl.innerHTML = `<img src="${options.icon}" />`;
            }

            this.titleEl.innerHTML = this.title;
            if ( this.subject != undefined ) {
                this.subjectEl.innerHTML = this.subject;
            }
            this.messageEl.innerHTML = this.message;
        } else if ( this.type == 'standard' ) {
            if ( options.hasOwnProperty('message') ) {
                this.message = this.parseMessage(options.message);
            }

            this.el.innerHTML = this.message;  
        }

        if ( options.hasOwnProperty('theme') ) {
            this.el.classList.remove(this.theme);

            this.theme = options.theme;
            this.el.classList.add(this.theme);
        }

        if ( options.hasOwnProperty('flash') && options.flash == true ) {
            this.el.classList.remove("flash");

            setTimeout(() => {
                this.el.classList.add("flash");
            }, 1);
        }

        this.rearrange(this.el.getBoundingClientRect().height);
    }

    rearrange(h) {
        let posY = 0;

        for (const n of this.container.notifications) {
            const rn = n.el.getBoundingClientRect();
            const offset = (rn.height - h);

            n.offset -= offset;

            if ( this.bottom ) {
                n.el.style.bottom = `${posY}px`;
            } else {
                n.el.style.top = `${posY}px`;
            }

            posY += rn.height + this.container.spacing;
        }
    }
}

/**
 *
 *
 * @class StandardNotification
 * @extends {Notification}
 */
class StandardNotification extends Notification {
    /**
     * Creates an instance of StandardNotification.
     * @param {object} cfg
     * @param {string} id
     * @param {string} message
     * @param {integer} interval
     * @param {string} position
     * @param {boolean} [progress=false]
     * @param {string} [theme="default"]
     * @param {string} [exitAnim="fadeOut"]
     * @param {boolean} [flash=false]
     * @param {boolean} [pin_id=false]
     * @memberof StandardNotification
     */
    constructor(cfg, id, message, couleurProgress, interval, position, progress = false, theme = "default", exitAnim = "fadeOut", flash = false, pin_id = false) {
        super(cfg, id, message, couleurProgress, interval, position, progress, theme, exitAnim, flash, pin_id);
    }

    /**
     *
     *
     * @memberof StandardNotification
     */
    init() {
        this.type = 'standard';
        this.message = this.parseMessage(this.message);
        this.el.innerHTML = this.message;     
        
        if (this.progress) {
            this.el.classList.add("with-progress");
            this.progressEl = document.createElement("div");
            this.progressEl.classList.add("notification-progress");

            this.barEl = document.createElement("div");
            this.barEl.classList.add("notification-bar");
            this.progressEl.appendChild(this.barEl);

            if (isColorLight()) {
                this.el.classList.add('light-badge');
                this.el.classList.remove('dark-badge');
            } else {
                this.el.classList.add('dark-badge');
                this.el.classList.remove('light-badge');
            }

            this.el.appendChild(this.progressEl);
        }  
    }
}

/**
 *
 *
 * @class AdvancedNotification
 * @extends {Notification}
 */
class AdvancedNotification extends Notification {
    /**
     * Creates an instance of AdvancedNotification.
     * @param {object} cfg
     * @param {string} id
     * @param {string} message
     * @param {string} title
     * @param {string} subject
     * @param {string} icon
     * @param {integer} interval
     * @param {string} position
     * @param {boolean} [progress=false]
     * @param {string} [theme="default"]
     * @param {string} [exitAnim="fadeOut"]
     * @param {boolean} [flash=false]
     * @param {boolean} [pin_id=false]
     * @memberof AdvancedNotification
     */
    constructor(cfg, id, message, couleurProgress, title, subject, icon, interval, position, progress = false, theme = "default", exitAnim = "fadeOut", flash = false, pin_id = false) {
        super(cfg, id, message, couleurProgress, interval, position, progress, theme, exitAnim, flash, pin_id, title, subject, icon);
    }

    /**
     *
     *
     * @memberof AdvancedNotification
     */
    init() {
        this.type = 'advanced';
        this.title = this.parseMessage(this.title);
        if ( this.subject != undefined ) {
            this.subject = this.parseMessage(this.subject);

            this.subjectEl = document.createElement("div");
            this.subjectEl.classList.add("notification-subject");
        }
        this.message = this.parseMessage(this.message);

        this.headerEl = document.createElement("div");
        this.headerEl.classList.add("notification-header");

        this.iconEl = document.createElement("div");
        this.iconEl.classList.add("notification-icon");

        this.titleEl = document.createElement("div");
        this.titleEl.classList.add("notification-title");

        this.messageEl = document.createElement("div");
        this.messageEl.classList.add("notification-message");

        this.iconEl.innerHTML = `<img src="${this.icon}" />`;
        this.titleEl.innerHTML = this.title;
        if ( this.subject != undefined ) {
            this.subjectEl.innerHTML = this.subject;
        }
        this.messageEl.innerHTML = this.message;

        this.headerEl.appendChild(this.iconEl);
        this.headerEl.appendChild(this.titleEl);
        if ( this.subject != undefined ) {
            this.headerEl.appendChild(this.subjectEl);
        }
        this.el.appendChild(this.headerEl);
        this.el.appendChild(this.messageEl);
        if (this.progress) {
            this.el.classList.add("with-progress");
            this.progressEl = document.createElement("div");
            this.progressEl.classList.add("notification-progress");

            this.barEl = document.createElement("div");
            this.barEl.classList.add("notification-bar");

            this.progressEl.appendChild(this.barEl);

            if (isColorLight()) {
                this.el.classList.add('light-badge');
                this.el.classList.remove('dark-badge');
            } else {
                this.el.classList.add('dark-badge');
                this.el.classList.remove('light-badge');
            }

            this.el.appendChild(this.progressEl);
        }  
    }
}

/**
 *
 *
 * @class AcceptNotification
 * @extends {Notification}
 */
class AcceptNotification extends Notification {
    constructor(cfg, id, message, couleurProgress, title, subject, icon, interval, position, progress = false, theme = "default", exitAnim = "fadeOut", flash = false, pin_id = false) {
        super(cfg, id, message, couleurProgress, interval, position, progress, theme, exitAnim, flash, pin_id, title, subject, icon);
        this.hasResponded = false;
    }

    init() {
        const content = document.createElement("div");
        content.classList.add("notification-content");

        // Ajout du header avec icône et titres
        const header = document.createElement("div");
        header.classList.add("notification-header");

        if (this.icon) {
            const iconContainer = document.createElement("div");
            iconContainer.classList.add("notification-icon");
            const iconImg = document.createElement("img");
            iconImg.src = this.icon;
            iconContainer.appendChild(iconImg);
            header.appendChild(iconContainer);
        }

        if (this.title || this.subject) {
            const titleContainer = document.createElement("div");
            titleContainer.classList.add("notification-titles");
            
            if (this.title) {
                const titleEl = document.createElement("div");
                titleEl.classList.add("notification-title");
                titleEl.textContent = this.title;
                titleContainer.appendChild(titleEl);
            }

            if (this.subject) {
                const subjectEl = document.createElement("div");
                subjectEl.classList.add("notification-subject");
                subjectEl.textContent = this.subject;
                titleContainer.appendChild(subjectEl);
            }

            header.appendChild(titleContainer);
        }

        content.appendChild(header);

        // Message principal
        const messageEl = document.createElement("p");
        messageEl.classList.add("notification-message");
        messageEl.style.marginTop = "3px";
        messageEl.style.marginBottom = "10px";
        messageEl.innerHTML = this.parseMessage(this.message);
        content.appendChild(messageEl);

        // Boutons d'acceptation/refus
        const buttonsContainer = document.createElement("div");
        buttonsContainer.classList.add("accept-buttons");

        const acceptText = document.createElement("span");
        acceptText.textContent = "Accepter";
        acceptText.classList.add("accept-option");

        const refuseText = document.createElement("span");
        refuseText.textContent = "Refuser";
        refuseText.classList.add("refuse-option");

        buttonsContainer.appendChild(acceptText);
        buttonsContainer.appendChild(refuseText);
        content.appendChild(buttonsContainer);

        // Barre de progression
        if (this.progress) {
            const progressBar = document.createElement("div");
            progressBar.classList.add("notification-progress");
            
            this.barEl = document.createElement("div");
            this.barEl.classList.add("notification-bar");
            progressBar.appendChild(this.barEl);

            if (isColorLight()) {
                this.el.classList.add('light-badge');
                this.el.classList.remove('dark-badge');
            } else {
                this.el.classList.add('dark-badge');
                this.el.classList.remove('light-badge');
            }

            content.appendChild(progressBar);
        }

        this.el.appendChild(content);
    }
}

/**
 *
 *
 * @param {Event} e
 */
const onData = function(e) {
    const data = e.data;
    if (data.type && data.message !== null && data.message !== undefined  && data.duplicate !== undefined) {
        if ( !styled ) {
            let css = `
            .animate__animated {
                -webkit-animation-duration: ${data.config.AnimationTime};
                animation-duration: ${data.config.AnimationTime};
            }

            .notifY-notification.active {
                opacity: 0;
                animation: fadeIn ${data.config.AnimationTime}ms ease 0ms forwards;
            }

            .notifY-notification.active.flash {
                opacity: 1;
                animation-name: ${data.config.FlashType};
            }            
            
            .notifY-notification.hiding {
                opacity: 1;
                animation: ${data.config.AnimationOut} ${data.config.AnimationTime}ms ease 0ms forwards;
            }`;

            if ( data.config.FlashType == "flash" ) {
                css += `
                    .notifY-notification.active.flash {
                        animation-iteration-count: ${data.config.FlashCount};
                    }                  
                `;
            }

            document.head.insertAdjacentHTML("beforeend", `<style>${css}</style>`);

            styled = true
        }

        if (data.type == "standard") {
            MaxQueue = data.config.Queue;

            if ( data.duplicate && data.config.Stacking ) {
                stackDuplicate(data)
            } else {
                new StandardNotification(data.config, data.id, data.message, data.couleurProgress, data.timeout, data.position, data.progress, data.theme, data.exitAnim, data.flash, data.pin_id).show();
            }
        } else if (data.type == "advanced") {
            MaxQueue = data.config.Queue;

            if ( data.duplicate && data.config.Stacking ) {
                stackDuplicate(data)
            } else {          
                new AdvancedNotification(data.config, data.id, data.message, data.couleurProgress, data.title, data.subject, data.icon, data.timeout, data.position, data.progress, data.theme, data.exitAnim, data.flash, data.pin_id).show();
            }
        } else if (data.type == "accept") {
            MaxQueue = data.config.Queue;

            if ( data.duplicate && data.config.Stacking ) {
                stackDuplicate(data)
            } else {          
                new AcceptNotification(data.config, data.id, data.message, data.couleurProgress, data.title, data.subject, data.icon, data.timeout, data.position, data.progress, data.theme, data.exitAnim, data.flash, data.pin_id).show();
            }
        } else if (data.type == "unpin") {
            if ( Array.isArray(data.pin_id) ) { // array of pin ids
                for ( const item of data.pin_id ) {
                    if ( pinned.hasOwnProperty(item) ) {
                        pinned[item].unpin();
                    }
                }
            } else if ( typeof(data.pin_id) == 'string' ) {  // unpin single
                if ( pinned.hasOwnProperty(data.pin_id) ) {
                    pinned[data.pin_id].unpin();
                }
            } else {
                for ( let id in pinned ) { // unpin all
                    pinned[id].unpin();
                }
            }
        } else if (data.type == "update_pinned") {
            if ( pinned.hasOwnProperty(data.pin_id) ) {
                pinned[data.pin_id].update(data.options)
            }
        }
    }
};

/**
 *
 *
 * @param {table} data
 */
function stackDuplicate(data) {
    for ( const position in BulletinContainers ) {
        for ( const notification of BulletinContainers[position].notifications ) {
            if ( notification.id == data.id ) {
                if ( notification.hiding ) {
                    if (data.type == "standard") {
                        new StandardNotification(data.config, data.id, data.message, data.couleurProgress, data.timeout, data.position, data.progress, data.theme, data.flash, data.pin_id).show();
                    } else if (data.type == "advanced") {
                        new AdvancedNotification(data.config, data.id, data.message, data.couleurProgress, data.title, data.subject, data.icon, data.timeout, data.position, data.progress, data.theme, data.flash, data.pin_id).show();
                    } else if (data.type == "accept") {
                        new AcceptNotification(data.config, data.id, data.message, data.couleurProgress, data.title, data.subject, data.icon, data.timeout, data.position, data.progress, data.theme, data.flash, data.pin_id).show();
                    }
                } else {
                    notification.stack();
                }

                break;
            }
        }
    }
}

/**
 *
 *
 * @param {string} [type=""]
 * @param {*} [data={}]
 */
function PostData(type = "", data = {}) {
    fetch(`https://${GetParentResourceName()}/nui_${type}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify(data)
    }).then(resp => resp.json()).then(resp => resp).catch(error => console.log('BULLETIN FETCH ERROR! ' + error.message));    
}

window.onload = function(e) {
    window.addEventListener('message', onData);
};