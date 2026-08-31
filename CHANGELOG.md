# Changelog

## 0.4.0

- Added independent single-line label width and overflow policies for each
  Material and Cupertino root action.
- Updated action measurement to honor the ambient locale and text scaler, and
  scale primary icons before placement resolution.
- Expanded the example with English and Chinese label comparisons for
  ellipsis, fade, and unconstrained label widths.

## 0.3.0

> **Breaking change:** Action-region composition now uses package-owned slot
> and layout-plan contracts. Custom integrations that imported unsupported
> `package:adaptive_actions/src/widgets/...` internals must migrate to the
> public APIs exported by `material.dart`, `cupertino.dart`, or
> `adaptive_actions.dart`. Existing supported constructors retain their
> default compact behavior.

- Added compact, space-between, space-around, and space-evenly single-region
  distributions shared by Material and Cupertino renderers.
- Added two-stage layout delegates for fixed and flexible action slots and
  gaps, including immutable plans, validation, and fixed pre-resolution
  reservations.
- Preserved one Core resolution per layout pass while exposing final tight
  action widths to custom button builders.
- Expanded the example and regression coverage for custom gaps, resize
  animation, overflow, unbounded constraints, and LTR/RTL placement.

## 0.2.2

- Deferred Cupertino menu action callbacks to at least the next frame so they
  can safely replace their host widget tree.
- Added `invokeAfterMenuClosed` to optionally wait for the root Cupertino menu
  to finish closing before invoking the selected action.
- Added an adaptive menu-to-dialog example and regression coverage for
  Cupertino and Material host replacement.

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
