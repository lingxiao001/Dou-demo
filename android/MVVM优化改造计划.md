toolName: file_search
            
status: success
          
file_pattern: lib/main.dart
          

        
            
toolName: view_files
            
status: success
          
            
filePath: d:\douyin_demo\lib\main.dart
          

        
            
toolName: view_files
            
status: success
          
            
filePath: d:\douyin_demo\lib\features\feed\views\feed_screen.dart
          

        
            
toolName: view_files
            
status: success
          
            
filePath: d:\douyin_demo\lib\features\ai\widgets\ai_fab.dart
          

        
            
toolName: todo_write
            
status: success
          
Todos updated: 1 items
          
**目标与范围**
- 将现有项目落地为“MVVM + Repository”分层，统一用例驱动的状态流与依赖注入，保留现有 UI 交互与体验。
- 首期覆盖 Feed 外流、Viewer 内流、评论面板、个人主页、AI 聊天与视频页内 AI 问答。
- 增量迁移，保证每一步可运行、可回滚。

**现状评估**
- 业务逻辑在 View 内部执行，以 `StatefulWidget + setState` 为主：
  - 视频页直接管理播放/点赞/静音/评论数与 AI 状态：`d:\douyin_demo\lib\features\viewer\widgets\tiktok_video_page.dart:98-154, 156-217`
  - 评论面板直接调用仓库：`d:\douyin_demo\lib\features\viewer\widgets\comment_sheet.dart:18-25`
  - 外流与内流直接从仓库取数据：`d:\douyin_demo\lib\features\feed\views\feed_grid_screen.dart:21-22`、`d:\douyin_demo\lib\features\viewer\views\viewer_screen.dart:29-32`
  - 个人主页直接调用偏好服务：`d:\douyin_demo\lib\features\profile\views\profile_screen.dart:17-36`
- 已有 Repository/Service：`VideoRepository`、`UserPrefsService`、`LLMapi`、`AiChatService` 等。
- 技术文档规划为“MVVM + Repository + Riverpod”，但尚未实现依赖与 ViewModel（`d:\douyin_demo\技术设计文档.md:18, 28-38`）。
- `pubspec.yaml` 未引入 `flutter_riverpod`（`d:\douyin_demo\pubspec.yaml`）。

**架构决策**
- 状态管理：`flutter_riverpod`（或 `hooks_riverpod`，可选）。
- ViewModel形态：按页面/组件粒度划分；使用 `StateNotifier`/`Notifier` 暴露可观察状态与纯方法。
- Repository 保持不变；通过 Provider 注入到各 ViewModel。
- 视频播放器控制器的归属：为避免生命周期与资源释放复杂化，控制器仍在 View 层；播放意图与业务状态由 ViewModel 管理，View 根据 ViewModel 的意图/状态去调用 `VideoPlayerController`。

**目录与命名规范**
- 新增分层目录（按 features 分包）：
  - `features/*/viewmodels/`：每个页面/组件一个 ViewModel 文件或按领域拆分。
  - `common/providers/`：通用 Provider（仓库、服务、播放器服务等）。
- 命名规则：`XxxViewModel`、`xxxProvider`；Provider 使用 `family` 传入 `id` 等参数。

**改造路径（增量分阶段）**
- 阶段 A：基础设施与依赖注入
  - 添加依赖并包裹根节点
    - `pubspec.yaml` 添加 `flutter_riverpod`
    - 在 `d:\douyin_demo\lib\main.dart` 用 `ProviderScope` 包裹 `MyApp`
  - 定义通用 Provider
    - `videoRepositoryProvider`、`userPrefsServiceProvider`、`llmApiProvider`、`aiChatServiceProvider`
- 阶段 B：Feed 外流（列表页面）
  - 建立 `FeedGridViewModel`：负责加载视频列表、刷新、错误态
  - 将 `d:\douyin_demo\lib\features\feed\views\feed_grid_screen.dart` 的 `FutureBuilder` 改为订阅 `posts` 状态并触发 `load()`
- 阶段 C：Viewer 内流（上下滑页面）
  - 建立 `ViewerViewModel`：管理当前索引、预取视频资源（封装对 `VideoAssetCacheService` 的调用）
  - 替换 `d:\douyin_demo\lib\features\viewer\views\viewer_screen.dart` 的本地索引与 `Future<List>` 为 Provider 驱动
- 阶段 D：视频页（核心交互与 AI）
  - 建立 `TikTokVideoViewModel`：管理 `liked`、`commentCount`、`muted`、`pausedByUser`、AI 相关状态与方法（如 `onAiTap()`、`sendAi()`、`closeAi()`）
  - View 侧保留 `VideoPlayerController`，将播放意图与 UI状态对齐：
    - 例如点击手势触发 `vm.togglePlayIntent()`，View 根据 VM 意图调用 `_controller.play()/pause()` 并回写播放状态
    - 当前你关注的逻辑在 View 内部：“记录 AI 弹窗前是否播放”：`d:\douyin_demo\lib\features\viewer\widgets\tiktok_video_page.dart:158`；迁移到 VM 的 `wasPlayingBeforeAi` 字段与 `onAiTap()` 方法
- 阶段 E：评论面板
  - 建立 `CommentSheetViewModel`：管理 `isLoading`、`comments` 列表、`submit()`
  - `CommentSheet` 订阅列表并渲染；输入框仍由 View 管理，提交时调用 VM 方法
- 阶段 F：个人主页
  - 建立 `ProfileViewModel`：加载昵称/头像、保存操作；View 订阅状态展示，点击操作调用 VM
- 阶段 G：AI 聊天（悬浮球）
  - 建立 `AiChatViewModel`：管理消息队列与发送状态；替换 `AiChatSheet` 内部本地状态
- 阶段 H：统一测试与验收
  - 跑分析、格式与构建；对关键交互做冒烟测试
  - 验证每一步迁移后功能一致

**具体改动清单（任务到文件级）**
- 依赖与入口
  - `pubspec.yaml`：添加 `flutter_riverpod:^…`
  - `lib/main.dart`：`runApp(ProviderScope(child: MyApp()))`
- Provider 定义（新建文件）
  - `lib/common/providers/app_providers.dart`：仓库与服务 Provider
- ViewModel（按模块新增文件）
  - `lib/features/feed/viewmodels/feed_grid_view_model.dart`：列表加载与刷新
  - `lib/features/viewer/viewmodels/viewer_view_model.dart`：当前索引与资源预取
  - `lib/features/viewer/viewmodels/tiktok_video_view_model.dart`：点赞、评论数、静音、AI 状态与意图
  - `lib/features/viewer/viewmodels/comment_sheet_view_model.dart`：评论列表与提交
  - `lib/features/profile/viewmodels/profile_view_model.dart`：昵称/头像加载与保存
  - `lib/features/ai/viewmodels/ai_chat_view_model.dart`：消息与发送状态
- 视图改造（现有文件）
  - `feed_grid_screen.dart`：用 `ConsumerWidget`/`Consumer` 替换 `StatefulWidget + FutureBuilder`
  - `viewer_screen.dart`：索引改为订阅 VM；`PageView.onPageChanged` 调用 VM 的 `onPageChanged(index)`
  - `tiktok_video_page.dart`：
    - 移除 `_liked/_commentCount/_muted/_showAi/_aiLoading/_aiReply/_aiImageBytes/_aiDataUrl/_wasPlayingBeforeAi/_pausedByUser` 本地状态
    - 使用 `ref.watch(tikTokVideoViewModelProvider(post.id))` 读状态；手势触发 VM 方法
    - 播放器控制器仍在 View；根据 VM 的 `isPlayingIntent` 调用 `_controller.play/pause()` 并回写 `vm.onPlayerStateChanged(isPlaying)`
  - `comment_sheet.dart`：移除本地列表与加载态，改为订阅 VM；`_submit()` 触发 VM
  - `profile_screen.dart`：改为订阅 VM；编辑/选择头像后调用 VM

**关键模型与状态划分**
- TikTokVideoViewModel（示例字段）
  - `liked`、`commentCount`、`muted`、`pausedByUser`
  - `showAi`、`aiLoading`、`aiReply`、`aiImageBytes`、`aiDataUrl`、`wasPlayingBeforeAi`
  - 方法：`toggleLike()`、`toggleMute()`、`togglePlayIntent()`、`onAiTap()`、`sendAi(prompt)`、`closeAi()`、`onPlayerStateChanged(isPlaying)`
- ViewerViewModel
  - `currentIndex`、`posts`、`isLoading`
  - 方法：`load()`、`onPageChanged(i)`、`prefetchAround(i)`
- FeedGridViewModel
  - `posts`、`isLoading`、`error`；方法：`load()`、`refresh()`
- CommentSheetViewModel
  - `comments`、`isLoading`；方法：`load(postId)`、`submit(content)`
- ProfileViewModel
  - `nickname`、`avatarPath`；方法：`load()`、`saveNickname()`、`saveAvatarFile()`

**播放器控制策略**
- 控制器仍在 View，避免 ViewModel 持有平台资源导致泄漏与复杂生命周期。
- ViewModel 只管理“播放意图与标志”（例如 `pausedByUser` 和“AI弹窗前是否在播放”），View 在手势或弹框事件中：
  - 写入 VM 的意图
  - 调用控制器执行真实播放/暂停
  - 将结果通过 `onPlayerStateChanged` 回写给 VM，使 UI 状态一致
- 参考当前逻辑：`_wasPlayingBeforeAi = _controller.value.isPlaying`（`d:\douyin_demo\lib\features\viewer\widgets\tiktok_video_page.dart:158`），迁移到 VM 字段与方法。

**示例代码片段（简化示意）**
- 添加 ProviderScope
  - 在 `lib/main.dart`：
    - `void main() { runApp(ProviderScope(child: const MyApp())); }`
- 定义仓库 Provider
  - `final videoRepositoryProvider = Provider((ref) => VideoRepository());`
- 定义页面 ViewModel Provider（family）
  - `final tikTokVideoViewModelProvider = StateNotifierProvider.family<TikTokVideoViewModel, TikTokVideoState, String>((ref, id) { ... });`
- 视图订阅
  - `final state = ref.watch(tikTokVideoViewModelProvider(post.id));`
  - `onTap: () => ref.read(tikTokVideoViewModelProvider(post.id).notifier).togglePlayIntent();`

以上片段为计划说明用途，落地时按项目代码风格与分层细化。

**风险与应对**
- 控制器生命周期复杂：保持在 View 层，减少资源泄漏风险。
- 增量迁移期间的状态不一致：采用“意图 → 控制器动作 → 回写状态”的三段式。
- 依赖引入后编译问题：每阶段完成后执行 `flutter analyze` 与构建验证。

**验收标准**
- 所有页面的业务状态不再依赖本地 `setState` 管理，均由 ViewModel 暴露。
- View 与 Repository、Service 不直接耦合，调用路径经 ViewModel。
- 播放器在 View 控制，状态在 VM 管理，交互一致无回归。
- 评论与 AI 功能在迁移后行为与视觉无变化。
- 代码通过静态分析与构建；交互冒烟测试正常。

**排期建议（两到三周）**
- 第 1 周：引入 Riverpod、搭建 Provider/VM 基础；完成 Feed/Viewer 的数据与索引管理。
- 第 2 周：完成 TikTok 视频页交互迁移（点赞/静音/播放意图）、评论面板 VM 化；打通 AI 查询状态流。
- 第 3 周：个人主页 VM 化、AI 聊天迁移；统一回归与性能核查。

如果你希望，我可以在此计划基础上，直接创建 Provider 与部分 ViewModel 的骨架代码，并完成首个页面（Feed 外流）的迁移与验证。

已完成的任务
- 撰写MVVM架构改造计划书