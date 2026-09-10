
const warnManger = {
    number: 0,
    total: 3,
    show: false,

    showText() {
        this.show = true;
        const indicator = $('.warn-indicator');
        const text = $('.warn-text');
        text.text(this.number + '/' + this.total);
        indicator.addClass('fade-in');
        indicator.css('opacity', 0.8);

        setTimeout(() => {
            indicator.css('opacity', 0.8);
            indicator.removeClass('fade-in');
        }, 1000);
    },

    hideText() {
        this.show = false;
        const indicator = $('.warn-indicator');
        indicator.removeClass('fade-in');
        indicator.addClass('fade-out');

        setTimeout(() => {
            indicator.removeClass('fade-out');
            indicator.css('opacity', 0);
        }, 1000);
    },

    updateNumber(number, total) {
        console.log(number, total);
        if (number === 0) {
            this.hideText();
            return;
        }
        if (number) {
            this.number = number;
        }
        if (total) {
            this.total = total;
        }
        if (!this.show) {
            this.showText();
        } else {
            const text = $('.warn-text');
            text.text(this.number + '/' + this.total);
        }

    },

}

window.addEventListener('message', (event) => {
    const data = event.data;
    switch (data.type) {
        case 'warn:update':
            warnManger.updateNumber(data.number, data.total);
            break;
    }
});