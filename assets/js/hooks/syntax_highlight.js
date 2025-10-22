/**
 * SyntaxHighlight Hook
 *
 * Applies highlight.js syntax highlighting to code blocks.
 * Uses phx-update="ignore" to prevent LiveView from re-rendering highlighted code.
 */
export const SyntaxHighlight = {
  mounted() {
    this.highlight();
  },

  updated() {
    this.highlight();
  },

  highlight() {
    const codeBlock = this.el.querySelector('code');
    if (codeBlock && window.hljs) {
      window.hljs.highlightElement(codeBlock);
    }
  }
};
