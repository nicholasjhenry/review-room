const SyntaxHighlighter = {
  mounted() {
    this.highlight();
  },

  updated() {
    this.highlight();
  },

  highlight() {
    const codeBlocks = this.el.querySelectorAll('pre code');
    codeBlocks.forEach((block) => {
      // Remove existing highlighting classes
      block.className = '';

      // Get language from data attribute
      const language = block.dataset.language;
      if (language) {
        block.classList.add(`language-${language}`);
      }

      // Apply Highlight.js
      if (window.hljs) {
        window.hljs.highlightElement(block);
      }
    });
  }
};

export default SyntaxHighlighter;
