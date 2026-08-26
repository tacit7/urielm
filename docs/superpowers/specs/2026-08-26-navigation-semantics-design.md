# Navigation semantics refinement

Preserve the approved navigation appearance and behavior while aligning its markup with daisyUI v5 guidance.

- Add a focus-visible skip link targeting the global main content region.
- Render desktop destinations as a semantic `menu menu-horizontal` list.
- Pair the mobile `dropdown-content` with a `dropdown dropdown-end` wrapper.
- Retain controlled Svelte open/close state, Escape handling, focus restoration, Tokyo Night tokens, and existing responsive ownership.
- Add focused source and LiveView tests for the semantic contract.
