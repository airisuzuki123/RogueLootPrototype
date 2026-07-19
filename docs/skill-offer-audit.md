# 阶段 5 出货规则抽样报告

本报告由 `tools/skill_offer_audit.gd` 生成，用于体检当前升级三选一和关间商店技能权重。

## 权重公式

- 基础权重来自技能稀有度。
- 已拥有同技能：每层 x1.24，上限 x1.85。
- 直接协同来源：每层 x1.18，上限 x1.70。
- 标签读取命中：每个命中标签 x1.18，上限 x1.75。
- 已成型路线：每路线层 x1.06，上限 x1.40。
- 首次核心引擎且命中读取条件：x1.18。
- 已拥有核心引擎：基础权重至少按 8 计算，再进入重复和协同权重。
- 冲突标签命中：每个冲突标签 x0.70。

## 结论摘要

- 无构筑开局：升级前五为 急速施放(58)、清弹屏障(58)、强击弹体(58)、折光护盾(58)、轻装骨架(58)；路线权重为 bulk 182 / agile 218 / pierce 128 / blast 54 / chain 52 / close 160；主路线 无 / 分支 无；主动标签 。
- 体积迟缓：升级前五为 体积共鸣(87)、巨体回响(83)、迟缓共鸣(77)、锚定释放(63)、清弹屏障(58)；路线权重为 bulk 418 / agile 155 / pierce 106 / blast 81 / chain 43 / close 227；主路线 bulk / 分支 blast；主动标签 large_body, slow_move, multi_projectile, heavy_hit, slow_attack, blast, shielded, high_health。
- 轻装疾行：升级前五为 轻装骨架(120)、轻锋协议(115)、游走聚焦(94)、疾行缓存(92)、疾行共鸣(83)；路线权重为 bulk 130 / agile 606 / pierce 208 / blast 42 / chain 60 / close 151；主路线 agile / 分支 chain；主动标签 small_body, fast_move, moving, fast_attack。
- 爆裂重弹：升级前五为 裂片爆破(101)、锚定释放(71)、体积共鸣(67)、静立聚焦(60)、清弹屏障(58)；路线权重为 bulk 395 / agile 155 / pierce 98 / blast 189 / chain 43 / close 202；主路线 blast / 分支 bulk；主动标签 blast, large_body, slow_attack, heavy_hit, heavy_blast, slow_move, high_health。
- 连锁追踪：升级前五为 急速施放(58)、清弹屏障(58)、折光护盾(58)、迅捷步伐(58)、穿透弹芯(58)；路线权重为 bulk 153 / agile 252 / pierce 133 / blast 46 / chain 121 / close 160；主路线 chain / 分支 pierce；主动标签 chain_skill, slow_move, fast_move, fast_attack, pierce, moving。
- 近身护盾：升级前五为 巨体回响(118)、护身锋刃(101)、破阵反应(86)、急速施放(58)、清弹屏障(58)；路线权重为 bulk 287 / agile 183 / pierce 120 / blast 56 / chain 52 / close 406；主路线 close / 分支 bulk；主动标签 close_skill, shielded, bulk_close, large_body, high_health。
- 血潮低血：升级前五为 背水矩阵(97)、生命强化(72)、急速施放(58)、清弹屏障(58)、强击弹体(58)；路线权重为 bulk 198 / agile 183 / pierce 119 / blast 54 / chain 52 / close 292；主路线 close / 分支 bulk；主动标签 low_life, blood_risk, slow_move, high_health。

## 场景明细

### 无构筑开局

- 主动标签：``
- 路线分数：bulk 0 / agile 0 / pierce 0 / blast 0 / chain 0 / close 0
- 路线选择：主路线 无 / 分支 无

升级权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 急速施放 | 58 | green | utility |  |  |
| 清弹屏障 | 58 | green | survival |  |  |
| 强击弹体 | 58 | green | projectile |  |  |
| 折光护盾 | 58 | green | survival |  |  |
| 轻装骨架 | 58 | green | agile |  |  |
| 生命强化 | 58 | green |  |  |  |
| 迅捷步伐 | 58 | green | mobility |  |  |
| 穿透弹芯 | 58 | green | pierce |  |  |
| 复苏训练 | 58 | green |  |  |  |
| 锚定释放 | 30 | blue | bulk |  |  |

商店权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 急速施放 | 52 | green | utility |  |  |
| 清弹屏障 | 52 | green | survival |  |  |
| 强击弹体 | 52 | green | projectile |  |  |
| 折光护盾 | 52 | green | survival |  |  |
| 轻装骨架 | 52 | green | agile |  |  |
| 生命强化 | 52 | green |  |  |  |
| 迅捷步伐 | 52 | green | mobility |  |  |
| 穿透弹芯 | 52 | green | pierce |  |  |
| 复苏训练 | 52 | green |  |  |  |
| 锚定释放 | 32 | blue | bulk |  |  |

### 体积迟缓

- 主动标签：`large_body`, `slow_move`, `multi_projectile`, `heavy_hit`, `slow_attack`, `blast`, `shielded`, `high_health`
- 路线分数：bulk 5 / agile 0 / pierce 0 / blast 1 / chain 0 / close 0
- 路线选择：主路线 bulk / 分支 blast

升级权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 体积共鸣 | 87 | blue | bulk | large_body |  |
| 巨体回响 | 83 | blue | bulk, close | shielded |  |
| 迟缓共鸣 | 77 | blue | bulk | slow_move |  |
| 锚定释放 | 63 | blue | bulk | slow_attack |  |
| 清弹屏障 | 58 | green | survival |  |  |
| 强击弹体 | 58 | green | projectile |  |  |
| 折光护盾 | 58 | green | survival |  |  |
| 生命强化 | 58 | green |  |  |  |
| 迅捷步伐 | 58 | green | mobility |  |  |
| 复苏训练 | 58 | green |  |  |  |

商店权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 体积共鸣 | 95 | blue | bulk | large_body |  |
| 巨体回响 | 89 | blue | bulk, close | shielded |  |
| 迟缓共鸣 | 83 | blue | bulk | slow_move |  |
| 锚定释放 | 69 | blue | bulk | slow_attack |  |
| 静立聚焦 | 58 | blue | bulk | slow_attack |  |
| 清弹屏障 | 52 | green | survival |  |  |
| 强击弹体 | 52 | green | projectile |  |  |
| 折光护盾 | 52 | green | survival |  |  |
| 生命强化 | 52 | green |  |  |  |
| 迅捷步伐 | 52 | green | mobility |  |  |

### 轻装疾行

- 主动标签：`small_body`, `fast_move`, `moving`, `fast_attack`
- 路线分数：bulk 0 / agile 7 / pierce 0 / blast 0 / chain 0 / close 0
- 路线选择：主路线 agile / 分支 chain

升级权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 轻装骨架 | 120 | green | agile |  |  |
| 轻锋协议 | 115 | blue | agile, pierce | small_body, fast_move |  |
| 游走聚焦 | 94 | blue | agile | fast_move |  |
| 疾行缓存 | 92 | blue | agile | moving, fast_move |  |
| 疾行共鸣 | 83 | blue | agile | fast_move |  |
| 轻盈共鸣 | 83 | blue | agile | small_body |  |
| 急速施放 | 58 | green | utility |  |  |
| 清弹屏障 | 58 | green | survival |  |  |
| 折光护盾 | 58 | green | survival |  |  |
| 穿透弹芯 | 58 | green | pierce |  |  |

商店权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 轻锋协议 | 121 | blue | agile, pierce | small_body, fast_move |  |
| 轻装骨架 | 108 | green | agile |  |  |
| 游走聚焦 | 102 | blue | agile | fast_move |  |
| 疾行缓存 | 99 | blue | agile | moving, fast_move |  |
| 疾行共鸣 | 89 | blue | agile | fast_move |  |
| 轻盈共鸣 | 89 | blue | agile | small_body |  |
| 急速施放 | 52 | green | utility |  |  |
| 清弹屏障 | 52 | green | survival |  |  |
| 折光护盾 | 52 | green | survival |  |  |
| 穿透弹芯 | 52 | green | pierce |  |  |

### 爆裂重弹

- 主动标签：`blast`, `large_body`, `slow_attack`, `heavy_hit`, `heavy_blast`, `slow_move`, `high_health`
- 路线分数：bulk 4 / agile 0 / pierce 0 / blast 6 / chain 0 / close 0
- 路线选择：主路线 blast / 分支 bulk

升级权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 裂片爆破 | 101 | blue | blast | blast |  |
| 锚定释放 | 71 | blue | bulk | slow_attack |  |
| 体积共鸣 | 67 | blue | bulk | large_body |  |
| 静立聚焦 | 60 | blue | bulk | slow_attack |  |
| 清弹屏障 | 58 | green | survival |  |  |
| 强击弹体 | 58 | green | projectile |  |  |
| 折光护盾 | 58 | green | survival |  |  |
| 生命强化 | 58 | green |  |  |  |
| 迅捷步伐 | 58 | green | mobility |  |  |
| 复苏训练 | 58 | green |  |  |  |

商店权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 裂片爆破 | 109 | blue | blast | blast |  |
| 锚定释放 | 76 | blue | bulk | slow_attack |  |
| 体积共鸣 | 72 | blue | bulk | large_body |  |
| 静立聚焦 | 64 | blue | bulk | slow_attack |  |
| 巨体回响 | 61 | blue | bulk, close |  |  |
| 清弹屏障 | 52 | green | survival |  |  |
| 强击弹体 | 52 | green | projectile |  |  |
| 折光护盾 | 52 | green | survival |  |  |
| 生命强化 | 52 | green |  |  |  |
| 迅捷步伐 | 52 | green | mobility |  |  |

### 连锁追踪

- 主动标签：`chain_skill`, `slow_move`, `fast_move`, `fast_attack`, `pierce`, `moving`
- 路线分数：bulk 0 / agile 2 / pierce 0 / blast 0 / chain 5 / close 0
- 路线选择：主路线 chain / 分支 pierce

升级权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 急速施放 | 58 | green | utility |  |  |
| 清弹屏障 | 58 | green | survival |  |  |
| 折光护盾 | 58 | green | survival |  |  |
| 迅捷步伐 | 58 | green | mobility |  |  |
| 穿透弹芯 | 58 | green | pierce |  |  |
| 疾行缓存 | 54 | blue | agile | moving, fast_move |  |
| 轻装骨架 | 45 | green | agile |  | slow_move |
| 强击弹体 | 41 | green | projectile |  | fast_attack |
| 生命强化 | 41 | green |  |  | fast_move |
| 复苏训练 | 41 | green |  |  | fast_move |

商店权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 疾行缓存 | 58 | blue | agile | moving, fast_move |  |
| 急速施放 | 52 | green | utility |  |  |
| 清弹屏障 | 52 | green | survival |  |  |
| 折光护盾 | 52 | green | survival |  |  |
| 迅捷步伐 | 52 | green | mobility |  |  |
| 穿透弹芯 | 52 | green | pierce |  |  |
| 碎片回流 | 52 | purple | chain | moving, chain_skill, fast_attack |  |
| 游走聚焦 | 42 | blue | agile | fast_move |  |
| 轻装骨架 | 41 | green | agile |  | slow_move |
| 速射共鸣 | 41 | purple | chain | fast_attack |  |

### 近身护盾

- 主动标签：`close_skill`, `shielded`, `bulk_close`, `large_body`, `high_health`
- 路线分数：bulk 1 / agile 0 / pierce 0 / blast 0 / chain 0 / close 5
- 路线选择：主路线 close / 分支 bulk

升级权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 巨体回响 | 118 | blue | bulk, close | shielded, close_skill |  |
| 护身锋刃 | 101 | blue | close | close_skill, large_body |  |
| 破阵反应 | 86 | blue | close | shielded, close_skill |  |
| 急速施放 | 58 | green | utility |  |  |
| 清弹屏障 | 58 | green | survival |  |  |
| 强击弹体 | 58 | green | projectile |  |  |
| 折光护盾 | 58 | green | survival |  |  |
| 生命强化 | 58 | green |  |  |  |
| 迅捷步伐 | 58 | green | mobility |  |  |
| 穿透弹芯 | 58 | green | pierce |  |  |

商店权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 巨体回响 | 127 | blue | bulk, close | shielded, close_skill |  |
| 护身锋刃 | 110 | blue | close | close_skill, large_body |  |
| 破阵反应 | 92 | blue | close | shielded, close_skill |  |
| 急速施放 | 52 | green | utility |  |  |
| 清弹屏障 | 52 | green | survival |  |  |
| 强击弹体 | 52 | green | projectile |  |  |
| 折光护盾 | 52 | green | survival |  |  |
| 生命强化 | 52 | green |  |  |  |
| 迅捷步伐 | 52 | green | mobility |  |  |
| 穿透弹芯 | 52 | green | pierce |  |  |

### 血潮低血

- 主动标签：`low_life`, `blood_risk`, `slow_move`, `high_health`
- 路线分数：bulk 0 / agile 0 / pierce 0 / blast 0 / chain 0 / close 3
- 路线选择：主路线 close / 分支 bulk

升级权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 背水矩阵 | 97 | blue | close | low_life, blood_risk |  |
| 生命强化 | 72 | green |  |  |  |
| 急速施放 | 58 | green | utility |  |  |
| 清弹屏障 | 58 | green | survival |  |  |
| 强击弹体 | 58 | green | projectile |  |  |
| 折光护盾 | 58 | green | survival |  |  |
| 迅捷步伐 | 58 | green | mobility |  |  |
| 穿透弹芯 | 58 | green | pierce |  |  |
| 复苏训练 | 58 | green |  |  |  |
| 轻装骨架 | 41 | green | agile |  | slow_move |

商店权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 背水矩阵 | 102 | blue | close | low_life, blood_risk |  |
| 生命强化 | 64 | green |  |  |  |
| 急速施放 | 52 | green | utility |  |  |
| 清弹屏障 | 52 | green | survival |  |  |
| 强击弹体 | 52 | green | projectile |  |  |
| 折光护盾 | 52 | green | survival |  |  |
| 迅捷步伐 | 52 | green | mobility |  |  |
| 穿透弹芯 | 52 | green | pierce |  |  |
| 复苏训练 | 52 | green |  |  |  |
| 血怒汲取 | 45 | purple | close | low_life, high_health, blood_risk |  |
