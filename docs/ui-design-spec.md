# ASMR One (Yuro) 应用开发规范 v3.0

> 本规范为 Yuro 应用提供统一的视觉语言、组件标准、高性能动画准则及性能优化方案。
> 作为一款 ASMR 音频应用，设计核心围绕 **宁静、沉浸、平顺** 展开，严格遵循 Material 3 标准。

---

## 目录

1. [设计令牌 (Design Tokens)](#1-设计令牌-design-tokens)
2. [组件设计标准](#2-组件设计标准)
3. [动画与微交互](#3-动画与微交互)
4. [无障碍标准 (Accessibility)](#4-无障碍标准-accessibility)
5. [响应式布局规则](#5-响应式布局规则)
6. [组件开发规范](#6-组件开发规范)
7. [性能优化准则](#7-性能优化准则)
8. [开发工作流规范](#8-开发工作流规范)

---

## 1. 设计令牌 (Design Tokens)

### 1.1 颜色系统 (Color System)

基于紫色调 Material 3 主题，强调多层级表面以增强视觉深度。

#### 核心调色板

| 语义层级 | 亮色模式 (Light) | 暗色模式 (Dark) | 用途 |
| :--- | :--- | :--- | :--- |
| **Primary** | #6750A4 | #D0BCFF | 品牌色、主要交互、进度条 |
| **Surface** | #FFFFFF | #1C1B1F | 基础底色 |
| **Surface L1** | #F7F2FA | #25232A | 容器层、次级卡片 |
| **Surface L2** | #F3EDF7 | #2B2930 | 侧边栏、搜索框、对话框背景 |
| **Surface L3** | #E6E6E6 | #2B2B2B | 最高的对比层 |

> **注意**：Surface L1 (#F7F2FA / #25232A) 和 Surface L2 (#F3EDF7 / #2B2930) 为本规范新增的设计令牌，尚未在 `app_colors.dart` 中实现。需在实施时同步更新主题代码。

#### 交互状态 (Interactive States)

| 状态 | 定义 | 叠加层 (Overlay) |
| :--- | :--- | :--- |
| **Hover** | 鼠标悬停 | Primary 8% 叠加 |
| **Pressed** | 按下反馈 | Primary 12% 叠加 |
| **Focused** | 聚焦状态 | Primary 12% 叠加 + 2px 外轮廓 (Outline) |
| **Disabled** | 禁用状态 | 38% 不透明度 (Opacity) |

#### 渐变定义 (Gradients)

- **播放器背景 (Dark)**: 垂直渐变，`Surface` (#1C1B1F) → `Surface L1` (#25232A)。
- **封面遮罩**: 底部 30% 黑色渐变，用于确保白色文字在浅色封面上可见。

---

### 1.2 排版规范 (Typography)

| 类型 | 粗细 | 大小 (sp) | 行高 | 用途 |
| :--- | :--- | :--- | :--- | :--- |
| **Headline Medium** | Medium | 28 | 1.2 | 大标题 |
| **Title Large** | Medium | 22 | 1.3 | AppBar 标题 |
| **Title Medium** | Medium | 16 | 1.5 | 列表标题、卡片标题 |
| **Body Large** | Regular | 16 | 1.5 | 主要正文内容 |
| **Body Medium** | Regular | 14 | 1.5 | 次要描述、副标题 |
| **Label Medium** | Medium | 12 | 1.3 | 标签、按钮文字、小图标注 |
| **Caption** | Regular | 10 | 1.2 | 时间戳、版权信息 |

---

### 1.3 间距与布局 (Spacing)

采用 **4px 基准网格** 系统。

- **Tokens**: 4, 8, 12, 16, 20, 24, 32, 40, 48, 64。
- **布局间距**: 移动端 16px，平板/桌面端 24px。

---

### 1.4 圆角 (Border Radius)

- **Small (8px)**: 标签 (Chips)、工具提示。
- **Medium (12px)**: 作品卡片、列表项。
- **Large (16px)**: 播放器抽屉、底部面板、对话框。
- **Full (999px)**: 胶囊按钮、头像。

---

### 1.5 图标系统 (Icon System)

| 尺寸 Token | 像素值 (dp) | 用途 |
| :--- | :--- | :--- |
| **Inline** | 16 | 正文内嵌图标 |
| **List Leading** | 20 | 列表前置图标 |
| **Standard** | 24 | 标准操作按钮 |
| **Emphasis** | 32 | 播放/暂停等强调操作 |
| **Feature** | 48 | 空状态、特性展示 |

- **不透明度**: 激活 87%，非激活 60%，禁用 38%。
- **点击区域**:
  - 24px 图标 → 48×48px 点击目标。
  - 20px 图标 → 40×40px 点击目标。
- **播放器特定**: 播放/暂停 32px，切歌 24px，循环/随机 20px。

---

### 1.6 海拔系统 (Elevation System)

遵循 Material 3 的高度层级。**注意：在暗色模式下，不使用阴影，而是使用 Surface Tint (表面色调叠加) 来区分层级。**

- **E0 (0dp)**: 卡片、平面容器。
- **E1 (1dp)**: 底部导航栏、滚动后的 AppBar。
- **E2 (3dp)**: 悬浮按钮 (FAB) 静止状态、底部抽屉 (Bottom Sheets)。
- **E3 (6dp)**: 悬浮按钮 (FAB) 按下状态、对话框 (Dialogs)。
- **E4 (8dp)**: 菜单 (Menus)、弹出框 (Popovers)。

---

## 2. 组件设计标准

### 2.1 作品卡片 (Work Cards)

- **比例**: 1:1 正方形封面。
- **交互**: 悬停时表面 8% Primary 遮罩，按下缩放至 0.95。

### 2.2 按钮 (Buttons)

- **FilledButton**: 高度 40px，横向内边距 24px，全圆角 (20px)，Primary 背景。
- **OutlinedButton**: 高度 40px，1px 边框，背景透明。
- **TextButton**: 高度 40px，无背景，使用 Primary 文本。
- **IconButton**: 48×48px 触碰目标，40×40px 可视区域，20px 半径涟漪效果。
- **通用限制**: 禁用状态统一使用 38% 不透明度，不定义自定义禁用颜色。

### 2.3 迷你播放器 (Mini Player)

- **高度**: 48px (内容区) + 底部安全区。
- **布局**: `[封面 48×48]` + `[16px 间距]` + `[标题/作者列 (Flex)]` + `[控制按钮组]`。
- **进度指示**: 顶部边缘 2px `LinearProgressIndicator`，Primary 颜色。
- **交互**: 点击或向上滑动均触发 Hero 动画展开至全屏播放器。
- **背景**: Surface L1。

### 2.4 列表与列表项 (Lists & Items)

- **高度**: 单行 56px，双行 72px，三行 88px。
- **前置组件**: 40×40 (图标) 或 56×56 (缩略图)。
- **分割线**: 1px，`onSurface` 8% 不透明度，起始偏移 16px。
- **分类标题**: 48px 高度，`Label Medium` 样式，`Surface L1` 背景。

### 2.5 对话框 (Dialogs)

- **尺寸**: 宽度 280px ~ 560px。
- **边距**: 全周 24px。
- **结构**: 标题 `headlineSmall`（下方 16px 间距），内容 `bodyLarge`（下方 24px 间距），操作项右对齐（8px 间距）。
- **样式**: `Surface L2` 背景，Large (16px) 圆角。

### 2.6 导航 (Navigation)

- **底部导航栏**: 高度 80px (含标签) / 56px (不含)。
- **指示器**: Primary 12% 不透明度，64×32px 胶囊形状。
- **侧边抽屉**: 宽度 304px，头部高度 160px。

### 2.7 标签与芯片 (Tags/Chips)

- **高度**: 32px，横向内边距 12px。
- **只读**: `Surface L2` 背景，次要文本。
- **交互**: 描边样式，选中时使用 Primary 颜色并显示前置 Checkmark。
- **间距**: 水平 8px，垂直 8px（使用 Wrap 布局）。

### 2.8 状态反馈 (States)

- **空状态 (Empty)**: 居中布局（宽 280px）。图标 64px (Tertiary 颜色) → 16px 间距 → 标题 (Title Medium) → 8px 间距 → 描述 (Body Medium，次要文本) → 24px 间距 → 操作按钮。
- **错误状态 (Error)**:
  - **内联**: 列表/网格内展示图标+信息+重试按钮。
  - **全屏**: 参照空状态布局，使用错误色图标。
  - **Snackbar**: 底部弹出，4s 自动消失，包含"重试"动作按钮。
  - **网络中断**: 顶部持久性横幅 (Banner)，恢复连接后自动消失。

---

## 3. 动画与微交互

### 3.1 动画框架代码

所有动画必须使用以下预定义常量，**禁止在业务代码中硬编码 Duration 或 Curve 值**。

```dart
/// 统一动画配置 - 所有动画必须使用这些预定义常量
class AppAnimations {
  AppAnimations._();

  // === 时间曲线 ===
  /// 元素进入：从无到有，减速停止
  static const Curve enter = Curves.easeOutCubic;
  /// 元素退出：从有到无，加速离开
  static const Curve exit = Curves.easeInCubic;
  /// 状态切换：标准过渡
  static const Curve standard = Curves.easeInOutCubic;
  /// 强调效果：弹性回弹
  static const Curve emphasis = Curves.elasticOut;
  /// 歌词滚动/长列表
  static const Curve smoothScroll = Curves.easeOutQuart;

  // === 时长标准 ===
  /// 微动效：涟漪、颜色变化、透明度
  static const Duration micro = Duration(milliseconds: 100);
  /// 短动效：标签弹出、菜单展开、芯片切换
  static const Duration short = Duration(milliseconds: 200);
  /// 中动效：列表进入、卡片展开、歌词同步
  static const Duration medium = Duration(milliseconds: 300);
  /// 长动效：播放器全屏转换、页面路由
  static const Duration long = Duration(milliseconds: 450);

  // 绝对禁止超过 500ms 的单个动画
}
```

---

### 3.2 微交互代码规范

```dart
class MicroInteractions {
  // 按钮按下反馈
  static const double buttonScaleDown = 0.95;
  static const double buttonOpacityDown = 0.8;
  static const Duration buttonDuration = Duration(milliseconds: 100);

  // 卡片点击反馈
  static const double cardElevationIncrease = 2.0; // 仅亮色模式
  static const Duration cardDuration = Duration(milliseconds: 150);

  // 收藏/点赞切换
  static const double favScaleUp = 1.3;            // 峰值缩放
  static const Duration favDuration = Duration(milliseconds: 300);
  static const Curve favCurve = Curves.elasticOut;

  // 播放/暂停图标变形
  static const Duration morphDuration = Duration(milliseconds: 200);

  // 下拉刷新
  static const double refreshIndicatorSize = 40.0;
  static const double refreshTriggerDistance = 100.0;

  // 进度条滑块 (Thumb)
  static const double thumbExpandedRadius = 8.0;   // 拖拽时
  static const double thumbNormalRadius = 0.0;     // 空闲时（隐藏）
  static const Duration thumbDuration = Duration(milliseconds: 150);
}
```

---

### 3.3 页面级动画规范

各屏幕的动画实现模式如下，**必须严格遵循，不得自行发明过渡效果**：

| 场景 | 动画方案 | 时长 | 曲线 |
| :--- | :--- | :--- | :--- |
| **主网格进入** | Staggered fade-in，最大延迟 250ms，仅首屏前 6 个可见条目 | 300ms | `easeOutCubic` |
| **播放器全屏展开** | Hero（封面）+ SlideTransition（控制区） | 450ms | `easeOutCubic` |
| **标签切换** | Crossfade（**禁止**水平滑动——会增加感知延迟） | 200ms | `easeInOut` |
| **歌词同步高亮** | 当前行 Scale(1.0→1.05) + Opacity(0.5→1.0) | 300ms | `easeOutCubic` |
| **筛选面板展开** | AnimatedSlide + AnimatedOpacity 组合 | 200ms | `easeInOut` |
| **下拉刷新指示器** | 自定义指示器，使用 Primary 颜色 | — | — |
| **骨架屏加载** | 纯色脉冲 Opacity(0.3→0.7→0.3)，1.5s 循环（**禁止**使用 Shimmer 包） | 1500ms loop | `easeInOut` |

---

### 3.4 动画性能规则

1. **优先使用隐式动画**（`AnimatedContainer`、`AnimatedOpacity`）而非显式动画（`AnimationController`）。
2. **高频重绘组件必须包裹 `RepaintBoundary`**（参见 §7.4 详细规范）。
3. **禁止对布局属性添加动画**（`width`、`height`、`margin`）——改用 `Transform` 代替。
4. **尊重用户系统偏好**：检查 `MediaQuery.of(context).disableAnimations`，若为 `true` 则将所有 `Duration` 设为 `Duration.zero`。
5. **限制并发动画数量**：同屏非循环动画最多 3 个。
6. 始终对 `Tween`、`Duration`、`Offset` 使用 `const` 构造函数。
7. 多动画屏幕使用 `TickerProviderStateMixin`（而非 `SingleTickerProviderStateMixin`）。

---

## 4. 无障碍标准 (Accessibility)

- **对比度**: 标准文本最小 4.5:1，大文本 (18pt+) 最小 3:1。
- **点击目标**: 移动端强制最小 **48×48px**。
- **减弱动态效果**: 检查 `MediaQuery.of(context).disableAnimations`，若为 `true` 则所有 Duration 设为 `Duration.zero`。
- **屏幕阅读器**: 所有 `IconButton` 和图像必须提供 `semanticLabel`。
- **聚焦指示**: 2px Primary 颜色外边框，2px 偏移量。

---

## 5. 响应式布局规则

| 断点 (Width) | 布局模式 | 卡片列数 | 间距 |
| :--- | :--- | :--- | :--- |
| **< 800px (Mobile)** | 底部导航 | 2 | 8px |
| **800–1200px (Tablet)** | 底部导航 / 侧边栏 | 3 | 12px |
| **≥ 1200px (Desktop)** | 固定侧边导航 | 4 | 16px |

---

## 6. 组件开发规范

### 6.1 Widget 拆分原则

- 单个 `build()` 方法超过 **80 行**时必须拆分为子 Widget。
- 提取子 Widget 优先考虑独立为 `StatelessWidget`，仅在需要状态时使用 `StatefulWidget`。
- 避免在一个文件中定义超过 3 个公开 Widget。

### 6.2 命名规范

| 类型 | 命名规范 | 示例 |
| :--- | :--- | :--- |
| Screen (页面) | `XxxScreen` | `PlayerScreen` |
| ViewModel | `XxxViewModel` | `PlayerViewModel` |
| Widget (可复用) | `XxxWidget` / `XxxView` | `WorkCardWidget` |
| Service 接口 | `IXxxService` | `IAudioPlayerService` |
| Service 实现 | `XxxService` | `AudioPlayerService` |
| Model (Freezed) | `XxxModel` / `Xxx` | `WorkModel` |

### 6.3 Provider 使用规范

```dart
// ✅ 推荐：精确监听单个字段
final title = context.select<PlayerViewModel, String>((vm) => vm.currentTitle);

// ✅ 推荐：只在需要调用方法时获取实例
final vm = context.read<PlayerViewModel>();
vm.togglePlayPause();

// ❌ 禁止：context.watch 包裹大型 Widget 树
// 这会导致 PlayerViewModel 任意字段变化时整棵树重建
final vm = context.watch<PlayerViewModel>();
```

---

## 7. 性能优化准则

> 本节基于对 Yuro 代码库的性能审计结果，按优先级列出已识别的瓶颈及对应修复方案。

### 7.1 已识别性能瓶颈与修复方案

#### P0 — 高优先级（立即修复）

| 问题 | 文件 | 影响 | 修复方案 |
| :--- | :--- | :--- | :--- |
| `PlayerViewModel` 8 个流订阅，其中 5 个直接调用 `notifyListeners`（`playbackState`、`trackChange`、`playbackProgress`、`errors`、`currentSubtitleStream`），播放中 `playbackProgress` 以 60Hz 频率触发 rebuild | `player_viewmodel.dart:47-129` | 播放中每秒 60+ 次 rebuild | 将 `playbackProgress` 监听拆分为两路：(1) UI 进度流使用 `.throttleTime(Duration(milliseconds: 200))` 更新 `_position` + `notifyListeners`；(2) 字幕同步流保持高精度，直接调用 `_subtitleService.updatePosition` 但不 notify |
| `PlaybackEventHub` 无节流 | `playback_event_hub.dart:19-21` | 每秒 60+ 事件广播 | 对 `playbackProgress` 流增加 `.throttleTime(Duration(milliseconds: 200))`（`.distinct()` 已存在但仅过滤相同 position）。另外需为 `PlaybackStateEvent` 实现 `==` / `hashCode`，否则 `.distinct()` 无效 |
| `SubtitleList.getCurrentSubtitle()` 线性搜索 O(n) | `subtitle.dart:68-80` | 每次位置更新遍历全部字幕 | 改用二分查找 + 缓存 `_currentIndex`，从上次索引附近开始搜索 |

#### P1 — 中优先级（本版本内修复）

| 问题 | 文件 | 影响 | 修复方案 |
| :--- | :--- | :--- | :--- |
| Shimmer 占位符约 5 处使用 | `work_cover_image.dart` 等 | 持续动画帧开销 | 替换为纯色脉冲 `AnimatedOpacity`（0.3→0.7，1.5s 循环） |
| `IntrinsicHeight` 双通道布局 | `work_row.dart:19` | 网格滚动卡顿 | 使用固定 `AspectRatio` 或 `LayoutBuilder` 替代 |
| `DetailViewModel` 连续多次 `notifyListeners` | `detail_viewmodel.dart` | 详情页加载时多次重建 | 合并状态更新，使用单一状态对象批量通知 |
| `WorkGrid.groupWorksIntoRows` 每次 `build` 重算 | `work_layout_strategy.dart:35-42` | 不必要的列表创建 | 缓存计算结果，仅在数据或屏幕宽度变化时重算 |
| `PlayerLyricView` 在 `build` 内调用 `addPostFrameCallback` | `player_lyric_view.dart:103` | 每次 `StreamBuilder` 重建都注册回调 | 移至 `didChangeDependencies` 或在 `StreamBuilder` 的 builder 外处理 |
| `WorkFilesList` 在 `build()` 中重置展开状态 | `work_files_list.dart:20` | 每次重建时所有文件夹收起 | 将 `resetExpandState()` 移至状态变更回调中，而非 `build()` |
| `PlaybackStateEvent` 未实现 `==`/`hashCode` | `playback_event.dart` | `playbackState.distinct()` 过滤无效 | 为事件类实现 `==` 和 `hashCode`（或使用 `Equatable`） |

#### P2 — 低优先级（后续迭代优化）

| 问题 | 文件 | 影响 | 修复方案 |
| :--- | :--- | :--- | :--- |
| `MainScreen` 4 个 `context.watch` 触发全 AppBar 重建 | `main_screen.dart` | 任一 ViewModel 变化触发 AppBar 重建 | 抽取为独立 `Consumer` widget |
| LRC 解析器在主线程执行 | `lrc_parser.dart` | 大文件解析阻塞 UI | 超过 500 行的文件使用 `compute()` 移至 isolate |
| `AudioCacheManager` 同步文件 I/O | `audio_cache_manager.dart:41-73` | 启动时可能造成卡顿 | 改为异步清理逻辑 |

---

### 7.2 状态管理性能规范

```
规则 1: notifyListeners 调用频率
  - UI 相关状态：不超过 30 次/秒（约 33ms 间隔）
  - 播放进度：throttle 到 200ms（5 次/秒足以满足进度条平滑度）
  - 字幕同步：仅在字幕行实际发生变化时通知

规则 2: Provider 粒度
  - 禁止：Consumer<PlayerViewModel> 包裹整个播放器界面
  - 推荐：拆分为 PlayerPositionNotifier / PlayerStateNotifier / SubtitleNotifier
  - 使用 context.select<T, R>() 精确监听单个字段，避免无关字段变化触发重建

规则 3: 避免 build() 内的副作用
  - 禁止在 build() 中调用 addPostFrameCallback
  - 禁止在 build() 中创建 Timer
  - 禁止在 build() 中执行计算密集型操作
  - 推荐：使用 initState / didChangeDependencies 注册回调和订阅
```

---

### 7.3 列表与滚动性能规范

```
规则 1: 强制使用 Builder 模式
  - 必须使用 ListView.builder / GridView.builder / SliverList.builder
  - 禁止在 Column/Row 中用 spread 展开长列表（[...items.map(...)]）
  - work_files_list.dart 中的文件列表必须改用 builder 模式

规则 2: 避免 IntrinsicHeight
  - 原因：触发双通道布局，O(2n) 复杂度，在长列表中影响严重
  - 替代方案：固定高度、AspectRatio、LayoutBuilder
  - 唯一例外：内容高度完全不可预测且列表项总数 < 20

规则 3: 网格计算缓存
  - groupWorksIntoRows 的计算结果必须缓存
  - 仅在 works 列表数据或屏幕宽度发生变化时重新计算
  - 使用 memo pattern（缓存最近一次输入+输出）或 ValueNotifier

规则 4: 图片加载
  - 使用 CachedNetworkImage（已实现，维持现状）
  - 骨架屏使用纯色脉冲替代 Shimmer 包
  - 必须指定 width/height 避免布局抖动（CLS）
  - 考虑使用 memCacheWidth/memCacheHeight 参数降低解码内存占用
```

---

### 7.4 RepaintBoundary 使用规范

**必须包裹的组件**（已确认为重绘热点）：

- `MiniPlayer`——持续的进度条更新。
- `PlayerProgress`（进度滑块）——拖拽时高频更新。
- 歌词列表中的**活跃行**——opacity/scale 动画变化。
- 任何使用 `AnimationController` 的自定义组件。

**禁止滥用**：

- 不要包裹静态组件（每个 `RepaintBoundary` 都有额外内存开销）。
- 不要包裹整个页面（粒度过大，失去意义）。
- **只在使用 Flutter DevTools 的 Repaint Rainbow 工具确认重绘热点后再添加**。

---

### 7.5 内存管理规范

```
规则 1: Stream 订阅生命周期
  - 在 initState 中订阅，在 dispose 中取消
  - 使用 List<StreamSubscription> _subscriptions 统一管理
  - 构造函数/initState 中的订阅必须用 try-catch 包裹

规则 2: Timer 管理
  - dispose 中必须取消所有活跃 Timer
  - 优先使用 RxDart 的 debounceTime/throttleTime 替代手动 Timer
  - 禁止在 build() 中创建 Timer

规则 3: Controller 生命周期
  - ScrollController、AnimationController、TextEditingController
  - 创建于 initState，销毁于 dispose
  - 覆写 dispose 时使用 @mustCallSuper 确保子类调用 super.dispose()

规则 4: 图片缓存策略
  - CachedNetworkImage 默认缓存策略满足绝大多数场景，无需额外配置
  - 设置页面须提供缓存清理入口（已实现，维持现状）
  - 监控缓存目录大小，超过合理阈值时提示用户清理
```

---

### 7.6 性能监控检查清单

在每次发版前，必须在 **Profile 模式**下完成以下检查：

```markdown
## 发版前性能检查清单

### 帧率 (使用 flutter run --profile)
- [ ] 主列表滚动帧率 ≥ 55fps
- [ ] 播放器页面所有动画帧率 ≥ 55fps
- [ ] 页面切换动画无明显丢帧（DevTools Timeline 无红帧）

### 内存 (使用 Flutter DevTools Memory 面板)
- [ ] 冷启动内存占用 < 150MB
- [ ] 持续播放 30 分钟后无内存泄漏趋势（堆快照无明显增长）
- [ ] 连续切换页面 50 次后内存使用稳定

### 启动性能
- [ ] 冷启动到首帧渲染 < 2s（Release 模式）
- [ ] 切换底部导航标签到内容显示 < 300ms

### 网络与缓存
- [ ] 图片二次访问无重复网络请求（验证 CachedNetworkImage 正常工作）
- [ ] API 请求超时时间 ≤ 10s
- [ ] 失败请求有重试机制并给予用户明确反馈
```

---

## 8. 开发工作流规范

### 8.1 代码生成

修改任何 `lib/data/models/` 下的 Freezed 模型文件后，**必须立即运行**：

```bash
dart run build_runner build --delete-conflicting-outputs
```

生成的 `*.g.dart` 和 `*.freezed.dart` 文件需要一并提交。**禁止手动编辑这些生成文件**。

### 8.2 提交前检查

```bash
# 1. 静态分析（无 errors/warnings 才可提交）
flutter analyze

# 2. 单元测试（全部通过才可提交）
flutter test

# 3. 格式化（保持代码风格一致）
dart format lib/
```

### 8.3 性能分析工具

```bash
# Profile 模式运行（用于性能分析，勿使用 debug 模式测帧率）
flutter run --profile

# Release 模式构建（用于最终性能验收）
flutter build apk --release
```

**Flutter DevTools 常用功能**（通过 `flutter pub global activate devtools` 或 IDE 插件打开）：

| 工具 | 用途 |
| :--- | :--- |
| **Performance → Timeline** | 检测丢帧，定位耗时 build/paint/layout |
| **Performance → Repaint Rainbow** | 可视化重绘区域，定位 `RepaintBoundary` 放置位置 |
| **Memory → Heap Snapshot** | 检测内存泄漏，分析对象保留链 |
| **Widget Inspector → Rebuild Stats** | 统计各 Widget 的 rebuild 次数，找出高频重建热点 |

### 8.4 分支与 CI/CD

- 功能分支命名：`feat/xxx`，修复分支：`fix/xxx`。
- CI 在 `v*` tag 触发，自动构建 Android APK/AAB（签名）+ iOS IPA 并创建 GitHub Release。
- **不要在 debug 模式下测量性能指标**——debug 模式禁用了大量优化，数据不具参考价值。
