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

- 无构筑开局：升级前五为 急速施放(48)、清弹屏障(48)、强击弹体(48)、折光护盾(48)、轻装骨架(48)；路线权重为 bulk 228 / agile 236 / pierce 134 / blast 78 / chain 94 / close 208；主路线 无 / 分支 无；主动标签 。
- 体积迟缓：升级前五为 体积共鸣(100)、巨体回响(94)、迟缓共鸣(87)、锚定释放(72)、静立聚焦(61)；路线权重为 bulk 512 / agile 175 / pierce 120 / blast 119 / chain 79 / close 286；主路线 bulk / 分支 blast；主动标签 large_body, slow_move, multi_projectile, heavy_hit, slow_attack, blast, shielded, high_health。
- 轻装疾行：升级前五为 轻锋协议(130)、游走聚焦(107)、疾行缓存(103)、轻装骨架(99)、疾行共鸣(94)；路线权重为 bulk 160 / agile 661 / pierce 221 / blast 58 / chain 108 / close 198；主路线 agile / 分支 chain；主动标签 small_body, fast_move, moving, fast_attack。
- 爆裂重弹：升级前五为 裂片爆破(114)、锚定释放(79)、体积共鸣(76)、静立聚焦(67)、巨体回响(64)；路线权重为 bulk 480 / agile 175 / pierce 107 / blast 245 / chain 79 / close 260；主路线 blast / 分支 bulk；主动标签 blast, large_body, slow_attack, heavy_hit, heavy_blast, slow_move, high_health。
- 连锁追踪：升级前五为 碎片回流(73)、疾行缓存(61)、速射共鸣(57)、急速施放(48)、清弹屏障(48)；路线权重为 bulk 191 / agile 284 / pierce 138 / blast 66 / chain 225 / close 208；主路线 chain / 分支 pierce；主动标签 chain_skill, slow_move, fast_move, fast_attack, pierce, moving。
- 近身护盾：升级前五为 巨体回响(133)、护身锋刃(115)、破阵反应(96)、急速施放(48)、清弹屏障(48)；路线权重为 bulk 345 / agile 202 / pierce 125 / blast 80 / chain 94 / close 508；主路线 close / 分支 bulk；主动标签 close_skill, shielded, bulk_close, large_body, high_health。
- 血潮低血：升级前五为 背水矩阵(110)、血怒汲取(62)、生命强化(60)、血潮契约(58)、急速施放(48)；路线权重为 bulk 247 / agile 202 / pierce 124 / blast 78 / chain 94 / close 392；主路线 close / 分支 bulk；主动标签 low_life, blood_risk, slow_move, high_health。

## 场景明细

### 无构筑开局

- 主动标签：``
- 路线分数：bulk 0 / agile 0 / pierce 0 / blast 0 / chain 0 / close 0
- 路线选择：主路线 无 / 分支 无

升级权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 急速施放 | 48 | green | utility |  |  |
| 清弹屏障 | 48 | green | survival |  |  |
| 强击弹体 | 48 | green | projectile |  |  |
| 折光护盾 | 48 | green | survival |  |  |
| 轻装骨架 | 48 | green | agile |  |  |
| 生命强化 | 48 | green |  |  |  |
| 迅捷步伐 | 48 | green | mobility |  |  |
| 穿透弹芯 | 48 | green | pierce |  |  |
| 复苏训练 | 48 | green |  |  |  |
| 锚定释放 | 34 | blue | bulk |  |  |

商店权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 急速施放 | 43 | green | utility |  |  |
| 清弹屏障 | 43 | green | survival |  |  |
| 强击弹体 | 43 | green | projectile |  |  |
| 折光护盾 | 43 | green | survival |  |  |
| 轻装骨架 | 43 | green | agile |  |  |
| 生命强化 | 43 | green |  |  |  |
| 迅捷步伐 | 43 | green | mobility |  |  |
| 穿透弹芯 | 43 | green | pierce |  |  |
| 复苏训练 | 43 | green |  |  |  |
| 锚定释放 | 35 | blue | bulk |  |  |

### 体积迟缓

- 主动标签：`large_body`, `slow_move`, `multi_projectile`, `heavy_hit`, `slow_attack`, `blast`, `shielded`, `high_health`
- 路线分数：bulk 5 / agile 0 / pierce 0 / blast 1 / chain 0 / close 0
- 路线选择：主路线 bulk / 分支 blast

升级权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 体积共鸣 | 100 | blue | bulk | large_body |  |
| 巨体回响 | 94 | blue | bulk, close | shielded |  |
| 迟缓共鸣 | 87 | blue | bulk | slow_move |  |
| 锚定释放 | 72 | blue | bulk | slow_attack |  |
| 静立聚焦 | 61 | blue | bulk | slow_attack |  |
| 裂片爆破 | 50 | blue | blast | blast |  |
| 清弹屏障 | 48 | green | survival |  |  |
| 强击弹体 | 48 | green | projectile |  |  |
| 折光护盾 | 48 | green | survival |  |  |
| 生命强化 | 48 | green |  |  |  |

商店权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 体积共鸣 | 101 | blue | bulk | large_body |  |
| 巨体回响 | 98 | blue | bulk, close | shielded |  |
| 迟缓共鸣 | 89 | blue | bulk | slow_move |  |
| 锚定释放 | 74 | blue | bulk | slow_attack |  |
| 静立聚焦 | 63 | blue | bulk | slow_attack |  |
| 裂片爆破 | 51 | blue | blast | blast |  |
| 破阵反应 | 49 | blue | close | shielded |  |
| 清弹屏障 | 43 | green | survival |  |  |
| 强击弹体 | 43 | green | projectile |  |  |
| 折光护盾 | 43 | green | survival |  |  |

### 轻装疾行

- 主动标签：`small_body`, `fast_move`, `moving`, `fast_attack`
- 路线分数：bulk 0 / agile 7 / pierce 0 / blast 0 / chain 0 / close 0
- 路线选择：主路线 agile / 分支 chain

升级权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 轻锋协议 | 130 | blue | agile, pierce | small_body, fast_move |  |
| 游走聚焦 | 107 | blue | agile | fast_move |  |
| 疾行缓存 | 103 | blue | agile | moving, fast_move |  |
| 轻装骨架 | 99 | green | agile |  |  |
| 疾行共鸣 | 94 | blue | agile | fast_move |  |
| 轻盈共鸣 | 94 | blue | agile | small_body |  |
| 急速施放 | 48 | green | utility |  |  |
| 清弹屏障 | 48 | green | survival |  |  |
| 折光护盾 | 48 | green | survival |  |  |
| 穿透弹芯 | 48 | green | pierce |  |  |

商店权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 轻锋协议 | 135 | blue | agile, pierce | small_body, fast_move |  |
| 游走聚焦 | 109 | blue | agile | fast_move |  |
| 疾行缓存 | 108 | blue | agile | moving, fast_move |  |
| 疾行共鸣 | 96 | blue | agile | fast_move |  |
| 轻盈共鸣 | 96 | blue | agile | small_body |  |
| 轻装骨架 | 90 | green | agile |  |  |
| 急速施放 | 43 | green | utility |  |  |
| 清弹屏障 | 43 | green | survival |  |  |
| 折光护盾 | 43 | green | survival |  |  |
| 穿透弹芯 | 43 | green | pierce |  |  |

### 爆裂重弹

- 主动标签：`blast`, `large_body`, `slow_attack`, `heavy_hit`, `heavy_blast`, `slow_move`, `high_health`
- 路线分数：bulk 4 / agile 0 / pierce 0 / blast 6 / chain 0 / close 0
- 路线选择：主路线 blast / 分支 bulk

升级权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 裂片爆破 | 114 | blue | blast | blast |  |
| 锚定释放 | 79 | blue | bulk | slow_attack |  |
| 体积共鸣 | 76 | blue | bulk | large_body |  |
| 静立聚焦 | 67 | blue | bulk | slow_attack |  |
| 巨体回响 | 64 | blue | bulk, close |  |  |
| 迟缓共鸣 | 50 | blue | bulk | slow_move |  |
| 清弹屏障 | 48 | green | survival |  |  |
| 强击弹体 | 48 | green | projectile |  |  |
| 折光护盾 | 48 | green | survival |  |  |
| 生命强化 | 48 | green |  |  |  |

商店权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 裂片爆破 | 117 | blue | blast | blast |  |
| 锚定释放 | 83 | blue | bulk | slow_attack |  |
| 体积共鸣 | 79 | blue | bulk | large_body |  |
| 静立聚焦 | 70 | blue | bulk | slow_attack |  |
| 巨体回响 | 67 | blue | bulk, close |  |  |
| 重压弹芯 | 51 | purple | bulk, blast |  |  |
| 迟缓共鸣 | 51 | blue | bulk | slow_move |  |
| 清弹屏障 | 43 | green | survival |  |  |
| 强击弹体 | 43 | green | projectile |  |  |
| 折光护盾 | 43 | green | survival |  |  |

### 连锁追踪

- 主动标签：`chain_skill`, `slow_move`, `fast_move`, `fast_attack`, `pierce`, `moving`
- 路线分数：bulk 0 / agile 2 / pierce 0 / blast 0 / chain 5 / close 0
- 路线选择：主路线 chain / 分支 pierce

升级权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 碎片回流 | 73 | purple | chain | moving, chain_skill, fast_attack |  |
| 疾行缓存 | 61 | blue | agile | moving, fast_move |  |
| 速射共鸣 | 57 | purple | chain | fast_attack |  |
| 急速施放 | 48 | green | utility |  |  |
| 清弹屏障 | 48 | green | survival |  |  |
| 折光护盾 | 48 | green | survival |  |  |
| 迅捷步伐 | 48 | green | mobility |  |  |
| 穿透弹芯 | 48 | green | pierce |  |  |
| 游走聚焦 | 45 | blue | agile | fast_move |  |
| 连锁电弧 | 41 | purple | chain | fast_attack |  |

商店权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 碎片回流 | 80 | purple | chain | moving, chain_skill, fast_attack |  |
| 速射共鸣 | 66 | purple | chain | fast_attack |  |
| 疾行缓存 | 63 | blue | agile | moving, fast_move |  |
| 连锁电弧 | 46 | purple | chain | fast_attack |  |
| 游走聚焦 | 46 | blue | agile | fast_move |  |
| 急速施放 | 43 | green | utility |  |  |
| 清弹屏障 | 43 | green | survival |  |  |
| 折光护盾 | 43 | green | survival |  |  |
| 迅捷步伐 | 43 | green | mobility |  |  |
| 穿透弹芯 | 43 | green | pierce |  |  |

### 近身护盾

- 主动标签：`close_skill`, `shielded`, `bulk_close`, `large_body`, `high_health`
- 路线分数：bulk 1 / agile 0 / pierce 0 / blast 0 / chain 0 / close 5
- 路线选择：主路线 close / 分支 bulk

升级权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 巨体回响 | 133 | blue | bulk, close | shielded, close_skill |  |
| 护身锋刃 | 115 | blue | close | close_skill, large_body |  |
| 破阵反应 | 96 | blue | close | shielded, close_skill |  |
| 急速施放 | 48 | green | utility |  |  |
| 清弹屏障 | 48 | green | survival |  |  |
| 近身刀环 | 48 | purple | close | shielded, large_body |  |
| 强击弹体 | 48 | green | projectile |  |  |
| 折光护盾 | 48 | green | survival |  |  |
| 生命强化 | 48 | green |  |  |  |
| 迅捷步伐 | 48 | green | mobility |  |  |

商店权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 巨体回响 | 137 | blue | bulk, close | shielded, close_skill |  |
| 护身锋刃 | 117 | blue | close | close_skill, large_body |  |
| 破阵反应 | 100 | blue | close | shielded, close_skill |  |
| 近身刀环 | 53 | purple | close | shielded, large_body |  |
| 体积共鸣 | 44 | blue | bulk | large_body |  |
| 脉冲场 | 44 | purple | close | shielded, large_body |  |
| 急速施放 | 43 | green | utility |  |  |
| 清弹屏障 | 43 | green | survival |  |  |
| 强击弹体 | 43 | green | projectile |  |  |
| 折光护盾 | 43 | green | survival |  |  |

### 血潮低血

- 主动标签：`low_life`, `blood_risk`, `slow_move`, `high_health`
- 路线分数：bulk 0 / agile 0 / pierce 0 / blast 0 / chain 0 / close 3
- 路线选择：主路线 close / 分支 bulk

升级权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 背水矩阵 | 110 | blue | close | low_life, blood_risk |  |
| 血怒汲取 | 62 | purple | close | low_life, high_health, blood_risk |  |
| 生命强化 | 60 | green |  |  |  |
| 血潮契约 | 58 | purple | close | low_life, high_health, blood_risk |  |
| 急速施放 | 48 | green | utility |  |  |
| 清弹屏障 | 48 | green | survival |  |  |
| 强击弹体 | 48 | green | projectile |  |  |
| 折光护盾 | 48 | green | survival |  |  |
| 迅捷步伐 | 48 | green | mobility |  |  |
| 穿透弹芯 | 48 | green | pierce |  |  |

商店权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 背水矩阵 | 114 | blue | close | low_life, blood_risk |  |
| 血怒汲取 | 71 | purple | close | low_life, high_health, blood_risk |  |
| 血潮契约 | 64 | purple | close | low_life, high_health, blood_risk |  |
| 生命强化 | 53 | green |  |  |  |
| 迟缓共鸣 | 48 | blue | bulk | slow_move |  |
| 急速施放 | 43 | green | utility |  |  |
| 清弹屏障 | 43 | green | survival |  |  |
| 强击弹体 | 43 | green | projectile |  |  |
| 折光护盾 | 43 | green | survival |  |  |
| 迅捷步伐 | 43 | green | mobility |  |  |
