## 1. Build diagnostics and provenance

- [x] 1.1 Add node-targeted issue records without removing readable CLI errors or existing validation rules.
- [x] 1.2 Add versioned external-resource fingerprints and checked-export preflight for public source/build associations; rebuild the sample without changing its authored layout.

## 2. Editor interaction

- [x] 2.1 Implement active-camera click placement, transient preview, surface rules, snap/facing controls and explicit centre fallback with undo/redo/cancel/scene cleanup.
- [x] 2.2 Add clickable issue selection, source/output navigation, clear status and lifecycle-safe busy handling.
- [x] 2.3 Add Checked Export action/CLI wrapper and honest stock-export bypass warning; prove stale maps never invoke checked export or overwrite outputs.

## 3. Level discovery and menus

- [x] 3.1 Add runtime-safe public built-map discovery without actor instantiation or editor dependencies.
- [x] 3.2 Add bounded keyboard/mouse level selection, duplicate-title/empty handling and Back/Escape; preserve default Start, mapping shortcut and restart lifecycle.

## 4. Verification and handoff

- [x] 4.1 Exercise actual editor input/undo/preview/clickable issues/save/reopen/export failures and runtime map-menu/restart behaviour, retaining gameplay regressions.
- [x] 4.2 Run full source/editor/offline/render and isolated packaged/audit/native checks; provide separate 0.7.0 evidence without replacing older artifacts.
- [x] 4.3 Document the workflow, version/compatibility details, checked-vs-stock export distinction and exact verification results.
- [ ] 4.4 Obtain user review of the polished editing workflow; do not infer human ergonomics/full-run acceptance from automation.
