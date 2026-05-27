# MXS 战斗系统设计文档

## 1. 概述

| 项目 | 内容 |
|------|------|
| 项目 | MXS — 魔灵-like 回合制策略游戏 |
| 引擎 | Godot 4.6 / GDScript 2.0 |
| 架构方案 | 集中式 BattleManager + Signal 解耦 |
| MVP 范围 | 战斗核心逻辑 + 基础 UI（PVE 优先，预留 PVP） |

## 2. 需求摘要

### 2.1 战斗规模
- 可配置，由游戏模式决定（竞技场 4v4，允许 1v4 等不对称配置）

### 2.2 ATB 系统
- 纯 ATB 充能模式，速度属性决定充能速率
- 行动条充满时全场暂停，等待玩家/AI 决策
- 额外回合由装备套装效果或单位技能触发，非全局面板规则

### 2.3 技能系统
- 固定技能槽：1 个普攻 + 2-3 个技能
- 手动选择技能和目标释放

### 2.4 Buff / Debuff 系统
- 完整机制：叠加层数、互斥组、刷新机制、驱散规则

### 2.5 装备系统
- 6 槽位：头部、上装、下装、鞋、饰品、武器
- 套装效果（2件/4件两档）
- 影响角色属性，套装效果可触发额外回合等特殊机制

### 2.6 属性体系
- 八大属性：攻击(ATK)、防御(DEF)、体力(HP)、速度(SPD)、命中(ACC)、抵抗(RES)、暴击率(CRI_RATE)、暴击伤害(CRI_DMG)
- 角色元素属性：光(LIGHT)、暗(DARK)、风(WIND)、火(FIRE)、水(WATER)，攻守双向克制

### 2.7 战斗单位类型
- 攻击型(ATTACK)：伤害 = ATK × 倍率
- 体力型(HP)：伤害 = ATK × 低倍率 + HP上限 × 倍数
- 防御型(DEFENSE)：伤害 = ATK × 低倍率 + DEF × 倍数
- 辅助型(SUPPORT)：伤害 = ATK × 技能倍率（基础倍率偏低），以治疗/Buff 为主

## 3. 核心架构

### 3.1 架构图

```
┌─────────────────────────────────────────┐
│             BattleManager               │
│  (战斗生命周期、回合调度、胜负判定)       │
├─────────┬──────────┬───────────┬────────┤
│ ATB     │ Skill    │ Buff      │ Damage │
│ System  │ System   │ System    │ System │
│ (充能)  │ (释放)   │ (叠加)    │(结算)  │
└────┬────┴────┬─────┴─────┬─────┴───┬────┘
     │         │           │         │
     ▼         ▼           ▼         ▼
┌─────────────────────────────────────────┐
│           Unit (战斗单位)                │
│  属性 | 技能槽 | Buff容器 | 装备容器     │
└─────────────────────────────────────────┘
```

### 3.2 职责划分

#### BattleManager
- 唯一调度者，管理战斗生命周期（开始 → 运行 → 结束）
- 维护参战单位列表（己方 / 敌方）
- 接收子系统 Signal，协调执行顺序
- 胜负判定

#### ATB System
- 管理所有单位的行动条充能
- 充能公式：每帧增量 = base_rate × (SPD / spd_ref) × delta
- 行动条范围 0.0 ~ 1.0，满 1.0 即就绪
- 单位行动条充满时暂停 ATB，发射 `unit_ready(unit)` Signal
- 同帧多单位充满按速度降序排队依次处理
- 支持暂停/恢复充能、直接修改行动条百分比

#### Skill System
- 处理技能释放流程（选择技能 → 选择目标 → 执行效果）
- 按 SkillEffect 列表顺序逐个执行效果
- 多段攻击每段独立计算，可触发 Buff 联动
- 冷却回合管理

#### Buff System
- 管理单位身上的 Buff/Debuff 实例
- 叠加策略：刷新时长 / 增加层数 / 整体替换
- 互斥组：同组 Buff 只存一个，新的替换旧的
- 驱散规则：按优先级从低到高驱散，仅驱散可驱散的 Buff
- 回合开始 tick 持续伤害/治疗，回合结束扣减剩余持续
- 触发机制：特定 Buff 可监听事件（受攻击、行动开始、友方死亡等）

#### Damage System
- 通用伤害公式，由 SkillData.scaling_ratios 数据驱动不同类型差异
- 含防御减免、元素克制修正、暴击判定、Buff 修正
- 治疗/护盾计算
- 伤害数字生成与通知

#### Unit
- 纯数据载体
- 持有：属性集、技能列表、Buff 容器、装备配置、元素属性
- 不包含逻辑，由各系统读写

### 3.3 Signal 通信

```
ATB System ──unit_ready(unit)──► BattleManager
BattleManager ──request_action(unit)──► AI Controller / 玩家 UI
玩家/AI ──action_selected(unit, skill, targets)──► BattleManager
BattleManager ──execute_skill(unit, skill, targets)──► Skill System
Skill System ──apply_damage(source, targets, formula)──► Damage System
Skill System ──apply_buff(source, targets, buff_data)──► Buff System
Damage System ──on_damage_dealt(source, target, amount)──► Buff System
Damage System ──on_unit_died(unit)──► BattleManager
Buff System ──on_buff_applied(unit, buff)──► (UI)
Buff System ──on_buff_removed(unit, buff)──► (UI)
Buff System ──on_buff_ticked(unit, buff, effect)──► Damage System
Buff System ──on_buff_stack_changed(unit, buff, new_count)──► (UI)
Buff System ──on_unit_buffs_changed(unit)──► (重新计算属性)
```

## 4. ATB 系统详细设计

### 充能流程
1. `_process(delta)` 中遍历所有存活单位，累加充能值
2. 任意单位达到 1.0 时：暂停 ATB 充能 → 发射 `unit_ready(unit)` → 等待 BattleManager 回复
3. 行动完成后清零该单位行动条，恢复充能

### 特殊情况
- 多个单位同一帧充满：按速度从高到低排队，依次处理
- 单位死亡时从 ATB 中移除
- 被击退类 Buff 可直接减少行动条百分比
- 装备套装/技能触发的额外回合：行动后不清零，直接再次触发 `unit_ready`
- 控制类 Buff（眩晕/冰冻）：行动条充满但跳过行动，直接清零

## 5. Buff / Debuff 系统详细设计

### BuffData（Resource）
- id, 名称, 描述
- 效果类型枚举：属性修正(STAT_MODIFY)、持续伤害(DOT)、持续治疗(HOT)、控制(CONTROL)、护盾(SHIELD)、标记(MARK)、触发(TRIGGER)
- 效果参数 Dictionary
- 最大叠加层数: int
- 叠加策略枚举：REFRESH_DURATION / ADD_STACK / REPLACE
- 互斥组: String
- 优先级: int（驱散时按优先级从低到高）
- 可驱散: bool
- 持续类型枚举：TURN_BASED / ACTION_BASED / PERMANENT
- 触发事件枚举（仅 TRIGGER 类型）

### BuffInstance（运行时）
- data: BuffData
- 当前层数: int
- 剩余持续: int
- 施放者: Unit（弱引用）

### 核心规则
- 叠加策略决定新 Buff 到来时的行为
- 互斥组内只存一个，新的替换旧的
- 驱散按可驱散=true 且优先级最低优先
- 属性修正机制：Buff 变化时重新计算单位所有 Buff 属性修正总和

## 6. 技能系统详细设计

### SkillData（Resource）
- id, 名称, 描述
- 技能类型枚举：NORMAL / ACTIVE
- 冷却回合: int（普攻为 0）
- 多段次数: int
- 效果列表: Array[SkillEffect]
- 目标模式枚举：SINGLE_ENEMY / ALL_ENEMY / SINGLE_ALLY / ALL_ALLY / SELF / RANDOM_N

### SkillEffect（Resource）
- 效果类型枚举：DAMAGE / HEAL / APPLY_BUFF / DISPEL_BUFF / MODIFY_ATB / REVIVE / SPECIAL
- scaling_ratios: Dictionary { "atk_ratio": float, "hp_ratio": float, "def_ratio": float }
- buff_data: BuffData（仅 APPLY_BUFF）
- 驱散数量: int（仅 DISPEL_BUFF）
- 行动条增减: float（仅 MODIFY_ATB）

### 释放流程
1. BattleManager 收到 action_selected(unit, skill, targets)
2. SkillSystem.execute() 按效果列表逐个执行
3. 伤害效果 → Damage System，Buff 效果 → Buff System，驱散 → Buff System，行动条 → ATB System
4. 扣减技能冷却
5. 发射 skill_executed 信号

### AI 决策模块
- AIController 监听 request_action(unit) 信号
- MVP 阶段使用简单优先级规则
- 发射 action_selected(unit, skill, targets) 信号

## 7. 伤害系统详细设计

### 通用伤害公式
```
原始伤害 = ATK × atk_ratio + HP上限 × hp_ratio + DEF × def_ratio + 固定值
防御减免 = 原始伤害 × (目标DEF / (目标DEF + 防御系数))
元素克制修正 = 克制 ×1.2 / 被克制 ×0.8 / 无关 ×1.0
暴击修正 = 暴击时 × CRI_DMG / 未暴击 ×1.0
最终伤害 = 防御减免后伤害 × 元素克制修正 × 暴击修正 × Buff 修正
```

### 元素克制关系
```
风 > 水 > 火 > 风（三角克制）
光 <> 暗（互相克制）
无克制关系：×1.0
```

### 暴击判定
```
暴击率 = 基础CRI_RATE + Buff修正 - 目标抗暴
判定: Random(0, 1) < 暴击率 → 暴击
```

### 命中判定
```
命中率 = 基础命中率 + (ACC - 目标RES) × 命中系数
判定: Random(0, 1) < 命中率 → 命中，未命中则 Miss
```

## 8. 装备系统详细设计

### 6 个装备槽位

| 槽位 | 枚举 | 主属性倾向 |
|------|------|-----------|
| 头部 | HEAD | 体力、防御 |
| 上装 | UPPER | 防御、体力、攻击 |
| 下装 | LOWER | 防御、速度 |
| 鞋 | BOOTS | 速度、体力 |
| 饰品 | ACCESSORY | 暴击率、暴击伤害、命中、抵抗 |
| 武器 | WEAPON | 攻击力 |

### EquipData（Resource）
- id, 名称, 描述
- 槽位枚举: HEAD / UPPER / LOWER / BOOTS / ACCESSORY / WEAPON
- 套装类型: String
- 主属性: { stat_type: StatType, value: float }
- 副属性: Array[{ stat_type: StatType, value: float }]

### EquipSetData（Resource）
- 套装类型: String
- 效果列表: Array[{ 需要件数: int, 效果类型: Enum, 效果参数: Dictionary }]

### 属性计算
```
单位最终属性 = 基础属性 + 装备主属性合计 + 装备副属性合计 + 套装效果加成 + Buff 修正
```

### 套装效果触发机制

| 效果类型 | 触发方式 | 示例 |
|---------|---------|------|
| 属性加成 | 被动，装备即生效 | 迅速套装 2件：速度 +25% |
| 额外回合概率 | 行动结束后判定 | 暴走套装 4件：20% 概率额外回合 |
| 行动条加成 | 战斗开始时触发 | 迅速套装 4件：开局行动条 +30% |

### MVP 套装示例
- 迅速套装（2件）：速度 +25%
- 暴走套装（4件）：行动结束后 20% 概率获得额外回合
- 刀剑套装（2件）：攻击力 +30%

## 9. 数据结构总览

### 枚举定义

```
enum Element { FIRE, WATER, WIND, LIGHT, DARK }
enum UnitType { ATTACK, HP, DEFENSE, SUPPORT }
enum StatType { HP, ATK, DEF, SPD, ACC, RES, CRI_RATE, CRI_DMG }
enum EquipSlot { HEAD, UPPER, LOWER, BOOTS, ACCESSORY, WEAPON }
```

### Resource 类

- **UnitData**: id, 名称, 元素, 类型, 基础属性(Dict), 技能列表(Array[SkillData])
- **SkillData**: id, 名称, 类型, 冷却, 多段次数, 效果列表(Array[SkillEffect]), 目标模式
- **SkillEffect**: 效果类型, scaling_ratios, buff_data, 驱散数量, 行动条增减
- **BuffData**: id, 名称, 效果类型, 效果参数, 最大层数, 叠加策略, 互斥组, 优先级, 可驱散, 持续类型, 触发事件
- **EquipData**: id, 名称, 槽位, 套装类型, 主属性, 副属性
- **EquipSetData**: 套装类型, 效果列表

### 运行时实例（非 Resource）

**Unit:**
- data: UnitData
- 当前属性: Dictionary[StatType, float]
- 当前HP: float
- buff_container: Array[BuffInstance]
- equip_slots: Dictionary[EquipSlot, EquipData]
- 套装激活状态: Dictionary[String, int]
- 技能冷却: Dictionary[String, int]
- atb_value: float (0.0~1.0)
- is_alive: bool

**BuffInstance:**
- data: BuffData
- 当前层数: int
- 剩余持续: int
- 施放者: Unit（弱引用）

## 10. 完整战斗流程

### 阶段一：战斗初始化
```
BattleManager.start_battle(player_units_data, enemy_units_data, battle_config)
  ├─ 创建 Unit 实例（从 UnitData + 装备数据）
  ├─ 计算各单位最终属性（基础 + 装备主/副属性 + 套装加成）
  ├─ ATB System 初始化所有单位行动条为 0
  ├─ 套装"战斗开始时"效果触发（如行动条+30%）
  ├─ 施加初始 Buff（被动技能自带的常驻 Buff）
  ├─ UI 初始化（生成单位卡片、ATBBar、技能栏）
  └─ 进入战斗循环
```

### 阶段二：战斗循环
```
Loop:
  ├─ ATB System._process(delta) → 充能所有单位
  │   └─ 任意单位达到 1.0 → 暂停充能 → 排队处理 → unit_ready(unit)
  ├─ BattleManager 收到 unit_ready → 判断控制权
  │   ├─ 玩家单位 → 激活技能栏 → 等待操作
  │   └─ AI单位 → AIController 决策 → 短暂延迟后执行
  ├─ 收到 action_selected → SkillSystem.execute()
  │   └─ 逐 SkillEffect 执行:
  │       ├─ DAMAGE → 命中判定 → 伤害计算 → 扣HP → 死亡检查
  │       ├─ HEAL → 治疗计算 → 加HP
  │       ├─ APPLY_BUFF → Buff System 叠加/互斥判定
  │       ├─ DISPEL_BUFF → 按优先级驱散
  │       └─ MODIFY_ATB → 行动条增减
  ├─ 行动后处理:
  │   ├─ 死亡单位 Buff 联动
  │   ├─ 套装额外回合判定（触发则不清零行动条）
  │   ├─ 回合结束类 Buff tick（DOT/HOT）
  │   ├─ 扣减技能冷却
  │   └─ 胜负判定（一方全灭 → 结束）
  └─ 未结束 → 回到 Loop
```

### 阶段三：特殊情况处理

| 情况 | 处理 |
|------|------|
| 同帧多单位充满 | 按速度降序排队，逐个处理 |
| 单位行动中被击杀 | 当前行动中断，检查死亡联动 |
| 控制类 Buff（眩晕/冰冻） | 行动条充满但跳过行动，直接清零 |
| 复活效果 | 单位从死亡状态恢复，重新加入 ATB |
| 不对称战斗（1v4） | 由 battle_config 配置，逻辑无差别 |

## 11. MVP 基础 UI 设计

### 战斗画面布局
```
┌──────────────────────────────────────────────┐
│  [敌方单位区]                                 │
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐     │
│  │头像  │  │头像  │  │头像  │  │头像  │     │
│  │充能条│  │充能条│  │充能条│  │充能条│     │
│  │血条  │  │血条  │  │血条  │  │血条  │     │
│  │Buff栏│  │Buff栏│  │Buff栏│  │Buff栏│     │
│  └──────┘  └──────┘  └──────┘  └──────┘     │
│                                              │
│  [ATB 汇总条]                                 │
│  ┌──────────────────────────────────────┐    │
│  │  ●敌方2  ●敌方1  ●我方1  ●敌方3     │    │
│  │  ──────────────────── 100% ────      │    │
│  └──────────────────────────────────────┘    │
│                                              │
│  [我方单位区]                                 │
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐     │
│  │头像  │  │头像  │  │头像  │  │头像  │     │
│  │充能条│  │充能条│  │充能条│  │充能条│     │
│  │血条  │  │血条  │  │血条  │  │血条  │     │
│  │Buff栏│  │Buff栏│  │Buff栏│  │Buff栏│     │
│  └──────┘  └──────┘  └──────┘  └──────┘     │
│                                              │
│  [技能按钮栏 - 当前行动单位]                   │
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐     │
│  │ 普攻 │  │技能1 │  │技能2 │  │技能3 │     │
│  │      │  │ CD:3 │  │可用  │  │ CD:1 │     │
│  └──────┘  └──────┘  └──────┘  └──────┘     │
│                                              │
│  [目标选择提示区]                              │
│  "请选择目标" / "点击敌方单位"                 │
└──────────────────────────────────────────────┘
```

### UI 组件清单

| 组件 | 功能 | 数据绑定 |
|------|------|---------|
| UnitCard | 头像 + 充能条 + 血条 + Buff 图标列表 | 绑定 Unit 实例 |
| ATBBar | 横向进度条，显示所有单位位置 | 监听 ATB System 信号 |
| SkillButton | 技能按钮 + 冷却遮罩 + 灰显 | 绑定当前行动单位技能列表 |
| DamageNumber | 伤害/治疗数字弹出动画 | 监听 Damage System 信号 |
| TargetSelector | 点击敌方/友方单位选择目标 | BattleManager 控制启用/禁用 |
| BuffIcon | Buff 图标 + 层数角标 + 剩余回合 | 绑定 BuffInstance |

### 行动充能条（UnitCard 内）
- 进度绑定单位 ATB 充能值 0.0~1.0，每帧实时更新
- 充满时变色/闪烁提示
- 己方蓝色，敌方红色

### 交互流程
1. ATB 单位就绪 → 高亮当前单位 → 显示其技能栏
2. 玩家点击技能按钮 → 进入目标选择模式
3. 可选目标高亮闪烁，不可选目标灰显
4. 玩家点击目标 → 确认行动 → skill_executed
5. 伤害数字弹出 → 血条动画更新 → Buff 栏更新
6. 回到 ATB 充能

### AI 回合表现
- 敌方单位就绪后短暂延迟（0.5-1秒），模拟"思考"
- 显示 AI 选中的技能和目标，再执行
