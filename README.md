<!-- markdownlint-disable MD013 MD033 MD060 -->

# adaptive_actions

![Package][pubdev-package]
![Likes][pubdev-likes]
![Points][pubdev-points]

EN / [中文](README_zh.md)

<!-- Project banner reserved for future artwork. -->

Adaptive action bars for Flutter. Keep the important actions visible, move the
rest into overflow, and share the same action model between Material and
Cupertino UI.

## Features

- Responsive primary actions that change between icon-and-label and icon-only
  presentations before moving into overflow.
- Material and Cupertino renderers backed by the same action tree and command
  payloads.
- Hierarchical menus that keep their declared nesting when a parent action is
  compressed into overflow.
- Pinned, automatic, overflow-only, and hidden placement, plus retention
  priorities and independent display-order overrides.
- Leaf, menu, and composite actions with enabled, destructive, tooltip, and
  semantic-label metadata.
- Menu dividers rendered with the native Material and Cupertino components.
- Custom primary-action and overflow-trigger builders without replacing menu
  ownership or layout resolution.
- Animated layout changes, anchored menus, and LTR/RTL-aware affordances.
- Platform-neutral resolver and renderer extension points for custom UI.

## See it in action

| Material                                                                              | Apple (Cupertino)                                                               |
| ------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| **Responsive Material actions**<br>![Material actions adapt to width][material-demo]   | **Responsive Apple actions**<br>![Apple actions adapt to width][apple-demo]       |
| **Nested hierarchy in overflow**<br>![Material example actions across three available widths][material-nested] | **Nested hierarchy in overflow**<br>![Apple example actions across three available widths][apple-nested] |

| **Custom button builders**                         | **RTL-aware nested menus**                          |
| -------------------------------------------------- | --------------------------------------------------- |
| ![Custom action and More buttons][custom-buttons]  | ![Apple nested menu following RTL][rtl-nested-menu] |

## Getting started

Add the package:

```shell
flutter pub add adaptive_actions
```

Start with one action list. Your app still owns the command handling, so an
enum is often enough for a small feature:

```dart
import 'package:adaptive_actions/material.dart';
import 'package:flutter/material.dart';

enum DocumentCommand { save, share, delete }

final documentActions = ActionCollection<DocumentCommand>(
  roots: [
    AdaptiveAction.action(
      id: ActionId('save'),
      metadata: const ActionMetadata(label: 'Save', iconKey: 'save'),
      payload: DocumentCommand.save,
      placementPolicy: ActionPlacementPolicy(
        placement: ActionPlacement.pinned,
      ),
    ),
    AdaptiveAction.action(
      id: ActionId('share'),
      metadata: const ActionMetadata(label: 'Share', iconKey: 'share'),
      payload: DocumentCommand.share,
    ),
    AdaptiveAction.action(
      id: ActionId('delete'),
      metadata: const ActionMetadata(
        label: 'Delete',
        subtitle: 'This cannot be undone',
        iconKey: 'delete',
        isDestructive: true,
      ),
      payload: DocumentCommand.delete,
      placementPolicy: ActionPlacementPolicy(
        placement: ActionPlacement.overflowOnly,
      ),
    ),
  ],
);
```

Place `MaterialAdaptiveActions` in your Material action area:

```dart
MaterialAdaptiveActions<DocumentCommand>.moreAction(
  actions: documentActions,
  primaryCapacity: 320,
  onInvoke: (command) => handleDocumentCommand(command),
  overflowTooltip: AppLocalizations.of(context).moreActions,
  iconBuilder: (context, action) => switch (action.metadata.iconKey) {
    'save' => const Icon(Icons.save),
    'share' => const Icon(Icons.share),
    'delete' => const Icon(Icons.delete),
    _ => null,
  },
);
```

`primaryCapacity` is the width left for actions after the title, padding, and
other controls have taken their space. As it shrinks, automatic actions use a
smaller layout or move into overflow. Pinned and overflow-only actions keep the
placement you requested.

### Use the Apple UI

Use the same `documentActions` and command handler with the Cupertino widget:

```dart
import 'package:adaptive_actions/cupertino.dart';
import 'package:flutter/cupertino.dart';

CupertinoAdaptiveActions<DocumentCommand>.moreAction(
  actions: documentActions,
  primaryCapacity: 320,
  onInvoke: (command) => handleDocumentCommand(command),
  overflowTooltip: AppLocalizations.of(context).moreActions,
  iconBuilder: (context, action) => switch (action.metadata.iconKey) {
    'save' => const Icon(CupertinoIcons.floppy_disk),
    'share' => const Icon(CupertinoIcons.share),
    'delete' => const Icon(CupertinoIcons.delete),
    _ => null,
  },
)
```

Only the widget and icon mapping change.

Labels, menu subtitles, tooltips, and semantic labels come from
`ActionMetadata`; subtitles appear only in menus. Visual tooltips default to
icon-only primary controls and use `tooltip ?? label`. Configure surfaces per
action with `ActionTooltipPolicy.allowed(...)` or `denied(...)`; their empty
forms are equivalent, while `always()` and `never()` are shortcuts.

Cupertino uses `AdaptiveCupertinoTooltip`; Material uses Flutter's `Tooltip`.
Set the renderer's `tooltipBuilder` to replace that visual wrapper once for all
of its actions. Tooltip policy remains separate from accessibility semantics.
The generic constructors require an explicit `overflowIcon` and keep
`overflowTooltip` empty. The `.moreAction` constructors add the conventional
platform More icon and a visible, overridable `More actions` tooltip; pass your
localized string as shown above when localization is required.

## More examples and behavior

<details>
<summary><strong>Explore the example app</strong></summary>

The [example app](example/lib/main.dart) runs on Android, iOS, Linux, macOS,
Web, and Windows. Its controls let you:

- switch between Material and Apple UI;
- change available width and parent height;
- try placement, retention, and ordering options;
- toggle animations, actions, text direction, and theme;
- open nested menus and inspect the result.

Run it locally:

```shell
cd example
fvm flutter run
```

</details>

<details>
<summary><strong>Placement, menus, and display order</strong></summary>

### Placement

| Placement      | Behavior                                                                                          |
| -------------- | ------------------------------------------------------------------------------------------------- |
| `pinned`       | Stays in the primary area. If it cannot fit, the result reports the problem instead of moving it. |
| `automatic`    | Uses available space and retention priority to choose primary, overflow, or hidden.               |
| `overflowOnly` | Always appears in overflow.                                                                       |
| `hidden`       | Is not shown.                                                                                     |

For automatic actions, `PrimaryRetentionPriority.low`, `.normal`, and `.high`
decide which actions stay visible for longer. Use
`PrimaryRetentionPriority.custom(value)` when you need your own scale.
Retention does not override placement rules or display order.

### Menus and composite actions

| Constructor                | Direct invocation | Children |
| -------------------------- | ----------------- | -------- |
| `AdaptiveAction.action`    | Required          | None     |
| `AdaptiveAction.menu`      | None              | Children or renderer builder |
| `AdaptiveAction.composite` | Required          | Children or renderer builder |

The layout places root actions. When a menu or composite action moves into
overflow, all of its children move with it and keep their declared order. A
disabled branch cannot be invoked or opened.

When an action owns stateful or platform-specific menu content, omit its
children and provide `menuBuilderForAction`. Returning a non-null list replaces
that action's complete menu subtree; returning `null` keeps the recursive
children behavior. Material multi-select menus can use
`CheckboxMenuButton(closeOnActivate: false)`:

```dart
final filters = AdaptiveAction<DocumentCommand>.menu(
  id: ActionId('filters'),
  metadata: const ActionMetadata(label: 'Filters'),
);

MaterialAdaptiveActions<DocumentCommand>.moreAction(
  actions: ActionCollection(roots: [filters]),
  primaryCapacity: 160,
  onInvoke: handleDocumentCommand,
  menuBuilderForAction: (context, action) => action.id != filters.id
      ? null
      : [
          CheckboxMenuButton(
            value: vegan,
            closeOnActivate: false,
            onChanged: updateVegan,
            child: const Text('Vegan'),
          ),
        ],
);
```

Use `CupertinoActionMenuBuilder` on Apple platforms and represent selected
items with a leading checkmark. Set
`CupertinoMenuItem.requestCloseOnActivate` to `false` for persistent
multi-select. The caller owns custom menu state, callbacks, nested content, and
close behavior. The package still owns the action trigger and the first-level
overflow menu; if the action moves into overflow, its custom content becomes
that action's submenu.

Use `AdaptiveMenuDivider` between child actions to separate menu groups. It is
rendered as `PopupMenuDivider` on Material and `CupertinoMenuDivider` on
Cupertino. Both display targets are enabled by default and can be configured
independently:

```dart
AdaptiveAction<DocumentCommand>.menu(
  id: ActionId('share'),
  metadata: const ActionMetadata(label: 'Share'),
  children: [
    shareLink,
    const AdaptiveMenuDivider<DocumentCommand>.menuOnly(),
    deleteShare,
  ],
)
```

Use `ActionCollection.withEntries` when the divider is between top-level
actions:

```dart
final documentActions = ActionCollection<DocumentCommand>.withEntries(
  entries: [
    save,
    const AdaptiveMenuDivider<DocumentCommand>.menuOnly(),
    delete,
  ],
);
```

`showInPrimary` controls the vertical separator between directly rendered
actions. `showInMenu` controls dividers in action and overflow menus. When both
are `false`, the divider remains declared but is not rendered. Dividers never
participate in action placement, and a boundary is omitted when either side has
no adjacent declared action in that region. Use `menuOnly()`, `primaryOnly()`,
or `hidden()` as shorthand for the corresponding visibility settings.

### Display order overrides

Use `primaryOrderOverride` and `overflowOrderOverride` when display order needs
to differ from declaration order:

```dart
MaterialAdaptiveActions<DocumentCommand>.moreAction(
  actions: documentActions,
  primaryCapacity: 320,
  primaryOrderOverride: [ActionId('share'), ActionId('save')],
  overflowOrderOverride: [ActionId('delete'), ActionId('share')],
  onInvoke: (command) => handleDocumentCommand(command),
)
```

Overrides only reorder actions inside primary or overflow. They do not move an
action between regions. Unlisted actions keep their slots, unknown IDs are
ignored, and duplicate IDs are rejected.

</details>

## Framework and Core

Most apps can stay with `MaterialAdaptiveActions` or
`CupertinoAdaptiveActions`. Reach for Core when you need custom placement rules
or a custom renderer.

<details>
<summary><strong>Framework and Core details</strong></summary>

Use these public imports. Do not import
`package:adaptive_actions/src/...`:

```dart
// Material widget plus the complete Core API.
import 'package:adaptive_actions/material.dart';

// Cupertino widget plus the complete Core API.
import 'package:adaptive_actions/cupertino.dart';

// Platform-neutral models and resolver only.
import 'package:adaptive_actions/core.dart';
```

Core places actions; widgets render the result:

```text
ActionCollection + placement policy + available capacity
                           │
                           ▼
                ActionLayoutResolver
                           │
                           ▼
       ordered primary │ overflow │ hidden │ diagnostics
                           │
                           ▼
        Material │ Cupertino │ your own renderer
```

The renderer reports the layouts it can draw and their costs, then renders the
ordered `ActionLayoutResult`. Core does not measure widgets, choose icons, run
commands, or depend on Material or Cupertino.

### Custom placement

Implement `ActionPlacementDelegate` to change placement while keeping the
standard validation and ordering:

```dart
final resolver = ActionLayoutResolver(
  placementDelegate: MyActionPlacementDelegate(),
);

MaterialAdaptiveActions<DocumentCommand>.moreAction(
  actions: documentActions,
  resolver: resolver,
  primaryCapacity: 320,
  onInvoke: (command) => handleDocumentCommand(command),
)
```

The built-in widgets can use that resolver directly.

### Custom rendering

A custom renderer imports `package:adaptive_actions/core.dart`, provides
`ActionLayoutProfile` and `ActionLayoutOption` values, creates an
`ActionLayoutRequest`, and renders the returned `ActionLayoutResult` in order.
It does not need a shared UI base class or Core changes. The final result owns
placement and display order; renderers only translate that result into UI.
Custom renderers can use `primaryDividerBeforeActionIds` and
`overflowDividerBeforeActionIds` to render resolved top-level group boundaries.

</details>

## Development

<details>
<summary><strong>Local checks</strong></summary>

```shell
# Format, analyze, and test the package and example application.
make check
```

</details>

## Donate

[!["Buy Me A Coffee"][buymeacoffee-badge]](https://www.buymeacoffee.com/d49cb87qgww)
[![Alipay][alipay-badge]][alipay-addr]
[![WechatPay][wechat-badge]][wechat-addr]

[![ETH][eth-badge]][eth-addr]
[![BTC][btc-badge]][btc-addr]

## License

This project is licensed under the MIT License.
See [LICENSE](LICENSE) for the full license text.

```text
MIT License

Copyright (c) 2026 Fries_I23

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

[pubdev-package]: https://img.shields.io/pub/v/adaptive_actions.svg
[pubdev-likes]: https://img.shields.io/pub/likes/adaptive_actions?logo=dart
[pubdev-points]: https://img.shields.io/pub/points/adaptive_actions?logo=dart
[material-demo]: screenshots/material-adaptive-actions.webp
[apple-demo]: screenshots/apple-adaptive-actions.webp
[material-nested]: screenshots/material-nested-overflow.webp
[apple-nested]: screenshots/apple-nested-overflow.webp
[custom-buttons]: screenshots/custom-button-builders.webp
[rtl-nested-menu]: screenshots/rtl-nested-menu.webp
[buymeacoffee-badge]: https://img.shields.io/badge/Buy_Me_A_Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black
[alipay-badge]: https://img.shields.io/badge/alipay-00A1E9?style=for-the-badge&logo=alipay&logoColor=white
[alipay-addr]: https://raw.githubusercontent.com/FriesI23/mhabit/main/docs/README/images/donate-alipay.jpg
[wechat-badge]: https://img.shields.io/badge/WeChat-07C160?style=for-the-badge&logo=wechat&logoColor=white
[wechat-addr]: https://raw.githubusercontent.com/FriesI23/mhabit/main/docs/README/images/donate-wechatpay.png
[eth-badge]: https://img.shields.io/badge/Ethereum-3C3C3D?style=for-the-badge&logo=Ethereum&logoColor=white
[eth-addr]: https://etherscan.io/address/0x35FC877Ef0234FbeABc51ad7fC64D9c1bE161f8F
[btc-badge]: https://img.shields.io/badge/Bitcoin-000000?style=for-the-badge&logo=bitcoin&logoColor=white
[btc-addr]: https://blockchair.com/bitcoin/address/bc1qz2vjews2fcscmvmcm5ctv47mj6236x9p26zk49
