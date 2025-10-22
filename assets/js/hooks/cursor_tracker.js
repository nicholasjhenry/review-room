/**
 * CursorTracker Hook
 *
 * Tracks cursor position and text selection in code snippets,
 * broadcasting updates to the LiveView for real-time collaboration.
 */

const CursorTracker = {
  mounted() {
    this.throttleDelay = 100; // 100ms throttle for cursor updates
    this.lastCursorUpdate = 0;

    // Add event listeners
    this.handleMouseMove = this.throttledCursorMove.bind(this);
    this.handleMouseUp = this.handleSelection.bind(this);

    this.el.addEventListener('mousemove', this.handleMouseMove);
    this.el.addEventListener('mouseup', this.handleMouseUp);
  },

  destroyed() {
    // Clean up event listeners
    this.el.removeEventListener('mousemove', this.handleMouseMove);
    this.el.removeEventListener('mouseup', this.handleMouseUp);
  },

  /**
   * Throttled cursor move handler
   * Limits cursor position updates to once per throttleDelay milliseconds
   */
  throttledCursorMove(event) {
    const now = Date.now();
    if (now - this.lastCursorUpdate < this.throttleDelay) {
      return;
    }

    this.lastCursorUpdate = now;

    const position = this.getLineColumn(event);
    if (position) {
      this.pushEvent('cursor_moved', position);
    }
  },

  /**
   * Handle text selection
   * Fires when user releases mouse button, potentially after selecting text
   */
  handleSelection(event) {
    const selection = window.getSelection();

    if (selection && selection.rangeCount > 0 && !selection.isCollapsed) {
      const range = selection.getRangeAt(0);
      const selectionRange = this.getSelectionRange(range);

      if (selectionRange) {
        this.pushEvent('text_selected', selectionRange);
      }
    } else {
      // Selection cleared
      this.pushEvent('selection_cleared', {});
    }
  },

  /**
   * Get line and column from mouse event
   * @param {MouseEvent} event
   * @returns {{line: number, column: number}|null}
   */
  getLineColumn(event) {
    const codeElement = this.el.querySelector('pre code');
    if (!codeElement) return null;

    // Get the text node at cursor position
    const range = document.caretRangeFromPoint(event.clientX, event.clientY);
    if (!range) return null;

    // Calculate line and column from range
    const textContent = codeElement.textContent;
    const lines = textContent.split('\n');

    // Get offset from start of code block
    let offset = 0;
    let node = codeElement.firstChild;

    while (node && node !== range.startContainer) {
      if (node.nodeType === Node.TEXT_NODE) {
        offset += node.textContent.length;
      }
      node = this.getNextNode(node, codeElement);
    }

    offset += range.startOffset;

    // Convert offset to line and column
    let currentOffset = 0;
    for (let line = 0; line < lines.length; line++) {
      const lineLength = lines[line].length + 1; // +1 for newline
      if (currentOffset + lineLength > offset) {
        return {
          line: line + 1, // 1-indexed
          column: offset - currentOffset
        };
      }
      currentOffset += lineLength;
    }

    return null;
  },

  /**
   * Get selection range from DOM Range object
   * @param {Range} range
   * @returns {{start: {line: number, column: number}, end: {line: number, column: number}}|null}
   */
  getSelectionRange(range) {
    const codeElement = this.el.querySelector('pre code');
    if (!codeElement) return null;

    const textContent = codeElement.textContent;
    const lines = textContent.split('\n');

    // Get start and end offsets
    const startOffset = this.getOffsetFromRange(codeElement, range.startContainer, range.startOffset);
    const endOffset = this.getOffsetFromRange(codeElement, range.endContainer, range.endOffset);

    if (startOffset === null || endOffset === null) return null;

    // Convert offsets to line/column positions
    const start = this.offsetToLineColumn(lines, startOffset);
    const end = this.offsetToLineColumn(lines, endOffset);

    if (!start || !end) return null;

    return { start, end };
  },

  /**
   * Get offset from start of code element to a specific node and offset
   * @param {Element} codeElement
   * @param {Node} targetNode
   * @param {number} targetOffset
   * @returns {number|null}
   */
  getOffsetFromRange(codeElement, targetNode, targetOffset) {
    let offset = 0;
    let node = codeElement.firstChild;

    while (node) {
      if (node === targetNode) {
        return offset + targetOffset;
      }

      if (node.nodeType === Node.TEXT_NODE) {
        offset += node.textContent.length;
      }

      if (node.contains && node.contains(targetNode)) {
        // Target is inside this node, traverse children
        node = node.firstChild;
      } else {
        node = this.getNextNode(node, codeElement);
      }
    }

    return null;
  },

  /**
   * Convert character offset to line and column
   * @param {string[]} lines
   * @param {number} offset
   * @returns {{line: number, column: number}|null}
   */
  offsetToLineColumn(lines, offset) {
    let currentOffset = 0;

    for (let line = 0; line < lines.length; line++) {
      const lineLength = lines[line].length + 1; // +1 for newline
      if (currentOffset + lineLength > offset) {
        return {
          line: line + 1, // 1-indexed
          column: offset - currentOffset
        };
      }
      currentOffset += lineLength;
    }

    return null;
  },

  /**
   * Get next node in tree traversal
   * @param {Node} node
   * @param {Element} root
   * @returns {Node|null}
   */
  getNextNode(node, root) {
    if (node.firstChild) {
      return node.firstChild;
    }

    while (node) {
      if (node === root) return null;
      if (node.nextSibling) return node.nextSibling;
      node = node.parentNode;
    }

    return null;
  }
};

export default CursorTracker;
