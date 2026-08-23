## 0.1.0

- Added a renderer-neutral action tree, placement constraints, deterministic
  layout resolution, and independent primary and overflow ordering.
- Added adaptive Material and Cupertino renderers with anchored, hierarchical
  menus, composite actions, customizable presentation, animated Material menu
  transitions, and animated layout changes.
- Added platform-specific `.moreAction` constructors while keeping generic
  overflow icons explicit and their tooltip defaults semantically distinct.
- Added custom resolver and renderer extension points backed by immutable
  layout request and result contracts.
- Added a six-platform example, bilingual documentation, architecture boundary
  tests, and release CI.
