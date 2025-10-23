/**
 * PresenceRenderer Hook
 *
 * Renders visual overlays for other users' cursors and text selections
 * on the code snippet display.
 *
 * Features:
 * - Colored cursor indicators at user positions
 * - Pixel-perfect highlighted selection ranges using Range API
 * - Username tooltips on cursor hover
 * - Accurate positioning using computed styles
 */

export const PresenceRenderer = {
  mounted() {
    this.renderPresences();
  },

  updated() {
    this.renderPresences();
  },

  renderPresences() {
    // Clear existing overlays
    this.el.innerHTML = "";

    // Get presences data from attribute
    const presencesData = this.el.getAttribute("data-presences");
    if (!presencesData) return;

    let presences;
    try {
      presences = JSON.parse(presencesData);
    } catch (e) {
      console.error("Failed to parse presences data:", e);
      return;
    }

    // Get the code display element for positioning
    const codeDisplay = document.getElementById("code-display");
    if (!codeDisplay) return;

    const codeElement = codeDisplay.querySelector("code");
    if (!codeElement) return;

    // Calculate metrics once for all overlays
    const metrics = this.calculateMetrics(codeElement);

    // Render cursors and selections for each user
    Object.entries(presences).forEach(([userId, presence]) => {
      const meta = presence.metas[0];
      if (!meta) return;

      const color = meta.color || "#6B7280";
      const displayName = meta.display_name || "Anonymous User";

      // Render cursor if present
      if (meta.cursor) {
        this.renderCursor(meta.cursor, color, displayName, codeElement, metrics);
      }

      // Render selection if present
      if (meta.selection) {
        this.renderSelection(meta.selection, color, displayName, codeElement, metrics);
      }
    });
  },

  calculateMetrics(codeElement) {
    const computedStyle = window.getComputedStyle(codeElement);
    const lineHeight = parseFloat(computedStyle.lineHeight) || 24;

    // Create a temporary span to measure character width
    const measureSpan = document.createElement("span");
    measureSpan.textContent = "M";
    measureSpan.style.font = computedStyle.font;
    measureSpan.style.fontSize = computedStyle.fontSize;
    measureSpan.style.fontFamily = computedStyle.fontFamily;
    measureSpan.style.visibility = "hidden";
    measureSpan.style.position = "absolute";
    document.body.appendChild(measureSpan);
    const charWidth = measureSpan.offsetWidth;
    document.body.removeChild(measureSpan);

    // Get padding from pre element
    const preElement = codeElement.closest("pre");
    const preStyle = window.getComputedStyle(preElement);
    const paddingLeft = parseFloat(preStyle.paddingLeft) || 16;
    const paddingTop = parseFloat(preStyle.paddingTop) || 16;

    return { lineHeight, charWidth, paddingLeft, paddingTop };
  },

  renderCursor(cursor, color, displayName, codeElement, metrics) {
    const { line, column } = cursor;

    // Get code lines
    const codeText = codeElement.textContent;
    const lines = codeText.split("\n");

    if (line < 1 || line > lines.length) return;

    const { lineHeight, charWidth, paddingLeft, paddingTop } = metrics;

    // Calculate position relative to code element
    const codeTop = (line - 1) * lineHeight + paddingTop;
    const codeLeft = column * charWidth + paddingLeft;

    // Get bounding rects to convert to overlay coordinates
    const overlayRect = this.el.getBoundingClientRect();
    const codeRect = codeElement.getBoundingClientRect();

    // Convert from code element space to overlay space
    const top = codeTop + (codeRect.top - overlayRect.top);
    const left = codeLeft + (codeRect.left - overlayRect.left);

    // Create cursor element
    const cursorEl = document.createElement("div");
    cursorEl.className = "absolute pointer-events-auto";
    cursorEl.style.top = `${top}px`;
    cursorEl.style.left = `${left}px`;
    cursorEl.style.width = "2px";
    cursorEl.style.height = `${lineHeight}px`;
    cursorEl.style.backgroundColor = color;
    cursorEl.style.zIndex = "20";
    cursorEl.style.transition = "all 0.2s ease";

    // Add tooltip with username
    cursorEl.title = displayName;

    // Add a small flag at the top with username
    const flagEl = document.createElement("div");
    flagEl.className = "absolute text-xs text-white px-2 py-1 rounded shadow-lg whitespace-nowrap";
    flagEl.style.backgroundColor = color;
    flagEl.style.top = "-2px";
    flagEl.style.left = "4px";
    flagEl.style.fontSize = "11px";
    flagEl.style.lineHeight = "1";
    flagEl.textContent = displayName;

    cursorEl.appendChild(flagEl);
    this.el.appendChild(cursorEl);
  },

  renderSelection(selection, color, displayName, codeElement, metrics) {
    const { start, end } = selection;

    // Get code lines
    const codeText = codeElement.textContent;
    const lines = codeText.split("\n");

    if (start.line < 1 || end.line > lines.length) return;

    // Use Range API for pixel-perfect positioning
    try {
      // Get all text nodes in the code element
      const textNodes = this.getTextNodes(codeElement);

      // Calculate absolute character offsets
      const startOffset = this.getAbsoluteOffset(lines, start.line, start.column);
      const endOffset = this.getAbsoluteOffset(lines, end.line, end.column);

      // Find text node positions
      const startPos = this.findTextNodePosition(textNodes, startOffset);
      const endPos = this.findTextNodePosition(textNodes, endOffset);

      if (!startPos || !endPos) {
        this.renderSelectionFallback(selection, color, displayName, codeElement, metrics, lines);
        return;
      }

      // Create a Range to get exact bounding rectangles
      const range = document.createRange();
      range.setStart(startPos.node, startPos.offset);
      range.setEnd(endPos.node, endPos.offset);

      // Get all client rects for the selection (handles multi-line perfectly)
      const rects = range.getClientRects();

      // Get bounding rects - we need to position relative to the overlay container
      const overlayRect = this.el.getBoundingClientRect();

      // Render a highlight for each rect
      for (let i = 0; i < rects.length; i++) {
        const rect = rects[i];

        // Calculate position relative to the overlay container
        const top = rect.top - overlayRect.top;
        const left = rect.left - overlayRect.left;
        const width = rect.width;
        const height = rect.height;

        // Create selection highlight
        const selectionEl = document.createElement("div");
        selectionEl.className = "absolute pointer-events-none";
        selectionEl.style.top = `${top}px`;
        selectionEl.style.left = `${left}px`;
        selectionEl.style.width = `${width}px`;
        selectionEl.style.height = `${height}px`;
        selectionEl.style.backgroundColor = color;
        selectionEl.style.opacity = "0.2";
        selectionEl.style.zIndex = "15";
        selectionEl.title = `${displayName}'s selection`;

        this.el.appendChild(selectionEl);
      }
    } catch (e) {
      console.warn("Range API failed, using fallback:", e);
      this.renderSelectionFallback(selection, color, displayName, codeElement, metrics, lines);
    }
  },

  getTextNodes(element) {
    const textNodes = [];
    const walker = document.createTreeWalker(element, NodeFilter.SHOW_TEXT, null, false);

    let node;
    while ((node = walker.nextNode())) {
      textNodes.push(node);
    }

    return textNodes;
  },

  getAbsoluteOffset(lines, line, column) {
    // Calculate total character offset from beginning of text
    let offset = 0;

    // Add lengths of all previous lines (including newline characters)
    for (let i = 0; i < line - 1; i++) {
      offset += lines[i].length + 1; // +1 for newline
    }

    // Add column offset on the current line
    offset += column;

    return offset;
  },

  findTextNodePosition(textNodes, targetOffset) {
    let currentOffset = 0;

    for (const node of textNodes) {
      const nodeLength = node.textContent.length;

      if (currentOffset + nodeLength >= targetOffset) {
        return {
          node: node,
          offset: targetOffset - currentOffset,
        };
      }

      currentOffset += nodeLength;
    }

    // Return last position if offset is beyond text
    if (textNodes.length > 0) {
      const lastNode = textNodes[textNodes.length - 1];
      return {
        node: lastNode,
        offset: lastNode.textContent.length,
      };
    }

    return null;
  },

  renderSelectionFallback(selection, color, displayName, codeElement, metrics, lines) {
    const { start, end } = selection;
    const { lineHeight, charWidth, paddingLeft, paddingTop } = metrics;

    // Render selection line by line using character-based positioning
    for (let lineNum = start.line; lineNum <= end.line; lineNum++) {
      const lineText = lines[lineNum - 1];
      if (!lineText && lineNum !== end.line) continue;

      let startCol, endCol;

      if (lineNum === start.line && lineNum === end.line) {
        startCol = start.column;
        endCol = end.column;
      } else if (lineNum === start.line) {
        startCol = start.column;
        endCol = lineText ? lineText.length : 0;
      } else if (lineNum === end.line) {
        startCol = 0;
        endCol = end.column;
      } else {
        startCol = 0;
        endCol = lineText ? lineText.length : 0;
      }

      const top = (lineNum - 1) * lineHeight + paddingTop;
      const left = startCol * charWidth + paddingLeft;
      const width = Math.max((endCol - startCol) * charWidth, 4);

      const selectionEl = document.createElement("div");
      selectionEl.className = "absolute pointer-events-none";
      selectionEl.style.top = `${top}px`;
      selectionEl.style.left = `${left}px`;
      selectionEl.style.width = `${width}px`;
      selectionEl.style.height = `${lineHeight}px`;
      selectionEl.style.backgroundColor = color;
      selectionEl.style.opacity = "0.2";
      selectionEl.style.zIndex = "15";
      selectionEl.title = `${displayName}'s selection`;

      this.el.appendChild(selectionEl);
    }
  },
};
