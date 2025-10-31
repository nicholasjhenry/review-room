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
      const preservedClasses = Array.from(block.classList).filter((className) => {
        return !className.startsWith('language-') && className !== 'hljs';
      });

      const language = block.dataset.language;
      const code = block.textContent;

      if (window.hljs && code) {
        let highlightedHtml;

        if (language && window.hljs.getLanguage(language)) {
          highlightedHtml = window.hljs.highlight(code, { language }).value;
          preservedClasses.push(`language-${language}`);
        } else {
          const { language: detectedLanguage, value } = window.hljs.highlightAuto(code);
          highlightedHtml = value;

          if (detectedLanguage) {
            preservedClasses.push(`language-${detectedLanguage}`);
          }
        }

        preservedClasses.push('hljs');

        block.innerHTML = highlightedHtml;
        block.className = preservedClasses.join(' ');
      }
    });
  }
};

export default SyntaxHighlighter;
