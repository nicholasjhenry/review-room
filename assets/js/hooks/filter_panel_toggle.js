const DEFAULT_OPEN_CLASSES = ["translate-y-0", "opacity-100", "pointer-events-auto"];
const DEFAULT_CLOSED_CLASSES = ["-translate-y-4", "opacity-0", "pointer-events-none"];

const FilterPanelToggle = {
  mounted() {
    this.state = this.el.dataset.state || "closed";
    this.triggerSelector = this.el.dataset.trigger;
    this.closeOnOutside = this.el.dataset.closeOnOutside === "true";
    this.openClasses = this.parseClasses(this.el.dataset.openClasses, DEFAULT_OPEN_CLASSES);
    this.closedClasses = this.parseClasses(this.el.dataset.closedClasses, DEFAULT_CLOSED_CLASSES);

    this.boundToggle = this.handleToggle.bind(this);
    this.handleOutsideClick = this.onOutsideClick.bind(this);
    this.outsideListenerAttached = false;

    this.registerTrigger();
    this.applyState();

    this.handleEvent("design-system:filter-panel", ({ open }) =>
      this.setState(open ? "open" : "closed"),
    );
  },

  updated() {
    this.state = this.el.dataset.state || this.state;
    this.applyState();
  },

  destroyed() {
    if (this.trigger) {
      this.trigger.removeEventListener("click", this.boundToggle);
    }

    this.removeOutsideListener();
  },

  handleToggle(event) {
    event?.preventDefault();
    this.toggle();
  },

  toggle() {
    this.setState(this.state === "open" ? "closed" : "open");
  },

  setState(nextState) {
    this.state = nextState;
    this.applyState();
  },

  applyState() {
    const isOpen = this.state === "open";
    this.toggleClasses(this.openClasses, isOpen);
    this.toggleClasses(this.closedClasses, !isOpen);

    this.el.dataset.state = this.state;
    this.el.classList.toggle("is-open", isOpen);

    if (this.trigger) {
      this.trigger.setAttribute("aria-expanded", String(isOpen));
      this.trigger.classList.toggle("is-active", isOpen);
    }

    if (this.closeOnOutside) {
      if (isOpen) {
        this.addOutsideListener();
      } else {
        this.removeOutsideListener();
      }
    }
  },

  registerTrigger() {
    if (!this.triggerSelector) return;

    this.trigger = document.querySelector(this.triggerSelector);

    if (this.trigger) {
      this.trigger.addEventListener("click", this.boundToggle);
      this.trigger.setAttribute("aria-controls", this.el.id || "");
      this.trigger.setAttribute("aria-expanded", String(this.state === "open"));
    }
  },

  addOutsideListener() {
    if (this.outsideListenerAttached) return;
    document.addEventListener("click", this.handleOutsideClick, true);
    this.outsideListenerAttached = true;
  },

  removeOutsideListener() {
    if (!this.outsideListenerAttached) return;
    document.removeEventListener("click", this.handleOutsideClick, true);
    this.outsideListenerAttached = false;
  },

  onOutsideClick(event) {
    if (this.el.contains(event.target)) return;
    if (this.trigger && this.trigger.contains(event.target)) return;
    this.setState("closed");
  },

  toggleClasses(classes, shouldEnable) {
    classes.forEach((className) => {
      this.el.classList.toggle(className, shouldEnable);
    });
  },

  parseClasses(value, fallback) {
    if (!value) return fallback;
    return value.split(/\s+/).filter(Boolean);
  },
};

export default FilterPanelToggle;
