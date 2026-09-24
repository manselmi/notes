// vim: set ft=javascript :
//
// https://zensical.org/docs/authoring/diagrams/#customization

import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@12/dist/mermaid.esm.min.mjs';

mermaid.initialize({
  startOnLoad: false,
  securityLevel: 'loose',
});

// Important: necessary to make it visible to Zensical
window.mermaid = mermaid;
