# 阶段 5.5 职业出货审计报告

本报告由 `tools/class_offer_audit.gd` 生成，用于检查初始职业对升级三选一和关间商店技能权重的开局偏向。

## 审计口径

- 每个职业只模拟选择职业后的开局状态，不模拟后续升级、商店购买或装备。
- 职业路线偏向会提高相关路线分数，职业标签偏向会参与标签命中和技能权重。
- 报告只展示内部审计数据；游戏内 UI 不显示路线名、标签名或权重规则。

## 结论摘要

- 巨躯炮台：升级前五为 体积共鸣(128)、迟缓共鸣(120)、分裂射击(116)、穿透弹芯(110)、巨体回响(88)；商店前五为 体积共鸣(132)、分裂射击(129)、迟缓共鸣(123)、穿透弹芯(99)、巨体回响(90)；路线分数 bulk 3 / agile 0 / pierce 2 / blast 2 / chain 0 / close 1；主动标签 `large_body`, `slow_move`。
- 沉稳射手：升级前五为 静立聚焦(107)、穿透弹芯(103)、锚定释放(70)、贯穿增幅(68)、强击弹体(55)；商店前五为 静立聚焦(110)、穿透弹芯(92)、锚定释放(72)、贯穿增幅(70)、巨体回响(52)；路线分数 bulk 2 / agile 0 / pierce 2 / blast 0 / chain 1 / close 0；主动标签 `stationary`。
- 贴身刃卫：升级前五为 巨体回响(220)、护身锋刃(124)、破阵反应(112)、近身刀环(79)、脉冲场(79)；商店前五为 巨体回响(226)、护身锋刃(128)、破阵反应(116)、近身刀环(87)、脉冲场(87)；路线分数 bulk 1 / agile 1 / pierce 0 / blast 0 / chain 0 / close 2；主动标签 `shielded`, `close_skill`。
- 游走电弧：升级前五为 轻锋协议(171)、轻装骨架(153)、游走聚焦(122)、疾行缓存(103)、回旋刃(98)；商店前五为 轻锋协议(176)、轻装骨架(137)、游走聚焦(125)、回旋刃(109)、疾行缓存(106)；路线分数 bulk 0 / agile 4 / pierce 1 / blast 0 / chain 3 / close 0；主动标签 `small_body`, `fast_move`, `chain_skill`。
- 重弹爆破：升级前五为 裂片爆破(149)、爆裂核心(90)、重压弹芯(88)、穿透弹芯(62)、锚定释放(50)；商店前五为 裂片爆破(153)、爆裂核心(101)、重压弹芯(97)、穿透弹芯(56)、锚定释放(52)；路线分数 bulk 2 / agile 0 / pierce 2 / blast 3 / chain 0 / close 0；主动标签 `blast`, `heavy_hit`。

## 职业明细

### 巨躯炮台

- 玩家可见效果：玩家体积 +15%；当前移速 -10%；体积共鸣伤害最终值 x1.20；获得投射物 +100%、穿透 +100%、爆裂范围 +50%；获得移速 -50%
- 路线分数：bulk 3 / agile 0 / pierce 2 / blast 2 / chain 0 / close 1
- 主动标签：`large_body`, `slow_move`

升级权重前 8：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 体积共鸣 | 128 | blue | bulk | large_body |  |
| 迟缓共鸣 | 120 | blue | bulk | slow_move |  |
| 分裂射击 | 116 | purple | bulk, pierce |  |  |
| 穿透弹芯 | 110 | green | pierce |  |  |
| 巨体回响 | 88 | blue | bulk, close |  |  |
| 爆裂核心 | 74 | purple | bulk, blast |  |  |
| 裂片爆破 | 63 | blue | blast |  |  |
| 锚定释放 | 59 | blue | bulk |  |  |

商店权重前 8：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 体积共鸣 | 132 | blue | bulk | large_body |  |
| 分裂射击 | 129 | purple | bulk, pierce |  |  |
| 迟缓共鸣 | 123 | blue | bulk | slow_move |  |
| 穿透弹芯 | 99 | green | pierce |  |  |
| 巨体回响 | 90 | blue | bulk, close |  |  |
| 爆裂核心 | 82 | purple | bulk, blast |  |  |
| 裂片爆破 | 65 | blue | blast |  |  |
| 锚定释放 | 61 | blue | bulk |  |  |

### 沉稳射手

- 玩家可见效果：暴击率 +5%；静立聚焦暴击率最终值 x1.25；移动时专注衰减速度 -20%；获得暴击率 +100%、穿透 +100%；获得移速 -25%
- 路线分数：bulk 2 / agile 0 / pierce 2 / blast 0 / chain 1 / close 0
- 主动标签：`stationary`

升级权重前 8：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 静立聚焦 | 107 | blue | bulk |  |  |
| 穿透弹芯 | 103 | green | pierce |  |  |
| 锚定释放 | 70 | blue | bulk | stationary |  |
| 贯穿增幅 | 68 | blue | pierce |  |  |
| 强击弹体 | 55 | green | projectile |  |  |
| 巨体回响 | 50 | blue | bulk, close |  |  |
| 轻锋协议 | 50 | blue | agile, pierce |  |  |
| 体积共鸣 | 50 | blue | bulk |  |  |

商店权重前 8：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 静立聚焦 | 110 | blue | bulk |  |  |
| 穿透弹芯 | 92 | green | pierce |  |  |
| 锚定释放 | 72 | blue | bulk | stationary |  |
| 贯穿增幅 | 70 | blue | pierce |  |  |
| 巨体回响 | 52 | blue | bulk, close |  |  |
| 轻锋协议 | 52 | blue | agile, pierce |  |  |
| 体积共鸣 | 52 | blue | bulk |  |  |
| 迟缓共鸣 | 52 | blue | bulk |  |  |

### 贴身刃卫

- 玩家可见效果：开局护盾 +20，持续 999 秒；近身刀环和脉冲场伤害 x1.20；近身技能半径 +15%；获得护盾 +100%、最大生命 +50%；获得投射物伤害 -25%
- 路线分数：bulk 1 / agile 1 / pierce 0 / blast 0 / chain 0 / close 2
- 主动标签：`shielded`, `close_skill`

升级权重前 8：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 巨体回响 | 220 | blue | bulk, close | shielded, close_skill |  |
| 护身锋刃 | 124 | blue | close | close_skill |  |
| 破阵反应 | 112 | blue | close | shielded, close_skill |  |
| 近身刀环 | 79 | purple | close | shielded |  |
| 脉冲场 | 79 | purple | close | shielded |  |
| 清弹屏障 | 71 | green | survival |  |  |
| 折光护盾 | 71 | green | survival |  |  |
| 轻装骨架 | 59 | green | agile |  |  |

商店权重前 8：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 巨体回响 | 226 | blue | bulk, close | shielded, close_skill |  |
| 护身锋刃 | 128 | blue | close | close_skill |  |
| 破阵反应 | 116 | blue | close | shielded, close_skill |  |
| 近身刀环 | 87 | purple | close | shielded |  |
| 脉冲场 | 87 | purple | close | shielded |  |
| 清弹屏障 | 63 | green | survival |  |  |
| 折光护盾 | 63 | green | survival |  |  |
| 轻装骨架 | 53 | green | agile |  |  |

### 游走电弧

- 玩家可见效果：当前移速 +15%；玩家体积 -12%；连锁、回旋和追踪伤害 x1.15；获得移速 +100%、投射物 +100%、穿透 +100%；获得最大生命 -50%
- 路线分数：bulk 0 / agile 4 / pierce 1 / blast 0 / chain 3 / close 0
- 主动标签：`small_body`, `fast_move`, `chain_skill`

升级权重前 8：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 轻锋协议 | 171 | blue | agile, pierce | small_body, fast_move |  |
| 轻装骨架 | 153 | green | agile |  |  |
| 游走聚焦 | 122 | blue | agile | fast_move |  |
| 疾行缓存 | 103 | blue | agile | fast_move |  |
| 回旋刃 | 98 | purple | agile | fast_move |  |
| 疾行共鸣 | 87 | blue | agile | fast_move |  |
| 轻盈共鸣 | 87 | blue | agile | small_body |  |
| 碎片回流 | 70 | purple | chain | chain_skill |  |

商店权重前 8：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 轻锋协议 | 176 | blue | agile, pierce | small_body, fast_move |  |
| 轻装骨架 | 137 | green | agile |  |  |
| 游走聚焦 | 125 | blue | agile | fast_move |  |
| 回旋刃 | 109 | purple | agile | fast_move |  |
| 疾行缓存 | 106 | blue | agile | fast_move |  |
| 疾行共鸣 | 89 | blue | agile | fast_move |  |
| 轻盈共鸣 | 89 | blue | agile | small_body |  |
| 碎片回流 | 77 | purple | chain | chain_skill |  |

### 重弹爆破

- 玩家可见效果：爆裂范围 +20；重压弹芯和过载爆发伤害 x1.15；射击间隔 +8%；获得爆裂范围 +100%、穿透 +100%、投射物伤害 +35%；获得移速 -50%
- 路线分数：bulk 2 / agile 0 / pierce 2 / blast 3 / chain 0 / close 0
- 主动标签：`blast`, `heavy_hit`

升级权重前 8：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 裂片爆破 | 149 | blue | blast | blast |  |
| 爆裂核心 | 90 | purple | bulk, blast |  |  |
| 重压弹芯 | 88 | purple | bulk, blast |  |  |
| 穿透弹芯 | 62 | green | pierce |  | heavy_hit |
| 锚定释放 | 50 | blue | bulk |  |  |
| 巨体回响 | 50 | blue | bulk, close |  |  |
| 轻锋协议 | 50 | blue | agile, pierce |  |  |
| 体积共鸣 | 50 | blue | bulk |  |  |

商店权重前 8：

| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |
|---|---:|---|---|---|---|
| 裂片爆破 | 153 | blue | blast | blast |  |
| 爆裂核心 | 101 | purple | bulk, blast |  |  |
| 重压弹芯 | 97 | purple | bulk, blast |  |  |
| 穿透弹芯 | 56 | green | pierce |  | heavy_hit |
| 锚定释放 | 52 | blue | bulk |  |  |
| 巨体回响 | 52 | blue | bulk, close |  |  |
| 轻锋协议 | 52 | blue | agile, pierce |  |  |
| 体积共鸣 | 52 | blue | bulk |  |  |
