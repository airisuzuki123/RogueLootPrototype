# 阶段 5 出货规则抽样报告

本报告由 `tools/skill_offer_audit.gd` 生成，用于体检当前升级三选一和关间商店技能权重。

## 权重公式

- 基础权重来自技能稀有度。
- 已拥有同技能：每层 x1.45，上限 x2.80。
- 直接协同来源：每层 x1.32，上限 x2.25。
- 标签读取命中：每个命中标签 x1.34，上限 x2.60。
- 已成型路线：每路线层 x1.10，上限 x1.70。
- 首次核心引擎且命中读取条件：x1.35。
- 已拥有核心引擎：基础权重至少按 10 计算，再进入重复和协同权重。
- 冲突标签命中：每个冲突标签 x0.48。

## 结论摘要

- 无构筑开局：升级前五为 急速施放(58)、清弹屏障(58)、强击弹体(58)、折光护盾(58)、轻装骨架(58)；路线权重为 bulk 152 / agile 198 / pierce 128 / blast 54 / chain 62 / close 100；主动标签 。
- 体积迟缓：升级前五为 体积共鸣(173)、巨体回响(160)、迟缓共鸣(145)、静立聚焦(80)、裂片爆破(59)；路线权重为 bulk 634 / agile 93 / pierce 94 / blast 110 / chain 47 / close 249；主动标签 large_body, slow_move, multi_projectile, heavy_hit, slow_attack, blast, shielded, high_health。
- 轻装疾行：升级前五为 轻锋协议(262)、游走聚焦(196)、轻装骨架(187)、疾行共鸣(164)、轻盈共鸣(164)；路线权重为 bulk 79 / agile 1052 / pierce 352 / blast 36 / chain 118 / close 84；主动标签 small_body, fast_move, moving, fast_attack。
- 爆裂重弹：升级前五为 裂片爆破(212)、压缩弹芯(128)、体积共鸣(111)、静立聚焦(92)、巨体回响(83)；路线权重为 bulk 561 / agile 93 / pierce 79 / blast 425 / chain 47 / close 180；主动标签 blast, large_body, slow_attack, heavy_hit, heavy_blast, slow_move, high_health。
- 连锁追踪：升级前五为 碎片回流(120)、速射共鸣(73)、急速施放(58)、清弹屏障(58)、折光护盾(58)；路线权重为 bulk 116 / agile 339 / pierce 134 / blast 42 / chain 320 / close 100；主动标签 chain_skill, slow_move, fast_move, fast_attack, pierce, moving。
- 近身护盾：升级前五为 巨体回响(274)、护身锋刃(217)、急速施放(58)、清弹屏障(58)、强击弹体(58)；路线权重为 bulk 419 / agile 136 / pierce 113 / blast 56 / chain 62 / close 603；主动标签 close_skill, shielded, bulk_close, large_body, high_health。
- 血潮低血：升级前五为 生命强化(84)、血怒汲取(76)、血潮契约(66)、急速施放(58)、清弹屏障(58)；路线权重为 bulk 185 / agile 136 / pierce 112 / blast 54 / chain 62 / close 246；主动标签 low_life, blood_risk, slow_move, high_health。

## 场景明细

### 无构筑开局

- 主动标签：``
- 路线分数：bulk 0 / agile 0 / pierce 0 / blast 0 / chain 0 / close 0

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
| 巨体回响 | 30 | blue | bulk, close |  |  |

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
| 巨体回响 | 32 | blue | bulk, close |  |  |

### 体积迟缓

- 主动标签：`large_body`, `slow_move`, `multi_projectile`, `heavy_hit`, `slow_attack`, `blast`, `shielded`, `high_health`
- 路线分数：bulk 5 / agile 0 / pierce 0 / blast 1 / chain 0 / close 0

升级权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 体积共鸣 | 173 | blue | bulk | large_body |  |
| 巨体回响 | 160 | blue | bulk, close | shielded |  |
| 迟缓共鸣 | 145 | blue | bulk | slow_move |  |
| 静立聚焦 | 80 | blue | bulk | slow_attack |  |
| 裂片爆破 | 59 | blue | blast | blast |  |
| 清弹屏障 | 58 | green | survival |  |  |
| 强击弹体 | 58 | green | projectile |  |  |
| 折光护盾 | 58 | green | survival |  |  |
| 生命强化 | 58 | green |  |  |  |
| 迅捷步伐 | 58 | green | mobility |  |  |

商店权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 体积共鸣 | 181 | blue | bulk | large_body |  |
| 巨体回响 | 171 | blue | bulk, close | shielded |  |
| 迟缓共鸣 | 151 | blue | bulk | slow_move |  |
| 静立聚焦 | 84 | blue | bulk | slow_attack |  |
| 裂片爆破 | 62 | blue | blast | blast |  |
| 清弹屏障 | 52 | green | survival |  |  |
| 强击弹体 | 52 | green | projectile |  |  |
| 折光护盾 | 52 | green | survival |  |  |
| 生命强化 | 52 | green |  |  |  |
| 迅捷步伐 | 52 | green | mobility |  |  |

### 轻装疾行

- 主动标签：`small_body`, `fast_move`, `moving`, `fast_attack`
- 路线分数：bulk 0 / agile 7 / pierce 0 / blast 0 / chain 0 / close 0

升级权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 轻锋协议 | 262 | blue | agile, pierce | small_body, fast_move |  |
| 游走聚焦 | 196 | blue | agile | fast_move |  |
| 轻装骨架 | 187 | green | agile |  |  |
| 疾行共鸣 | 164 | blue | agile | fast_move |  |
| 轻盈共鸣 | 164 | blue | agile | small_body |  |
| 急速施放 | 58 | green | utility |  |  |
| 清弹屏障 | 58 | green | survival |  |  |
| 折光护盾 | 58 | green | survival |  |  |
| 穿透弹芯 | 58 | green | pierce |  |  |
| 碎片回流 | 50 | purple | agile, chain | moving, fast_attack |  |

商店权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 轻锋协议 | 278 | blue | agile, pierce | small_body, fast_move |  |
| 游走聚焦 | 205 | blue | agile | fast_move |  |
| 疾行共鸣 | 171 | blue | agile | fast_move |  |
| 轻盈共鸣 | 171 | blue | agile | small_body |  |
| 轻装骨架 | 168 | green | agile |  |  |
| 碎片回流 | 66 | purple | agile, chain | moving, fast_attack |  |
| 急速施放 | 52 | green | utility |  |  |
| 清弹屏障 | 52 | green | survival |  |  |
| 折光护盾 | 52 | green | survival |  |  |
| 穿透弹芯 | 52 | green | pierce |  |  |

### 爆裂重弹

- 主动标签：`blast`, `large_body`, `slow_attack`, `heavy_hit`, `heavy_blast`, `slow_move`, `high_health`
- 路线分数：bulk 4 / agile 0 / pierce 0 / blast 6 / chain 0 / close 0

升级权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 裂片爆破 | 212 | blue | blast | blast |  |
| 压缩弹芯 | 128 | gold | bulk, blast | slow_attack, blast |  |
| 体积共鸣 | 111 | blue | bulk | large_body |  |
| 静立聚焦 | 92 | blue | bulk | slow_attack |  |
| 巨体回响 | 83 | blue | bulk, close |  |  |
| 清弹屏障 | 58 | green | survival |  |  |
| 强击弹体 | 58 | green | projectile |  |  |
| 折光护盾 | 58 | green | survival |  |  |
| 生命强化 | 58 | green |  |  |  |
| 迅捷步伐 | 58 | green | mobility |  |  |

商店权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 裂片爆破 | 223 | blue | blast | blast |  |
| 压缩弹芯 | 128 | gold | bulk, blast | slow_attack, blast |  |
| 体积共鸣 | 118 | blue | bulk | large_body |  |
| 静立聚焦 | 98 | blue | bulk | slow_attack |  |
| 巨体回响 | 88 | blue | bulk, close |  |  |
| 迟缓共鸣 | 60 | blue | bulk | slow_move |  |
| 重压弹芯 | 56 | purple | bulk, blast |  |  |
| 清弹屏障 | 52 | green | survival |  |  |
| 强击弹体 | 52 | green | projectile |  |  |
| 折光护盾 | 52 | green | survival |  |  |

### 连锁追踪

- 主动标签：`chain_skill`, `slow_move`, `fast_move`, `fast_attack`, `pierce`, `moving`
- 路线分数：bulk 0 / agile 2 / pierce 0 / blast 0 / chain 6 / close 0

升级权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 碎片回流 | 120 | purple | agile, chain | moving, chain_skill, fast_attack |  |
| 速射共鸣 | 73 | purple | chain | fast_attack |  |
| 急速施放 | 58 | green | utility |  |  |
| 清弹屏障 | 58 | green | survival |  |  |
| 折光护盾 | 58 | green | survival |  |  |
| 迅捷步伐 | 58 | green | mobility |  |  |
| 穿透弹芯 | 58 | green | pierce |  |  |
| 游走聚焦 | 48 | blue | agile | fast_move |  |
| 回旋刃 | 48 | purple | agile, chain | fast_move, fast_attack |  |
| 连锁电弧 | 41 | purple | chain | fast_attack |  |

商店权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 碎片回流 | 152 | purple | agile, chain | moving, chain_skill, fast_attack |  |
| 速射共鸣 | 92 | purple | chain | fast_attack |  |
| 回旋刃 | 61 | purple | agile, chain | fast_move, fast_attack |  |
| 连锁电弧 | 54 | purple | chain | fast_attack |  |
| 急速施放 | 52 | green | utility |  |  |
| 清弹屏障 | 52 | green | survival |  |  |
| 折光护盾 | 52 | green | survival |  |  |
| 迅捷步伐 | 52 | green | mobility |  |  |
| 穿透弹芯 | 52 | green | pierce |  |  |
| 游走聚焦 | 51 | blue | agile | fast_move |  |

### 近身护盾

- 主动标签：`close_skill`, `shielded`, `bulk_close`, `large_body`, `high_health`
- 路线分数：bulk 1 / agile 0 / pierce 0 / blast 0 / chain 0 / close 5

升级权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 巨体回响 | 274 | blue | bulk, close | shielded, close_skill |  |
| 护身锋刃 | 217 | blue | close | close_skill, large_body |  |
| 急速施放 | 58 | green | utility |  |  |
| 清弹屏障 | 58 | green | survival |  |  |
| 强击弹体 | 58 | green | projectile |  |  |
| 折光护盾 | 58 | green | survival |  |  |
| 生命强化 | 58 | green |  |  |  |
| 迅捷步伐 | 58 | green | mobility |  |  |
| 穿透弹芯 | 58 | green | pierce |  |  |
| 复苏训练 | 58 | green |  |  |  |

商店权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 巨体回响 | 288 | blue | bulk, close | shielded, close_skill |  |
| 护身锋刃 | 227 | blue | close | close_skill, large_body |  |
| 近身刀环 | 63 | purple | close | shielded, large_body |  |
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

升级权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 生命强化 | 84 | green |  |  |  |
| 血怒汲取 | 76 | purple | close | low_life, high_health, blood_risk |  |
| 血潮契约 | 66 | purple | close | low_life, high_health, blood_risk |  |
| 急速施放 | 58 | green | utility |  |  |
| 清弹屏障 | 58 | green | survival |  |  |
| 强击弹体 | 58 | green | projectile |  |  |
| 折光护盾 | 58 | green | survival |  |  |
| 迅捷步伐 | 58 | green | mobility |  |  |
| 穿透弹芯 | 58 | green | pierce |  |  |
| 复苏训练 | 58 | green |  |  |  |

商店权重前 10：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 血怒汲取 | 97 | purple | close | low_life, high_health, blood_risk |  |
| 血潮契约 | 87 | purple | close | low_life, high_health, blood_risk |  |
| 生命强化 | 75 | green |  |  |  |
| 迟缓共鸣 | 56 | blue | bulk | slow_move |  |
| 急速施放 | 52 | green | utility |  |  |
| 清弹屏障 | 52 | green | survival |  |  |
| 强击弹体 | 52 | green | projectile |  |  |
| 折光护盾 | 52 | green | survival |  |  |
| 迅捷步伐 | 52 | green | mobility |  |  |
| 穿透弹芯 | 52 | green | pierce |  |  |
