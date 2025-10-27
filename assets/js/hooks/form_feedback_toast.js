const REDUCED_MOTION_QUERY = "(prefers-reduced-motion: reduce)";

const FormFeedbackToast = {
  mounted() {
    this.timer = null;
    this.el.dataset.motion = this.el.dataset.motion || "standard";

    this.motionQuery = typeof window !== "undefined" && window.matchMedia
      ? window.matchMedia(REDUCED_MOTION_QUERY)
      : null;

    this.handleMotionChange = this.syncMotionPreference.bind(this);

    if (this.motionQuery) {
      this.motionQuery.addEventListener
        ? this.motionQuery.addEventListener("change", this.handleMotionChange)
        : this.motionQuery.addListener(this.handleMotionChange);

      this.syncMotionPreference();
    }

    this.scheduleDismiss();
  },

  updated() {
    this.scheduleDismiss();
  },

  destroyed() {
    this.clearTimer();

    if (this.motionQuery) {
      this.motionQuery.removeEventListener
        ? this.motionQuery.removeEventListener("change", this.handleMotionChange)
        : this.motionQuery.removeListener(this.handleMotionChange);
    }
  },

  scheduleDismiss() {
    this.clearTimer();

    if (this.visibility() !== "visible") return;

    const duration = this.autoDismissMs();
    if (!duration) return;

    this.timer = setTimeout(() => this.pushEvent("dismiss_toast", {}), duration);
  },

  autoDismissMs() {
    const value = parseInt(this.el.dataset.autoDismissMs || "0", 10);
    return Number.isNaN(value) || value <= 0 ? 0 : value;
  },

  visibility() {
    return this.el.dataset.visibility || "hidden";
  },

  clearTimer() {
    if (this.timer) {
      clearTimeout(this.timer);
      this.timer = null;
    }
  },

  syncMotionPreference() {
    if (!this.motionQuery) return;
    this.el.dataset.motion = this.motionQuery.matches ? "reduce" : "standard";
  },
};

export default FormFeedbackToast;
