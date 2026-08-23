<!-- markdownlint-disable MD013 MD033 MD060 -->

# adaptive_actions

![Package][pubdev-package]
![Likes][pubdev-likes]
![Points][pubdev-points]

[EN](README.md) / 中文

<!-- Project banner reserved for future artwork. -->

用于 Flutter 的自适应操作组件。重要操作直接显示，放不下的收入更多菜单；同一组
操作可以同时用于 Material 和 Cupertino UI。

## 功能特点

- 直接显示的操作可随空间在 icon + label、icon-only 和更多菜单之间自适应切换。
- Material 与 Cupertino renderer 共用同一棵操作树和 command payload。
- 父级操作被压缩进更多菜单后，子菜单仍保留声明时的层级结构。
- 支持 `pinned`、`automatic`、`overflowOnly` 和 `hidden` 放置方式，以及保留
  优先级和各区域独立的显示顺序覆盖。
- 支持普通操作、菜单和复合操作，以及可用状态、危险操作、tooltip 和语义标签。
- 可以只替换直接显示的操作按钮或更多菜单入口，不接管菜单和布局逻辑。
- 支持布局变化动画、锚定菜单和 LTR/RTL 自适应 affordance。
- 提供平台无关的 resolver 与 renderer 扩展点，可接入自定义 UI。

## 效果展示

| Material                                                                        | Apple（Cupertino）                                                          |
| ------------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| **Material 自适应操作**<br>![Material 操作随宽度变化][material-demo]             | **Apple 自适应操作**<br>![Apple 操作随宽度变化][apple-demo]                  |
| **收入更多菜单后保留层级**<br>![Material example 操作在三档可用宽度下的变化][material-nested] | **收入更多菜单后保留层级**<br>![Apple example 操作在三档可用宽度下的变化][apple-nested] |

| **自定义按钮 builder**                              | **RTL 多级菜单**                              |
| --------------------------------------------------- | --------------------------------------------- |
| ![自定义操作按钮和更多菜单入口][custom-buttons]     | ![Apple 多级菜单跟随 RTL 方向][rtl-nested-menu] |

## 开始使用

添加依赖：

```shell
flutter pub add adaptive_actions
```

先定义一组操作。命令处理仍在你的 app 里，所以小功能通常用一个
enum 就够：

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

把 `MaterialAdaptiveActions` 放进 Material 界面的操作区域：

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
)
```

`primaryCapacity` 是标题、padding 和其他控件占位后，留给操作的宽度。
宽度变小时，`automatic` 操作会切换到更紧凑的样式，或者进入更多菜单；`pinned` 和
`overflowOnly` 操作会遵循指定的放置策略（placement）。

### 使用 Apple UI

同一份 `documentActions` 和命令处理逻辑也可以用于 Cupertino widget：

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

这里只需更换 widget 和 icon 映射。

操作的 label、tooltip 和 semantic label 都来自调用方传入的 `ActionMetadata`。
通用构造器要求显式传入 `overflowIcon`，并保持 `overflowTooltip` 为空；
`.moreAction` 构造器提供各平台惯用的更多图标，以及明显且可覆盖的
`More actions` tooltip。需要多语言时，像上面的示例一样传入本地化字符串即可。

## 更多示例与行为说明

<details>
<summary><strong>查看 example 应用</strong></summary>

[example](example/lib/main.dart) 支持 Android、iOS、Linux、macOS、Web
和 Windows。里面的控制项可以：

- 切换 Material 和 Apple UI；
- 调整可用宽度和父级高度；
- 尝试不同的放置方式、保留优先级和排序选项；
- 开关动画、操作、文字方向和主题；
- 打开多级菜单，查看布局结果。

本地运行：

```shell
cd example
fvm flutter run
```

</details>

<details>
<summary><strong>放置方式、菜单与显示顺序</strong></summary>

### 放置方式

| 放置方式       | 行为                                                       |
| -------------- | ---------------------------------------------------------- |
| `pinned`       | 保持直接显示；放不下时结果会报告问题，不会自动挪走。       |
| `automatic`    | 根据可用空间和保留优先级决定直接显示、收入更多菜单或隐藏。 |
| `overflowOnly` | 始终进入更多菜单。                                         |
| `hidden`       | 不显示。                                                   |

对于 `automatic` 操作，`PrimaryRetentionPriority.low`、`.normal` 和 `.high` 决定
哪些操作更晚进入更多菜单。需要自定义数值时，使用
`PrimaryRetentionPriority.custom(value)`。保留优先级不会覆盖放置规则，也不会
改变显示顺序。

### 菜单与复合操作

| 构造器                     | 可直接调用 | 子操作 |
| -------------------------- | ---------- | ------ |
| `AdaptiveAction.action`    | 必需       | 无     |
| `AdaptiveAction.menu`      | 无         | 必需   |
| `AdaptiveAction.composite` | 必需       | 必需   |

布局以顶层操作为单位。菜单或复合操作进入更多菜单时，它的子操作会一起移动，并
保留声明顺序。禁用的分支不能调用，也不能打开。

### 覆盖显示顺序

需要让显示顺序不同于声明顺序时，使用 `primaryOrderOverride` 和
`overflowOrderOverride`：

```dart
MaterialAdaptiveActions<DocumentCommand>.moreAction(
  actions: documentActions,
  primaryCapacity: 320,
  primaryOrderOverride: [ActionId('share'), ActionId('save')],
  overflowOrderOverride: [ActionId('delete'), ActionId('share')],
  onInvoke: (command) => handleDocumentCommand(command),
)
```

顺序覆盖只改变直接显示区域或更多菜单内部的顺序，不会把操作从一个区域移到另一个区域。
未列出的操作保留原位，未知 ID 会被忽略，重复 ID 会被拒绝。

</details>

## Framework 与 Core

大多数 app 用 `MaterialAdaptiveActions` 或 `CupertinoAdaptiveActions` 就够。
需要自定义放置规则或 renderer 时，再接 Core。

<details>
<summary><strong>Framework 与 Core 详细说明</strong></summary>

使用这些公开入口，不要导入 `package:adaptive_actions/src/...`：

```dart
// Material widget plus the complete Core API.
import 'package:adaptive_actions/material.dart';

// Cupertino widget plus the complete Core API.
import 'package:adaptive_actions/cupertino.dart';

// Platform-neutral models and resolver only.
import 'package:adaptive_actions/core.dart';
```

Core 决定操作放在哪里，widgets 负责 render：

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

renderer 报告自己支持的 layout 及其成本，再按 `ActionLayoutResult` 的顺序 render。
Core 不测量 widget、不选择 icon、不执行 command，也不依赖 Material 或 Cupertino。

### 自定义放置逻辑

实现 `ActionPlacementDelegate` 可以改变操作的放置逻辑，同时保留标准校验和排序：

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

内置 widgets 可以直接使用这个 resolver。

### 自定义 renderer

自定义 renderer 只需导入 `package:adaptive_actions/core.dart`，提供自己的
`ActionLayoutProfile` 和 `ActionLayoutOption`，创建 `ActionLayoutRequest`，再按顺序
render 返回的 `ActionLayoutResult`。不需要统一的 UI 基类，也不需要改 Core。最终结果已经决定
placement 和显示顺序，renderer 只负责将它转换成 UI。

</details>

## 开发

<details>
<summary><strong>本地检查</strong></summary>

```shell
# Format, analyze, and test the package and example application.
make check
```

</details>

## 捐赠

[!["Buy Me A Coffee"][buymeacoffee-badge]](https://www.buymeacoffee.com/d49cb87qgww)
[![Alipay][alipay-badge]][alipay-addr]
[![WechatPay][wechat-badge]][wechat-addr]

[![ETH][eth-badge]][eth-addr]
[![BTC][btc-badge]][btc-addr]

## 许可证

本项目基于 MIT License 许可。
完整许可文本见 [LICENSE](LICENSE)。

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
