const FEEDBACK_DURATION = 2200;

const ClipboardCopy = {
  mounted() {
    this.targetSelector = this.el.dataset.clipboardTarget;
    this.resetTimer = null;
    this.handleClick = this.onClick.bind(this);

    this.el.addEventListener('click', this.handleClick);
  },

  destroyed() {
    this.el.removeEventListener('click', this.handleClick);

    if (this.resetTimer) {
      clearTimeout(this.resetTimer);
      this.resetTimer = null;
    }
  },

  async onClick(event) {
    event.preventDefault();

    if (!this.targetSelector) {
      return;
    }

    const source = document.querySelector(this.targetSelector);
    if (!source) {
      this.showFeedback('error');
      return;
    }

    const text = source.textContent ?? '';

    try {
      await this.copyToClipboard(text);
      this.showFeedback('success');
    } catch (_error) {
      this.showFeedback('error');
    }
  },

  async copyToClipboard(text) {
    if (navigator.clipboard && typeof navigator.clipboard.writeText === 'function') {
      await navigator.clipboard.writeText(text);
      return true;
    }

    const textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.setAttribute('readonly', '');
    textarea.style.position = 'absolute';
    textarea.style.left = '-9999px';
    document.body.appendChild(textarea);
    textarea.select();

    try {
      document.execCommand('copy');
      return true;
    } finally {
      document.body.removeChild(textarea);
    }
  },

  showFeedback(state) {
    this.toggleState(state);

    if (state !== 'default') {
      if (this.resetTimer) {
        clearTimeout(this.resetTimer);
      }

      this.resetTimer = setTimeout(() => {
        this.toggleState('default');
      }, FEEDBACK_DURATION);
    }
  },

  toggleState(state) {
    const states = {
      default: this.el.querySelector('[data-default-state]'),
      success: this.el.querySelector('[data-success-state]'),
      error: this.el.querySelector('[data-error-state]')
    };

    Object.entries(states).forEach(([key, element]) => {
      if (!element) return;
      element.classList.toggle('hidden', key !== state);
      element.classList.toggle('flex', key === state && element.classList.contains('items-center'));
    });

    this.el.setAttribute('data-state', state);
  }
};

export default ClipboardCopy;
