// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { hooks as colocatedHooks } from "phoenix-colocated/review_room";
import topbar from "../vendor/topbar";

// Import Highlight.js for syntax highlighting
import hljs from "highlight.js/lib/core";
import elixir from "highlight.js/lib/languages/elixir";
import javascript from "highlight.js/lib/languages/javascript";
import python from "highlight.js/lib/languages/python";
import ruby from "highlight.js/lib/languages/ruby";
import go from "highlight.js/lib/languages/go";
import rust from "highlight.js/lib/languages/rust";
import sql from "highlight.js/lib/languages/sql";
import xml from "highlight.js/lib/languages/xml";
import css from "highlight.js/lib/languages/css";
import json from "highlight.js/lib/languages/json";
import yaml from "highlight.js/lib/languages/yaml";
import markdown from "highlight.js/lib/languages/markdown";

// Register languages with Highlight.js
hljs.registerLanguage("elixir", elixir);
hljs.registerLanguage("javascript", javascript);
hljs.registerLanguage("python", python);
hljs.registerLanguage("ruby", ruby);
hljs.registerLanguage("go", go);
hljs.registerLanguage("rust", rust);
hljs.registerLanguage("sql", sql);
hljs.registerLanguage("xml", xml);
hljs.registerLanguage("html", xml);
hljs.registerLanguage("css", css);
hljs.registerLanguage("json", json);
hljs.registerLanguage("yaml", yaml);
hljs.registerLanguage("markdown", markdown);

// Custom hooks for snippet feature
let Hooks = {};

Hooks.SyntaxHighlight = {
  mounted() {
    this.highlight();
  },
  updated() {
    this.highlight();
  },
  highlight() {
    this.el.querySelectorAll("pre code:not(.hljs)").forEach((block) => {
      hljs.highlightElement(block);
    });
  },
};

Hooks.CodeInput = {
  mounted() {
    this.updateCounter();
    this.el.addEventListener("input", () => this.updateCounter());
  },
  updateCounter() {
    const bytes = new Blob([this.el.value]).size;
    const maxBytes = 512000;
    const percentage = (bytes / maxBytes) * 100;

    const counter = document.getElementById("size-counter");
    if (counter) {
      counter.textContent = `${this.formatBytes(bytes)} / 500 KB`;
      counter.className =
        percentage >= 100 ? "text-red-600" : percentage >= 90 ? "text-yellow-600" : "text-gray-600";
    }
  },
  formatBytes(bytes) {
    return `${(bytes / 1024).toFixed(1)} KB`;
  },
};

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: { ...colocatedHooks, ...Hooks },
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({ detail: reloader }) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs();

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown;
    window.addEventListener("keydown", (e) => (keyDown = e.key));
    window.addEventListener("keyup", (e) => (keyDown = null));
    window.addEventListener(
      "click",
      (e) => {
        if (keyDown === "c") {
          e.preventDefault();
          e.stopImmediatePropagation();
          reloader.openEditorAtCaller(e.target);
        } else if (keyDown === "d") {
          e.preventDefault();
          e.stopImmediatePropagation();
          reloader.openEditorAtDef(e.target);
        }
      },
      true,
    );

    window.liveReloader = reloader;
  });
}
