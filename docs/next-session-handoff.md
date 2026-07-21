# 下一会话交接文本

本交接用于继续 `D:\CODEX\RogueLootPrototype` 的下一步开发。当前分支为 `main`；默认先做本地提交，只有用户明确要求演示版或版本推送时才推送远端。提交信息继续使用简体中文。

## 当前项目状态

- 阶段 5：局内体验深度优化已完成并归档。
- 阶段 5.5：初始职业制作版本已完成并归档。
- 下一阶段：阶段 6，局外成长与资源消耗，尚未开始。
- 当前主循环为 10 个约 30 秒战斗关，关后自动清场并进入关间商店。
- 装备提供基础属性，技能承担百分比放大、触发效果和构筑联动，职业负责开局导向与属性获取差异。
- 技能池体量偏小的问题继续留到阶段 7 内容池扩充，不作为阶段 6 起步任务。

## 开始前必读

- `AGENTS.md`
- `README.md`
- `docs/stage-plan.md`
- `docs/design.md`
- `docs/development-log.md`
- `docs/next-session-handoff.md`

开始工作前运行：

- `git status --short --branch`
- `git log -5 --oneline`

## 阶段 5.5 完成内容

- 集中职业目录和选择流程已接入，开局职业为巨躯炮台、沉稳射手、贴身刃卫、游走电弧和重弹爆破。
- 职业提供初始属性、属性获取倍率、少量已有技能通道乘区和轻量出货偏向，不锁死后续构筑。
- 选择职业后立即生成一次职业偏向的开局三选一；仅该次选择统一提高真实清群技能权重，不设置职业专属固定保底。
- 第一关确定性目标金币为 25；五个职业都能在第一商店购买至少一张职业偏向技能。
- 升级、商店、装备详情、装备对比和 HUD 构筑摘要均显示职业倍率换算后的实际收益。
- 近身刀环与脉冲场已增加清晰的攻击轨迹、实际范围边界、扩张过程和敌人命中反馈。

## 最终验收结果

- 职业效果审计：通过，报告为 `docs/class-effect-audit.md`。
- 职业初始出货审计：通过，报告为 `docs/class-offer-audit.md`。
- 职业连续选择审计：五职业风险分支均为 0/3，报告为 `docs/class-progression-audit.md`。
- 开局清群概率下限：贴身刃卫 58%，其余职业 88%-92%。
- 第一商店最低偏向技能最高价格：22 金，低于 25 金确定性预算。
- 五职业代表性构筑和主界面选择流程运行测试：5/5 通过。
- Godot 4.6.1 主场景 headless 启动验证通过。

## 阶段 6 边界

- 先定义一种局外资源的来源、结算保留、消耗与存档结构，再制作 UI。
- 第一版只做最小局外循环：单局结算资源、局外入口、少量永久强化和基础存档。
- 不在起步阶段同时加入职业等级、复杂天赋树、宠物、融合、资质或长期收集系统。
- 永久强化不能替代局内职业、装备和技能选择，应控制为可解释的小幅基础成长。
- 玩家可见文本继续使用简体中文；内部路线、标签和权重规则不得显示在 HUD、商店或升级按钮中。

详细方案：`docs/stage6-implementation-plan.md`。

## 阶段 6 已确定方案

- 局外资源名称为“试炼印记”，内部字段为 `meta_currency`，与每局清零的金币完全分离。
- 第一版结算为“完成关卡数 + 通关奖励 5”；完整十关获得 15 枚，未完成任何关卡获得 0 枚。
- 第一批强化只有四项：最大生命、基础伤害、移速和暴击率，每项 5 级。
- 每级价格统一为 3 / 5 / 8 / 12 / 17，永久强化不受职业属性获取倍率二次放大。
- 存档使用 `user://meta_progression.cfg` 和 Godot `ConfigFile`，只保存局外资源、统计和强化等级。
- 局内金币、装备、背包、技能、职业和当前关卡均不跨局保存。
- 新增独立 `MetaProgression` Autoload；`GameManager.reset_run()` 不能清除局外状态。
- 新增独立备战面板，不把永久强化购买控件继续堆进战斗 HUD。

## 关键文件

- `scripts/items/character_class_catalog.gd`：职业数据、初始属性、获取倍率、乘区和出货偏向。
- `scripts/items/skill_catalog.gd`：技能数据、数值和出货规则。
- `scripts/core/game_manager.gd`：单局流程、职业选择、升级和商店。
- `scripts/entities/player.gd`：职业实际生效、属性和战斗技能。
- `scripts/ui/hud.gd`：职业选择、构筑摘要、升级、商店和结算界面。
- `docs/stage6-implementation-plan.md`：阶段 6 的资源公式、首批强化、代码边界、开发顺序和验收标准。
- `docs/stage-plan.md`：标准阶段计划和阶段边界。

## 验证命令

涉及 Godot 脚本、场景、preload path 或 Autoload 改动后运行：

```powershell
& "C:\Godot_v4.6.1-stable_mono_win64\Godot_v4.6.1-stable_mono_win64_console.exe" --headless --path "D:\CODEX\RogueLootPrototype" --quit-after 5
```

职业回归测试场景：

```powershell
& "C:\Godot_v4.6.1-stable_mono_win64\Godot_v4.6.1-stable_mono_win64_console.exe" --headless --path "D:\CODEX\RogueLootPrototype" --scene "res://tools/class_runtime_smoke_test.tscn"
```

如果受限环境中出现已知 `signal 11`，需要在受限环境外重跑同一条命令。

## 建议第一步

严格从 `docs/stage6-implementation-plan.md` 的第一步开始：新增 `scripts/progression/meta_upgrade_catalog.gd` 和 `scripts/progression/meta_progression.gd`，先完成默认档、读取、校验、保存、消费和独立测试存档；这一步不要制作 UI，也不要修改职业和技能数值。
