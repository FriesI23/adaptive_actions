# Changelog

## 0.2.1

- Added per-action Material and Cupertino primary presentations with
  resolver-aware mixed icon-only and icon-plus-label layouts.

## 0.2.0

> **Breaking change:** `AdaptiveAction.children` changed from
> `List<AdaptiveAction<T>>` to `List<AdaptiveMenuEntry<T>>`. Callers that read
> children directly must now handle or filter `AdaptiveMenuDivider<T>` entries.

- Added configurable dividers for nested menus and top-level actions across
  Material and Cupertino.

## 0.1.2

- Added optional menu subtitles through `ActionMetadata.subtitle`, with native
  Cupertino presentation and Material supporting-text styling.
- Preserved primary action layout while extending nested, composite, disabled,
  destructive, accessible, and large-text menu behavior.

## 0.1.1

- Expanded the bilingual README feature overview and visual gallery with
  focused demos for adaptive layout, nested overflow menus, custom button
  builders, and RTL directionality.

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
