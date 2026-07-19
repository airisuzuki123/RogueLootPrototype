# 阶段 5.5 职业出货审计报告

本报告由 `tools/class_offer_audit.gd` 生成，用于检查初始职业对升级三选一和关间商店技能权重的开局偏向。

## 审计口径

- 每个职业只模拟选择职业后的开局状态，不模拟后续升级、商店购买或装备。
- 职业路线偏向会提高相关路线分数，职业标签偏向会参与标签命中和技能权重。
- 报告只展示内部审计数据；游戏内 UI 不显示路线名、标签名或权重规则。

## 结论摘要

- 巨躯炮台：升级前五为 体积共鸣(68)、迟缓共鸣(68)、巨体回响(59)、生命强化(53)、迅捷步伐(53)；商店前五为 体积共鸣(70)、迟缓共鸣(70)、巨体回响(60)、护身锋刃(53)、锚定释放(47)；路线分数 bulk 2 / agile 0 / pierce 0 / blast 1 / chain 0 / close 1；主动标签 `large_body`, `slow_move`。
- 沉稳射手：升级前五为 静立聚焦(59)、穿透弹芯(56)、锚定释放(55)、强击弹体(52)、急速施放(48)；商店前五为 静立聚焦(61)、锚定释放(56)、穿透弹芯(50)、强击弹体(46)、急速施放(43)；路线分数 bulk 1 / agile 0 / pierce 1 / blast 0 / chain 1 / close 0；主动标签 `stationary`。
- 贴身刃卫：升级前五为 巨体回响(114)、破阵反应(89)、护身锋刃(75)、轻装骨架(56)、清弹屏障(53)；商店前五为 巨体回响(117)、破阵反应(91)、护身锋刃(77)、轻装骨架(50)、近身刀环(48)；路线分数 bulk 1 / agile 1 / pierce 0 / blast 0 / chain 0 / close 2；主动标签 `shielded`, `close_skill`。
- 游走电弧：升级前五为 轻锋协议(109)、轻装骨架(82)、疾行缓存(74)、游走聚焦(70)、疾行共鸣(62)；商店前五为 轻锋协议(112)、疾行缓存(76)、轻装骨架(74)、游走聚焦(72)、疾行共鸣(64)；路线分数 bulk 0 / agile 3 / pierce 1 / blast 0 / chain 2 / close 0；主动标签 `small_body`, `fast_move`, `chain_skill`。
- 重弹爆破：升级前五为 裂片爆破(71)、急速施放(48)、清弹屏障(48)、强击弹体(48)、折光护盾(48)；商店前五为 裂片爆破(73)、急速施放(43)、清弹屏障(43)、强击弹体(43)、折光护盾(43)；路线分数 bulk 1 / agile 0 / pierce 1 / blast 2 / chain 0 / close 0；主动标签 `blast`, `heavy_hit`。

## 职业明细

### 巨躯炮台

- 玩家可见效果：玩家体积 +15%；当前移速 -10%；体积共鸣伤害最终值 x1.20
- 路线分数：bulk 2 / agile 0 / pierce 0 / blast 1 / chain 0 / close 1
- 主动标签：`large_body`, `slow_move`

升级权重前 8：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 体积共鸣 | 68 | blue | bulk | large_body |  |
| 迟缓共鸣 | 68 | blue | bulk | slow_move |  |
| 巨体回响 | 59 | blue | bulk, close |  |  |
| 生命强化 | 53 | green |  |  |  |
| 迅捷步伐 | 53 | green | mobility |  |  |
| 复苏训练 | 53 | green |  |  |  |
| 护身锋刃 | 51 | blue | close | large_body |  |
| 急速施放 | 48 | green | utility |  |  |

商店权重前 8：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 体积共鸣 | 70 | blue | bulk | large_body |  |
| 迟缓共鸣 | 70 | blue | bulk | slow_move |  |
| 巨体回响 | 60 | blue | bulk, close |  |  |
| 护身锋刃 | 53 | blue | close | large_body |  |
| 锚定释放 | 47 | blue | bulk |  |  |
| 生命强化 | 47 | green |  |  |  |
| 迅捷步伐 | 47 | green | mobility |  |  |
| 复苏训练 | 47 | green |  |  |  |

### 沉稳射手

- 玩家可见效果：暴击率 +5%；静立聚焦暴击率最终值 x1.25；移动时专注衰减速度 -20%
- 路线分数：bulk 1 / agile 0 / pierce 1 / blast 0 / chain 1 / close 0
- 主动标签：`stationary`

升级权重前 8：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 静立聚焦 | 59 | blue | bulk |  |  |
| 穿透弹芯 | 56 | green | pierce |  |  |
| 锚定释放 | 55 | blue | bulk | stationary |  |
| 强击弹体 | 52 | green | projectile |  |  |
| 急速施放 | 48 | green | utility |  |  |
| 清弹屏障 | 48 | green | survival |  |  |
| 折光护盾 | 48 | green | survival |  |  |
| 轻装骨架 | 48 | green | agile |  |  |

商店权重前 8：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 静立聚焦 | 61 | blue | bulk |  |  |
| 锚定释放 | 56 | blue | bulk | stationary |  |
| 穿透弹芯 | 50 | green | pierce |  |  |
| 强击弹体 | 46 | green | projectile |  |  |
| 急速施放 | 43 | green | utility |  |  |
| 清弹屏障 | 43 | green | survival |  |  |
| 折光护盾 | 43 | green | survival |  |  |
| 轻装骨架 | 43 | green | agile |  |  |

### 贴身刃卫

- 玩家可见效果：开局护盾 +20，持续 999 秒；近身刀环和脉冲场伤害 x1.20；近身技能半径 +8%
- 路线分数：bulk 1 / agile 1 / pierce 0 / blast 0 / chain 0 / close 2
- 主动标签：`shielded`, `close_skill`

升级权重前 8：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 巨体回响 | 114 | blue | bulk, close | shielded, close_skill |  |
| 破阵反应 | 89 | blue | close | shielded, close_skill |  |
| 护身锋刃 | 75 | blue | close | close_skill |  |
| 轻装骨架 | 56 | green | agile |  |  |
| 清弹屏障 | 53 | green | survival |  |  |
| 折光护盾 | 53 | green | survival |  |  |
| 急速施放 | 48 | green | utility |  |  |
| 强击弹体 | 48 | green | projectile |  |  |

商店权重前 8：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 巨体回响 | 117 | blue | bulk, close | shielded, close_skill |  |
| 破阵反应 | 91 | blue | close | shielded, close_skill |  |
| 护身锋刃 | 77 | blue | close | close_skill |  |
| 轻装骨架 | 50 | green | agile |  |  |
| 近身刀环 | 48 | purple | close | shielded |  |
| 脉冲场 | 48 | purple | close | shielded |  |
| 清弹屏障 | 47 | green | survival |  |  |
| 折光护盾 | 47 | green | survival |  |  |

### 游走电弧

- 玩家可见效果：当前移速 +15%；玩家体积 -12%；连锁、回旋和追踪伤害 x1.15
- 路线分数：bulk 0 / agile 3 / pierce 1 / blast 0 / chain 2 / close 0
- 主动标签：`small_body`, `fast_move`, `chain_skill`

升级权重前 8：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 轻锋协议 | 109 | blue | agile, pierce | small_body, fast_move |  |
| 轻装骨架 | 82 | green | agile |  |  |
| 疾行缓存 | 74 | blue | agile | fast_move |  |
| 游走聚焦 | 70 | blue | agile | fast_move |  |
| 疾行共鸣 | 62 | blue | agile | fast_move |  |
| 轻盈共鸣 | 62 | blue | agile | small_body |  |
| 穿透弹芯 | 56 | green | pierce |  |  |
| 回旋刃 | 49 | purple | agile | fast_move |  |

商店权重前 8：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 轻锋协议 | 112 | blue | agile, pierce | small_body, fast_move |  |
| 疾行缓存 | 76 | blue | agile | fast_move |  |
| 轻装骨架 | 74 | green | agile |  |  |
| 游走聚焦 | 72 | blue | agile | fast_move |  |
| 疾行共鸣 | 64 | blue | agile | fast_move |  |
| 轻盈共鸣 | 64 | blue | agile | small_body |  |
| 回旋刃 | 55 | purple | agile | fast_move |  |
| 穿透弹芯 | 50 | green | pierce |  |  |

### 重弹爆破

- 玩家可见效果：爆裂范围 +20；重压弹芯和过载爆发伤害 x1.15；射击间隔 +8%
- 路线分数：bulk 1 / agile 0 / pierce 1 / blast 2 / chain 0 / close 0
- 主动标签：`blast`, `heavy_hit`

升级权重前 8：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 裂片爆破 | 71 | blue | blast | blast |  |
| 急速施放 | 48 | green | utility |  |  |
| 清弹屏障 | 48 | green | survival |  |  |
| 强击弹体 | 48 | green | projectile |  |  |
| 折光护盾 | 48 | green | survival |  |  |
| 轻装骨架 | 48 | green | agile |  |  |
| 生命强化 | 48 | green |  |  |  |
| 迅捷步伐 | 48 | green | mobility |  |  |

商店权重前 8：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 裂片爆破 | 73 | blue | blast | blast |  |
| 急速施放 | 43 | green | utility |  |  |
| 清弹屏障 | 43 | green | survival |  |  |
| 强击弹体 | 43 | green | projectile |  |  |
| 折光护盾 | 43 | green | survival |  |  |
| 轻装骨架 | 43 | green | agile |  |  |
| 生命强化 | 43 | green |  |  |  |
| 迅捷步伐 | 43 | green | mobility |  |  |
