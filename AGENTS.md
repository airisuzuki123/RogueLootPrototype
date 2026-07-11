# Repository Guidelines

## 项目结构与模块组织

本项目是 Godot 4 + GDScript 的 2D 肉鸽刷宝原型。

- `scenes/` 存放 Godot 场景。
- `scripts/core/` 存放全局流程和管理器。
- `scripts/entities/` 存放玩家、敌人、投射物等实体。
- `scripts/items/` 存放掉落物、装备、道具。
- `docs/` 存放设计文档和学习记录。

新增功能优先按玩法模块组织，避免把战斗、UI、掉落逻辑混在一个脚本中。

## 构建、测试与开发命令

当前项目使用 Godot 编辑器运行。

- 打开项目：用 Godot 4.x 打开 `project.godot`。
- 运行游戏：在 Godot 中运行主场景 `scenes/main.tscn`。
- 导出构建：配置 Godot Export Presets 后再导出到 `builds/`。

项目暂未配置自动化测试。后续可引入 GUT 等 Godot 测试框架。

## 编码风格与命名规范

- GDScript 使用 1 个 Tab 缩进，遵循 Godot 默认格式。
- 文件名使用小写蛇形命名，例如 `game_manager.gd`。
- 场景名使用小写蛇形命名，例如 `loot_drop.tscn`。
- 类和节点名称使用清晰的 PascalCase，例如 `GameManager`、`Player`。
- 单个脚本只负责一个主要职责。

## 测试规范

新增玩法时至少手动验证：

- 主场景可以正常启动。
- 玩家移动、敌人生成、击杀和掉落没有报错。
- 新增数值不会导致明显失衡或死循环。

后续如果加入自动化测试，测试文件放在 `tests/`，并与脚本模块对应。

## 提交与 Pull Request 规范

当前是个人原型项目，提交应保持小而清晰。

- 提交信息使用动词开头，例如 `Add enemy spawner`。
- 每次提交只包含一个明确改动。
- 涉及玩法数值时，在说明中记录改动前后的差异。
- 涉及视觉效果时，附截图或短视频更便于回看。

## Agent 使用说明

自动化代理修改项目时，应优先保持 Godot 项目可打开、主场景可运行。新增资源路径时同步检查 `preload()`、场景引用和 Autoload 配置。

