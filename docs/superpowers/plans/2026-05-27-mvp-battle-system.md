# MXS MVP 战斗系统实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现 MXS 回合制策略游戏的 MVP 战斗系统，包含 ATB 充能、技能释放、Buff/Debuff、装备系统、伤害结算和基础战斗 UI。

**Architecture:** 集中式 BattleManager 作为唯一调度者，ATB/Skill/Buff/Damage 四个子系统为独立 Node，通过 Signal 通信。所有数据使用 Godot Resource 子类定义，运行时 Unit/BuffInstance 为 RefCounted 对象。

**Tech Stack:** Godot 4.6, GDScript 2.0, Godot 单元测试 (GUT)

---

## 文件结构总览

```
scripts/
├── core/
│   ├── battle_manager.gd      # 战斗调度器
│   ├── atb_system.gd          # ATB 充能系统
│   ├── skill_system.gd        # 技能释放系统
│   ├── buff_system.gd         # Buff/Debuff 管理系统
│   └── damage_system.gd       # 伤害结算系统
├── data/
│   ├── enums.gd               # 全局枚举（Element, UnitType, StatType 等）
│   ├── stat_data.gd           # StatType → 属性名映射
│   ├── unit_data.gd           # 角色数据 Resource
│   ├── skill_data.gd          # 技能数据 Resource（含 SkillEffect）
│   ├── buff_data.gd           # Buff 数据 Resource
│   ├── equip_data.gd          # 装备数据 Resource
│   └── equip_set_data.gd      # 套装数据 Resource
├── runtime/
│   ├── unit.gd                # 运行时战斗单位（RefCounted）
│   └── buff_instance.gd       # 运行时 Buff 实例（RefCounted）
├── ai/
│   └── ai_controller.gd       # AI 决策控制器
├── ui/
│   ├── battle_ui.gd           # 战斗主 UI
│   ├── unit_card.gd           # 单位卡片组件
│   ├── atb_bar.gd             # ATB 汇总进度条
│   ├── skill_button.gd        # 技能按钮
│   ├── damage_number.gd       # 伤害数字弹出
│   └── buff_icon.gd           # Buff 图标
├── utils/
│   └── element_chart.gd       # 元素克制关系表
scenes/
└── battle/
    ├── battle_scene.tscn      # 战斗主场景
    ├── unit_card.tscn         # 单位卡片场景
    ├── atb_bar.tscn           # ATB 进度条场景
    └── skill_button.tscn      # 技能按钮场景
resources/
├── characters/                 # UnitData .tres
├── skills/                     # SkillData .tres
├── equipments/                 # EquipData .tres
├── equip_sets/                 # EquipSetData .tres
└── buffs/                      # BuffData .tres
```

---

### Task 1: 全局枚举与常量定义

**Files:**
- Create: `scripts/data/enums.gd`
- Create: `scripts/data/stat_data.gd`
- Create: `scripts/utils/element_chart.gd`

- [ ] **Step 1: 创建枚举定义文件**

```gdscript
# scripts/data/enums.gd
class_name Enums

enum Element { FIRE, WATER, WIND, LIGHT, DARK }

enum UnitType { ATTACK, HP, DEFENSE, SUPPORT }

enum StatType { HP, ATK, DEF, SPD, ACC, RES, CRI_RATE, CRI_DMG }

enum EquipSlot { HEAD, UPPER, LOWER, BOOTS, ACCESSORY, WEAPON }

enum SkillType { NORMAL, ACTIVE }

enum TargetMode { SINGLE_ENEMY, ALL_ENEMY, SINGLE_ALLY, ALL_ALLY, SELF, RANDOM_N }

enum SkillEffectType { DAMAGE, HEAL, APPLY_BUFF, DISPEL_BUFF, MODIFY_ATB, REVIVE, SPECIAL }

enum BuffEffectType { STAT_MODIFY, DOT, HOT, CONTROL, SHIELD, MARK, TRIGGER }

enum BuffStackStrategy { REFRESH_DURATION, ADD_STACK, REPLACE }

enum BuffDurationType { TURN_BASED, ACTION_BASED, PERMANENT }

enum BuffTriggerEvent { ON_ATTACKED, ON_ACTION_START, ON_ALLY_DIED, ON_ACTION_END }

enum EquipSetEffectType { STAT_BONUS, EXTRA_TURN_CHANCE, ATB_BOOST_ON_START }
```

- [ ] **Step 2: 创建属性名映射**

```gdscript
# scripts/data/stat_data.gd
class_name StatData

const STAT_NAMES: Dictionary = {
	Enums.StatType.HP: "HP",
	Enums.StatType.ATK: "ATK",
	Enums.StatType.DEF: "DEF",
	Enums.StatType.SPD: "SPD",
	Enums.StatType.ACC: "ACC",
	Enums.StatType.RES: "RES",
	Enums.StatType.CRI_RATE: "CRI_RATE",
	Enums.StatType.CRI_DMG: "CRI_DMG",
}

const STAT_DEFAULTS: Dictionary = {
	Enums.StatType.HP: 100.0,
	Enums.StatType.ATK: 50.0,
	Enums.StatType.DEF: 30.0,
	Enums.StatType.SPD: 100.0,
	Enums.StatType.ACC: 0.0,
	Enums.StatType.RES: 0.0,
	Enums.StatType.CRI_RATE: 15.0,
	Enums.StatType.CRI_DMG: 50.0,
}
```

- [ ] **Step 3: 创建元素克制关系表**

```gdscript
# scripts/utils/element_chart.gd
class_name ElementChart

const _ADVANTAGE: Dictionary = {
	Enums.Element.FIRE: Enums.Element.WIND,
	Enums.Element.WIND: Enums.Element.WATER,
	Enums.Element.WATER: Enums.Element.FIRE,
	Enums.Element.LIGHT: Enums.Element.DARK,
	Enums.Element.DARK: Enums.Element.LIGHT,
}

const ADVANTAGE_MULTIPLIER: float = 1.2
const DISADVANTAGE_MULTIPLIER: float = 0.8
const NEUTRAL_MULTIPLIER: float = 1.0

static func get_multiplier(attacker: Enums.Element, defender: Enums.Element) -> float:
	if _ADVANTAGE.has(attacker) and _ADVANTAGE[attacker] == defender:
		return ADVANTAGE_MULTIPLIER
	if _ADVANTAGE.has(defender) and _ADVANTAGE[defender] == attacker:
		return DISADVANTAGE_MULTIPLIER
	return NEUTRAL_MULTIPLIER
```

- [ ] **Step 4: 在 project.godot 中注册 autoload（Enums）**

在 `project.godot` 的 `[autoload]` 段添加：
```
[autoload]

Enums="*res://scripts/data/enums.gd"
```

- [ ] **Step 5: 提交**

```bash
git add scripts/data/enums.gd scripts/data/stat_data.gd scripts/utils/element_chart.gd project.godot
git commit -m "feat: 添加全局枚举、属性映射和元素克制表"
```

---

### Task 2: Resource 数据类（UnitData、SkillData、SkillEffect、BuffData）

**Files:**
- Create: `scripts/data/skill_data.gd`
- Create: `scripts/data/buff_data.gd`
- Create: `scripts/data/unit_data.gd`

- [ ] **Step 1: 创建 SkillData（含 SkillEffect 内部类）**

```gdscript
# scripts/data/skill_data.gd
class_name SkillData
extends Resource

@export var id: String = ""
@export var skill_name: String = ""
@export var description: String = ""
@export var skill_type: Enums.SkillType = Enums.SkillType.NORMAL
@export var cooldown: int = 0
@export var multihit: int = 1
@export var effects: Array[SkillEffect] = []
@export var target_mode: Enums.TargetMode = Enums.TargetMode.SINGLE_ENEMY
```

```gdscript
# scripts/data/skill_effect.gd
class_name SkillEffect
extends Resource

@export var effect_type: Enums.SkillEffectType = Enums.SkillEffectType.DAMAGE
@export var scaling_ratios: Dictionary = {
	"atk_ratio": 1.0,
	"hp_ratio": 0.0,
	"def_ratio": 0.0,
	"flat": 0.0,
}
@export var buff_data: BuffData = null
@export var dispel_count: int = 0
@export var atb_modify: float = 0.0
```

- [ ] **Step 2: 创建 BuffData**

```gdscript
# scripts/data/buff_data.gd
class_name BuffData
extends Resource

@export var id: String = ""
@export var buff_name: String = ""
@export var description: String = ""
@export var effect_type: Enums.BuffEffectType = Enums.BuffEffectType.STAT_MODIFY
@export var effect_params: Dictionary = {}
@export var max_stacks: int = 1
@export var stack_strategy: Enums.BuffStackStrategy = Enums.BuffStackStrategy.ADD_STACK
@export var mutex_group: String = ""
@export var priority: int = 0
@export var dispellable: bool = true
@export var duration_type: Enums.BuffDurationType = Enums.BuffDurationType.TURN_BASED
@export var trigger_event: Enums.BuffTriggerEvent = Enums.BuffTriggerEvent.ON_ATTACKED
@export var duration: int = 2
```

- [ ] **Step 3: 创建 UnitData**

```gdscript
# scripts/data/unit_data.gd
class_name UnitData
extends Resource

@export var id: String = ""
@export var unit_name: String = ""
@export var element: Enums.Element = Enums.Element.FIRE
@export var unit_type: Enums.UnitType = Enums.UnitType.ATTACK
@export var base_stats: Dictionary = {
	Enums.StatType.HP: 100.0,
	Enums.StatType.ATK: 50.0,
	Enums.StatType.DEF: 30.0,
	Enums.StatType.SPD: 100.0,
	Enums.StatType.ACC: 0.0,
	Enums.StatType.RES: 0.0,
	Enums.StatType.CRI_RATE: 15.0,
	Enums.StatType.CRI_DMG: 50.0,
}
@export var skills: Array[SkillData] = []
```

- [ ] **Step 4: 提交**

```bash
git add scripts/data/skill_data.gd scripts/data/skill_effect.gd scripts/data/buff_data.gd scripts/data/unit_data.gd
git commit -m "feat: 添加 UnitData、SkillData、SkillEffect、BuffData 资源类"
```

---

### Task 3: 装备数据类（EquipData、EquipSetData）

**Files:**
- Create: `scripts/data/equip_data.gd`
- Create: `scripts/data/equip_set_data.gd`

- [ ] **Step 1: 创建 EquipData**

```gdscript
# scripts/data/equip_data.gd
class_name EquipData
extends Resource

@export var id: String = ""
@export var equip_name: String = ""
@export var description: String = ""
@export var slot: Enums.EquipSlot = Enums.EquipSlot.WEAPON
@export var set_type: String = ""
@export var main_stat: Dictionary = { "stat_type": Enums.StatType.ATK, "value": 10.0 }
@export var sub_stats: Array[Dictionary] = []
```

- [ ] **Step 2: 创建 EquipSetData**

```gdscript
# scripts/data/equip_set_data.gd
class_name EquipSetData
extends Resource

@export var set_type: String = ""
@export var set_name: String = ""
@export var effects: Array[Dictionary] = []
```

- [ ] **Step 3: 提交**

```bash
git add scripts/data/equip_data.gd scripts/data/equip_set_data.gd
git commit -m "feat: 添加 EquipData、EquipSetData 装备资源类"
```

---

### Task 4: 运行时类（Unit、BuffInstance）

**Files:**
- Create: `scripts/runtime/buff_instance.gd`
- Create: `scripts/runtime/unit.gd`

- [ ] **Step 1: 创建 BuffInstance**

```gdscript
# scripts/runtime/buff_instance.gd
class_name BuffInstance
extends RefCounted

var data: BuffData
var current_stacks: int = 1
var remaining_duration: int = 0
var source_unit: WeakRef

func _init(p_data: BuffData, p_source: Unit = null) -> void:
	data = p_data
	remaining_duration = data.duration
	if p_source:
		source_unit = weakref(p_source)

func add_stack() -> void:
	if current_stacks < data.max_stacks:
		current_stacks += 1

func refresh_duration() -> void:
	remaining_duration = data.duration

func tick() -> void:
	if data.duration_type == Enums.BuffDurationType.TURN_BASED:
		remaining_duration -= 1

func is_expired() -> bool:
	if data.duration_type == Enums.BuffDurationType.PERMANENT:
		return false
	return remaining_duration <= 0
```

- [ ] **Step 2: 创建 Unit**

```gdscript
# scripts/runtime/unit.gd
class_name Unit
extends RefCounted

signal hp_changed(unit: Unit, old_hp: float, new_hp: float)
signal died(unit: Unit)

var data: UnitData
var stats: Dictionary = {}
var current_hp: float = 0.0
var max_hp: float = 0.0
var buff_container: Array[BuffInstance] = []
var equip_slots: Dictionary = {}
var set_counts: Dictionary = {}
var skill_cooldowns: Dictionary = {}
var atb_value: float = 0.0
var is_alive: bool = true
var is_player_unit: bool = true

func _init(p_data: UnitData, p_is_player: bool = true) -> void:
	data = p_data
	is_player_unit = p_is_player
	for stat_key in data.base_stats:
		stats[stat_key] = data.base_stats[stat_key]
	max_hp = stats[Enums.StatType.HP]
	current_hp = max_hp

func apply_equip(equip: EquipData) -> void:
	equip_slots[equip.slot] = equip
	if equip.main_stat.has("stat_type") and equip.main_stat.has("value"):
		var stat_type: int = equip.main_stat["stat_type"]
		var value: float = equip.main_stat["value"]
		stats[stat_type] = stats.get(stat_type, 0.0) + value
	for sub in equip.sub_stats:
		if sub.has("stat_type") and sub.has("value"):
			stats[sub["stat_type"]] = stats.get(sub["stat_type"], 0.0) + sub["value"]
	_recalculate_set_counts()
	max_hp = stats[Enums.StatType.HP]
	if current_hp > max_hp:
		current_hp = max_hp

func remove_equip(slot: int) -> void:
	var equip: EquipData = equip_slots.get(slot)
	if equip == null:
		return
	if equip.main_stat.has("stat_type") and equip.main_stat.has("value"):
		stats[equip.main_stat["stat_type"]] -= equip.main_stat["value"]
	for sub in equip.sub_stats:
		if sub.has("stat_type") and sub.has("value"):
			stats[sub["stat_type"]] -= sub["value"]
	equip_slots.erase(slot)
	_recalculate_set_counts()
	max_hp = stats[Enums.StatType.HP]

func _recalculate_set_counts() -> void:
	set_counts.clear()
	for slot in equip_slots.values():
		var e: EquipData = slot
		if e.set_type != "":
			set_counts[e.set_type] = set_counts.get(e.set_type, 0) + 1

func take_damage(amount: float) -> void:
	var old_hp: float = current_hp
	current_hp = maxf(0.0, current_hp - amount)
	hp_changed.emit(self, old_hp, current_hp)
	if current_hp <= 0.0 and is_alive:
		is_alive = false
		died.emit(self)

func heal(amount: float) -> void:
	var old_hp: float = current_hp
	current_hp = minf(max_hp, current_hp + amount)
	hp_changed.emit(self, old_hp, current_hp)

func get_stat(stat_type: int) -> float:
	return stats.get(stat_type, 0.0)

func set_stat(stat_type: int, value: float) -> void:
	stats[stat_type] = value
	if stat_type == Enums.StatType.HP:
		max_hp = value

func is_skill_ready(skill_id: String) -> bool:
	return skill_cooldowns.get(skill_id, 0) <= 0

func set_cooldown(skill_id: String, turns: int) -> void:
	skill_cooldowns[skill_id] = turns

func tick_cooldowns() -> void:
	for skill_id in skill_cooldowns:
		if skill_cooldowns[skill_id] > 0:
			skill_cooldowns[skill_id] -= 1
```

- [ ] **Step 3: 提交**

```bash
git add scripts/runtime/buff_instance.gd scripts/runtime/unit.gd
git commit -m "feat: 添加 Unit 和 BuffInstance 运行时类"
```

---

### Task 5: Buff System

**Files:**
- Create: `scripts/core/buff_system.gd`

- [ ] **Step 1: 实现 BuffSystem**

```gdscript
# scripts/core/buff_system.gd
extends Node
class_name BuffSystem

signal buff_applied(unit: Unit, buff: BuffInstance)
signal buff_removed(unit: Unit, buff: BuffInstance)
signal buff_stack_changed(unit: Unit, buff: BuffInstance, new_count: int)
signal buff_ticked(unit: Unit, buff: BuffInstance)
signal unit_buffs_changed(unit: Unit)

func apply_buff(target: Unit, buff_data: BuffData, source: Unit = null) -> BuffInstance:
	var existing: BuffInstance = _find_by_mutex_group(target, buff_data.mutex_group)
	if existing:
		_remove_buff_internal(target, existing)

	var existing_same: BuffInstance = _find_by_id(target, buff_data.id)
	if existing_same:
		match buff_data.stack_strategy:
			Enums.BuffStackStrategy.REFRESH_DURATION:
				existing_same.refresh_duration()
				buff_stack_changed.emit(target, existing_same, existing_same.current_stacks)
				return existing_same
			Enums.BuffStackStrategy.ADD_STACK:
				if existing_same.current_stacks < buff_data.max_stacks:
					existing_same.add_stack()
				existing_same.refresh_duration()
				buff_stack_changed.emit(target, existing_same, existing_same.current_stacks)
				return existing_same
			Enums.BuffStackStrategy.REPLACE:
				_remove_buff_internal(target, existing_same)

	var instance: BuffInstance = BuffInstance.new(buff_data, source)
	target.buff_container.append(instance)
	buff_applied.emit(target, instance)
	_recalc_stat_modifiers(target)
	unit_buffs_changed.emit(target)
	return instance

func dispel_buffs(target: Unit, count: int) -> void:
	var dispellable: Array[BuffInstance] = []
	for b in target.buff_container:
		if b.data.dispellable:
			dispellable.append(b)
	dispellable.sort_custom(func(a, b): return a.data.priority < b.data.priority)
	var to_remove: int = mini(count, dispellable.size())
	for i in range(to_remove):
		remove_buff(target, dispellable[i])

func remove_buff(target: Unit, buff: BuffInstance) -> void:
	_remove_buff_internal(target, buff)

func tick_buffs(unit: Unit) -> void:
	var to_remove: Array[BuffInstance] = []
	for b in unit.buff_container:
		match b.data.effect_type:
			Enums.BuffEffectType.DOT, Enums.BuffEffectType.HOT:
				buff_ticked.emit(unit, b)
		b.tick()
		if b.is_expired():
			to_remove.append(b)
	for b in to_remove:
		_remove_buff_internal(unit, b)

func get_stat_modifier(unit: Unit, stat_type: int) -> float:
	var total: float = 0.0
	for b in unit.buff_container:
		if b.data.effect_type == Enums.BuffEffectType.STAT_MODIFY:
			if b.data.effect_params.has("stat_type") and b.data.effect_params["stat_type"] == stat_type:
				var per_stack: float = b.data.effect_params.get("value", 0.0)
				total += per_stack * b.current_stacks
	return total

func _remove_buff_internal(target: Unit, buff: BuffInstance) -> void:
	target.buff_container.erase(buff)
	buff_removed.emit(target, buff)
	_recalc_stat_modifiers(target)
	unit_buffs_changed.emit(target)

func _find_by_mutex_group(unit: Unit, group: String) -> BuffInstance:
	if group == "":
		return null
	for b in unit.buff_container:
		if b.data.mutex_group == group:
			return b
	return null

func _find_by_id(unit: Unit, buff_id: String) -> BuffInstance:
	for b in unit.buff_container:
		if b.data.id == buff_id:
			return b
	return null

func _recalc_stat_modifiers(unit: Unit) -> void:
	var modifiers: Dictionary = {}
	for st in Enums.StatType.values():
		modifiers[st] = 0.0
	for b in unit.buff_container:
		if b.data.effect_type == Enums.BuffEffectType.STAT_MODIFY:
			if b.data.effect_params.has("stat_type"):
				var st: int = b.data.effect_params["stat_type"]
				var val: float = b.data.effect_params.get("value", 0.0)
				modifiers[st] = modifiers.get(st, 0.0) + val * b.current_stacks
	for st in modifiers:
		var base: float = unit.data.base_stats.get(st, 0.0)
		var equip_val: float = _get_equip_stat_total(unit, st)
		unit.set_stat(st, base + equip_val + modifiers[st])

func _get_equip_stat_total(unit: Unit, stat_type: int) -> float:
	var total: float = 0.0
	for equip in unit.equip_slots.values():
		if equip.main_stat.get("stat_type") == stat_type:
			total += equip.main_stat.get("value", 0.0)
		for sub in equip.sub_stats:
			if sub.get("stat_type") == stat_type:
				total += sub.get("value", 0.0)
	return total
```

- [ ] **Step 2: 提交**

```bash
git add scripts/core/buff_system.gd
git commit -m "feat: 实现 BuffSystem（叠加、互斥、驱散、属性修正）"
```

---

### Task 6: Damage System

**Files:**
- Create: `scripts/core/damage_system.gd`

- [ ] **Step 1: 实现 DamageSystem**

```gdscript
# scripts/core/damage_system.gd
extends Node
class_name DamageSystem

signal damage_dealt(source: Unit, target: Unit, amount: float, is_crit: bool)
signal heal_applied(source: Unit, target: Unit, amount: float)
signal unit_died(unit: Unit)

const DEF_COEFFICIENT: float = 300.0
const BASE_HIT_RATE: float = 0.85
const HIT_COEFFICIENT: float = 0.005

var buff_system: BuffSystem

func calculate_raw_damage(source: Unit, scaling: Dictionary) -> float:
	var atk_ratio: float = scaling.get("atk_ratio", 0.0)
	var hp_ratio: float = scaling.get("hp_ratio", 0.0)
	var def_ratio: float = scaling.get("def_ratio", 0.0)
	var flat: float = scaling.get("flat", 0.0)
	return (source.get_stat(Enums.StatType.ATK) * atk_ratio
		+ source.get_stat(Enums.StatType.HP) * hp_ratio
		+ source.get_stat(Enums.StatType.DEF) * def_ratio
		+ flat)

func apply_defense(raw_damage: float, target_def: float) -> float:
	return raw_damage * (target_def / (target_def + DEF_COEFFICIENT))

func roll_crit(source: Unit) -> bool:
	var crit_rate: float = source.get_stat(Enums.StatType.CRI_RATE)
	return randf() < (crit_rate / 100.0)

func roll_hit(source: Unit, target: Unit) -> bool:
	var acc: float = source.get_stat(Enums.StatType.ACC)
	var res: float = target.get_stat(Enums.StatType.RES)
	var hit_rate: float = BASE_HIT_RATE + (acc - res) * HIT_COEFFICIENT
	return randf() < hit_rate

func deal_damage(source: Unit, target: Unit, effect: SkillEffect) -> Dictionary:
	var result: Dictionary = {"hit": false, "damage": 0.0, "is_crit": false}
	if not target.is_alive:
		return result
	if not roll_hit(source, target):
		return result
	result["hit"] = true
	var raw: float = calculate_raw_damage(source, effect.scaling_ratios)
	var after_def: float = raw - apply_defense(raw, target.get_stat(Enums.StatType.DEF))
	var elemental: float = after_def * ElementChart.get_multiplier(source.data.element, target.data.element)
	var is_crit: bool = roll_crit(source)
	result["is_crit"] = is_crit
	var crit_mult: float = 1.0
	if is_crit:
		crit_mult = 1.0 + source.get_stat(Enums.StatType.CRI_DMG) / 100.0
	var final_damage: float = maxf(1.0, elemental * crit_mult)
	result["damage"] = final_damage
	target.take_damage(final_damage)
	damage_dealt.emit(source, target, final_damage, is_crit)
	if not target.is_alive:
		unit_died.emit(target)
	return result

func apply_heal(source: Unit, target: Unit, effect: SkillEffect) -> float:
	var raw: float = calculate_raw_damage(source, effect.scaling_ratios)
	var heal_amount: float = maxf(0.0, raw)
	target.heal(heal_amount)
	heal_applied.emit(source, target, heal_amount)
	return heal_amount
```

- [ ] **Step 2: 提交**

```bash
git add scripts/core/damage_system.gd
git commit -m "feat: 实现 DamageSystem（伤害公式、防御减免、暴击、命中、元素克制）"
```

---

### Task 7: ATB System

**Files:**
- Create: `scripts/core/atb_system.gd`

- [ ] **Step 1: 实现 ATBSystem**

```gdscript
# scripts/core/atb_system.gd
extends Node
class_name ATBSystem

signal unit_ready(unit: Unit)

const BASE_CHARGE_RATE: float = 0.06
const SPD_REFERENCE: float = 100.0

var _units: Array[Unit] = []
var _is_paused: bool = false

func add_unit(unit: Unit) -> void:
	if not _units.has(unit):
		_units.append(unit)

func remove_unit(unit: Unit) -> void:
	_units.erase(unit)

func pause() -> void:
	_is_paused = true

func resume() -> void:
	_is_paused = false

func reset_unit(unit: Unit) -> void:
	unit.atb_value = 0.0

func modify_atb(unit: Unit, percentage: float) -> void:
	unit.atb_value = clampf(unit.atb_value + percentage, 0.0, 1.0)

func _process(delta: float) -> void:
	if _is_paused:
		return
	var ready_units: Array[Unit] = []
	for unit in _units:
		if not unit.is_alive:
			continue
		var spd: float = unit.get_stat(Enums.StatType.SPD)
		var increment: float = BASE_CHARGE_RATE * (spd / SPD_REFERENCE) * delta
		unit.atb_value = minf(1.0, unit.atb_value + increment)
		if unit.atb_value >= 1.0:
			ready_units.append(unit)
	if ready_units.size() > 0:
		ready_units.sort_custom(func(a, b): return a.get_stat(Enums.StatType.SPD) > b.get_stat(Enums.StatType.SPD))
		_is_paused = true
		for unit in ready_units:
			unit_ready.emit(unit)
```

- [ ] **Step 2: 提交**

```bash
git add scripts/core/atb_system.gd
git commit -m "feat: 实现 ATBSystem（充能、暂停、速度队列）"
```

---

### Task 8: Skill System

**Files:**
- Create: `scripts/core/skill_system.gd`

- [ ] **Step 1: 实现 SkillSystem**

```gdscript
# scripts/core/skill_system.gd
extends Node
class_name SkillSystem

signal skill_executed(unit: Unit, skill: SkillData, targets: Array[Unit])

var damage_system: DamageSystem
var buff_system: BuffSystem
var atb_system: ATBSystem

func execute(unit: Unit, skill: SkillData, targets: Array[Unit]) -> void:
	for effect in skill.effects:
		match effect.effect_type:
			Enums.SkillEffectType.DAMAGE:
				for target in targets:
					if not target.is_alive:
						continue
					for i in range(skill.multihit):
						damage_system.deal_damage(unit, target, effect)
			Enums.SkillEffectType.HEAL:
				for target in targets:
					if not target.is_alive:
						continue
					damage_system.apply_heal(unit, target, effect)
			Enums.SkillEffectType.APPLY_BUFF:
				if effect.buff_data != null:
					for target in targets:
						if not target.is_alive:
							continue
						buff_system.apply_buff(target, effect.buff_data, unit)
			Enums.SkillEffectType.DISPEL_BUFF:
				for target in targets:
					buff_system.dispel_buffs(target, effect.dispel_count)
			Enums.SkillEffectType.MODIFY_ATB:
				for target in targets:
					atb_system.modify_atb(target, effect.atb_modify)
	if skill.cooldown > 0:
		unit.set_cooldown(skill.id, skill.cooldown)
	skill_executed.emit(unit, skill, targets)
```

- [ ] **Step 2: 提交**

```bash
git add scripts/core/skill_system.gd
git commit -m "feat: 实现 SkillSystem（技能效果分发、多段攻击、冷却）"
```

---

### Task 9: AI Controller

**Files:**
- Create: `scripts/ai/ai_controller.gd`

- [ ] **Step 1: 实现 AIController**

```gdscript
# scripts/ai/ai_controller.gd
extends Node
class_name AIController

signal action_selected(unit: Unit, skill: SkillData, targets: Array[Unit])

var _pending_unit: Unit = null
var _enemies: Array[Unit] = []

func request_action(unit: Unit, enemies: Array[Unit]) -> void:
	_pending_unit = unit
	_enemies = enemies
	var timer: SceneTreeTimer = get_tree().create_timer(0.7)
	timer.timeout.connect(_make_decision)

func _make_decision() -> void:
	if _pending_unit == null:
		return
	var skill: SkillData = _pick_skill(_pending_unit)
	var targets: Array[Unit] = _pick_targets(_pending_unit, skill)
	action_selected.emit(_pending_unit, skill, targets)
	_pending_unit = null
	_enemies.clear()

func _pick_skill(unit: Unit) -> SkillData:
	var available: Array[SkillData] = []
	for s in unit.data.skills:
		if unit.is_skill_ready(s.id):
			available.append(s)
	if available.size() == 0:
		return unit.data.skills[0]
	for s in available:
		if s.skill_type == Enums.SkillType.ACTIVE:
			return s
	return available[0]

func _pick_targets(unit: Unit, skill: SkillData) -> Array[Unit]:
	var alive_enemies: Array[Unit] = []
	for e in _enemies:
		if e.is_alive:
			alive_enemies.append(e)
	if alive_enemies.size() == 0:
		return []
	match skill.target_mode:
		Enums.TargetMode.SINGLE_ENEMY, Enums.TargetMode.RANDOM_N:
			return [alive_enemies[randi() % alive_enemies.size()]]
		Enums.TargetMode.ALL_ENEMY:
			return alive_enemies
		Enums.TargetMode.SINGLE_ALLY:
			return [unit]
		Enums.TargetMode.ALL_ALLY:
			return [unit]
		Enums.TargetMode.SELF:
			return [unit]
		_:
			return [alive_enemies[0]]
```

- [ ] **Step 2: 提交**

```bash
git add scripts/ai/ai_controller.gd
git commit -m "feat: 实现 AIController（简单优先级 AI 决策）"
```

---

### Task 10: BattleManager

**Files:**
- Create: `scripts/core/battle_manager.gd`

- [ ] **Step 1: 实现 BattleManager**

```gdscript
# scripts/core/battle_manager.gd
extends Node
class_name BattleManager

signal battle_started
signal battle_ended(player_won: bool)
signal action_requested(unit: Unit)
signal action_completed(unit: Unit)

var atb_system: ATBSystem
var skill_system: SkillSystem
var buff_system: BuffSystem
var damage_system: DamageSystem
var ai_controller: AIController

var player_units: Array[Unit] = []
var enemy_units: Array[Unit] = []
var all_units: Array[Unit] = []
var _current_unit: Unit = null
var _is_running: bool = false

func _ready() -> void:
	atb_system = ATBSystem.new()
	skill_system = SkillSystem.new()
	buff_system = BuffSystem.new()
	damage_system = DamageSystem.new()
	ai_controller = AIController.new()

	add_child(atb_system)
	add_child(skill_system)
	add_child(buff_system)
	add_child(damage_system)
	add_child(ai_controller)

	skill_system.damage_system = damage_system
	skill_system.buff_system = buff_system
	skill_system.atb_system = atb_system
	damage_system.buff_system = buff_system

	atb_system.unit_ready.connect(_on_unit_ready)
	skill_system.skill_executed.connect(_on_skill_executed)
	ai_controller.action_selected.connect(_on_action_selected)
	damage_system.unit_died.connect(_on_unit_died)

func start_battle(p_units: Array[UnitData], e_units: Array[UnitData]) -> void:
	player_units.clear()
	enemy_units.clear()
	all_units.clear()
	for ud in p_units:
		var unit: Unit = Unit.new(ud, true)
		player_units.append(unit)
		all_units.append(unit)
		atb_system.add_unit(unit)
	for ud in e_units:
		var unit: Unit = Unit.new(ud, false)
		enemy_units.append(unit)
		all_units.append(unit)
		atb_system.add_unit(unit)
	_is_running = true
	battle_started.emit()
	atb_system.resume()

func player_select_action(unit: Unit, skill: SkillData, targets: Array[Unit]) -> void:
	if not _is_running or _current_unit != unit:
		return
	_on_action_selected(unit, skill, targets)

func _on_unit_ready(unit: Unit) -> void:
	_current_unit = unit
	if not unit.is_alive:
		atb_system.reset_unit(unit)
		atb_system.resume()
		return
	var has_control: bool = false
	for b in unit.buff_container:
		if b.data.effect_type == Enums.BuffEffectType.CONTROL:
			has_control = true
			break
	if has_control:
		atb_system.reset_unit(unit)
		atb_system.resume()
		return
	if unit.is_player_unit:
		action_requested.emit(unit)
	else:
		ai_controller.request_action(unit, player_units)

func _on_action_selected(unit: Unit, skill: SkillData, targets: Array[Unit]) -> void:
	skill_system.execute(unit, skill, targets)

func _on_skill_executed(unit: Unit, skill: SkillData, targets: Array[Unit]) -> void:
	buff_system.tick_buffs(unit)
	unit.tick_cooldowns()
	_check_set_extra_turn(unit)
	action_completed.emit(unit)
	_current_unit = null
	if _check_battle_end():
		return
	atb_system.reset_unit(unit)
	atb_system.resume()

func _on_unit_died(unit: Unit) -> void:
	atb_system.remove_unit(unit)

func _check_set_extra_turn(unit: Unit) -> void:
	for set_type in unit.set_counts:
		var count: int = unit.set_counts[set_type]
		if count >= 4:
			if set_type == "rampage":
				if randf() < 0.2:
					unit.atb_value = 1.0

func _check_battle_end() -> bool:
	var player_alive: bool = false
	var enemy_alive: bool = false
	for u in player_units:
		if u.is_alive:
			player_alive = true
			break
	for u in enemy_units:
		if u.is_alive:
			enemy_alive = true
			break
	if not player_alive:
		_is_running = false
		battle_ended.emit(false)
		return true
	if not enemy_alive:
		_is_running = false
		battle_ended.emit(true)
		return true
	return false
```

- [ ] **Step 2: 提交**

```bash
git add scripts/core/battle_manager.gd
git commit -m "feat: 实现 BattleManager（战斗生命周期、调度、胜负判定）"
```

---

### Task 11: 测试数据资源

**Files:**
- Create: `resources/buffs/atk_up.tres`
- Create: `resources/buffs/dot_poison.tres`
- Create: `resources/skills/normal_attack.tres`
- Create: `resources/skills/fire_slash.tres`
- Create: `resources/characters/test_warrior.tres`
- Create: `resources/characters/test_enemy.tres`

- [ ] **Step 1: 创建测试 Buff 数据**

在 Godot 编辑器中创建以下 `.tres` 资源文件（或手写）：

`resources/buffs/atk_up.tres` — 攻击力提升 Buff：
- id="atk_up", buff_name="攻击提升", effect_type=STAT_MODIFY
- effect_params={"stat_type": 1, "value": 20.0} (ATK=1)
- max_stacks=3, stack_strategy=ADD_STACK, duration=3, dispellable=true

`resources/buffs/dot_poison.tres` — 中毒 DOT：
- id="poison", buff_name="中毒", effect_type=DOT
- effect_params={"damage_percent": 5.0}
- max_stacks=1, stack_strategy=REPLACE, duration=3, dispellable=true

- [ ] **Step 2: 创建测试技能数据**

`resources/skills/normal_attack.tres` — 普攻：
- id="normal_attack", skill_type=NORMAL, cooldown=0, multihit=1
- target_mode=SINGLE_ENEMY
- effects=[{effect_type=DAMAGE, scaling_ratios={"atk_ratio":1.0,"hp_ratio":0.0,"def_ratio":0.0,"flat":0.0}}]

`resources/skills/fire_slash.tres` — 火焰斩：
- id="fire_slash", skill_name="火焰斩", skill_type=ACTIVE, cooldown=3, multihit=2
- target_mode=SINGLE_ENEMY
- effects=[{effect_type=DAMAGE, scaling_ratios={"atk_ratio":2.5,...}}, {effect_type=APPLY_BUFF, buff_data=atk_up}]

- [ ] **Step 3: 创建测试角色数据**

`resources/characters/test_warrior.tres` — 测试战士：
- element=FIRE, unit_type=ATTACK
- base_stats={HP:500, ATK:120, DEF:40, SPD:110, ACC:0, RES:0, CRI_RATE:20, CRI_DMG:50}
- skills=[normal_attack, fire_slash]

`resources/characters/test_enemy.tres` — 测试敌人：
- element=WATER, unit_type=HP
- base_stats={HP:800, ATK:60, DEF:50, SPD:90, ...}
- skills=[normal_attack]

- [ ] **Step 4: 提交**

```bash
git add resources/
git commit -m "feat: 添加测试用 Buff、技能、角色数据资源"
```

---

### Task 12: 战斗场景与基础 UI

**Files:**
- Create: `scenes/battle/battle_scene.tscn`
- Create: `scenes/battle/unit_card.tscn`
- Create: `scripts/ui/unit_card.gd`
- Create: `scripts/ui/battle_ui.gd`
- Create: `scripts/ui/atb_bar.gd`
- Create: `scripts/ui/skill_button.gd`
- Create: `scripts/ui/damage_number.gd`
- Create: `scripts/ui/buff_icon.gd`

- [ ] **Step 1: 创建 UnitCard 场景和脚本**

```gdscript
# scripts/ui/unit_card.gd
extends HBoxContainer

@onready var name_label: Label = $NameLabel
@onready var charge_bar: ProgressBar = $ChargeBar
@onready var hp_bar: ProgressBar = $HPBar
@onready var hp_label: Label = $HPLabel
@onready var buff_container: HBoxContainer = $BuffContainer

var unit: Unit: set = set_unit

func set_unit(value: Unit) -> void:
	if unit:
		unit.hp_changed.disconnect(_on_hp_changed)
	unit = value
	if unit:
		name_label.text = unit.data.unit_name
		charge_bar.value = 0.0
		hp_bar.max_value = unit.max_hp
		hp_bar.value = unit.current_hp
		hp_label.text = "%d/%d" % [unit.current_hp, unit.max_hp]
		unit.hp_changed.connect(_on_hp_changed)

func _process(_delta: float) -> void:
	if unit:
		charge_bar.value = unit.atb_value * 100.0

func _on_hp_changed(u: Unit, old_hp: float, new_hp: float) -> void:
	hp_bar.value = new_hp
	hp_label.text = "%d/%d" % [new_hp, u.max_hp]
```

在 Godot 编辑器中创建 `scenes/battle/unit_card.tscn`：根节点 HBoxContainer（脚本 unit_card.gd），子节点 NameLabel(Label)、ChargeBar(ProgressBar)、HPBar(ProgressBar)、HPLabel(Label)、BuffContainer(HBoxContainer)。

- [ ] **Step 2: 创建 ATBBar**

```gdscript
# scripts/ui/atb_bar.gd
extends HBoxContainer

func update_units(units: Array[Unit]) -> void:
	for child in get_children():
		child.queue_free()
	for unit in units:
		if not unit.is_alive:
			continue
		var marker: ColorRect = ColorRect.new()
		marker.custom_minimum_size = Vector2(8, 16)
		marker.color = Color.BLUE if unit.is_player_unit else Color.RED
		marker.size.x = unit.atb_value * 400.0
		add_child(marker)
```

- [ ] **Step 3: 创建 SkillButton**

```gdscript
# scripts/ui/skill_button.gd
extends Button

var skill: SkillData: set = set_skill
var unit: Unit

func set_skill(value: SkillData) -> void:
	skill = value
	if skill:
		text = skill.skill_name
		disabled = false
	else:
		text = ""
		disabled = true

func _process(_delta: float) -> void:
	if unit and skill:
		var cd: int = unit.skill_cooldowns.get(skill.id, 0)
		disabled = cd > 0 or not unit.is_skill_ready(skill.id)
		if cd > 0:
			text = "%s (%d)" % [skill.skill_name, cd]
		else:
			text = skill.skill_name
```

- [ ] **Step 4: 创建 DamageNumber**

```gdscript
# scripts/ui/damage_number.gd
extends Label

var _timer: float = 1.0

func show_damage(amount: float, is_crit: bool) -> void:
	text = str(int(amount))
	if is_crit:
		text = "暴击! " + text
		add_theme_color_override("font_color", Color.YELLOW)
	else:
		add_theme_color_override("font_color", Color.WHITE)
	_timer = 1.0

func _process(delta: float) -> void:
	_timer -= delta
	position.y -= 30.0 * delta
	if _timer <= 0.0:
		queue_free()
```

- [ ] **Step 5: 创建 BuffIcon**

```gdscript
# scripts/ui/buff_icon.gd
extends TextureRect

var buff: BuffInstance: set = set_buff
@onready var stack_label: Label = $StackLabel

func set_buff(value: BuffInstance) -> void:
	buff = value
	if buff:
		stack_label.text = str(buff.current_stacks) if buff.current_stacks > 1 else ""
		tooltip_text = "%s (%d回合)" % [buff.data.buff_name, buff.remaining_duration]
```

- [ ] **Step 6: 创建 BattleUI**

```gdscript
# scripts/ui/battle_ui.gd
extends Control

@onready var enemy_container: HBoxContainer = $EnemyContainer
@onready var player_container: HBoxContainer = $PlayerContainer
@onready var atb_bar: HBoxContainer = $ATBBar
@onready var skill_bar: HBoxContainer = $SkillBar
@onready var target_hint: Label = $TargetHint

var battle_manager: BattleManager
var _current_unit: Unit = null
var _selected_skill: SkillData = null
var _unit_cards: Dictionary = {}
var _skill_buttons: Array = []

func setup(bm: BattleManager) -> void:
	battle_manager = bm
	bm.action_requested.connect(_on_action_requested)
	bm.action_completed.connect(_on_action_completed)
	bm.damage_system.damage_dealt.connect(_on_damage_dealt)

func create_unit_cards(units: Array[Unit], container: HBoxContainer) -> void:
	for child in container.get_children():
		child.queue_free()
	for unit in units:
		var card_scene: PackedScene = load("res://scenes/battle/unit_card.tscn")
		var card = card_scene.instantiate()
		container.add_child(card)
		card.unit = unit
		_unit_cards[unit] = card

func _on_action_requested(unit: Unit) -> void:
	_current_unit = unit
	_selected_skill = null
	_show_skills(unit)
	target_hint.text = "请选择技能"

func _show_skills(unit: Unit) -> void:
	for child in skill_bar.get_children():
		child.queue_free()
	_skill_buttons.clear()
	for skill_data in unit.data.skills:
		var btn: Button = Button.new()
		btn.text = skill_data.skill_name
		var sd: SkillData = skill_data
		btn.pressed.connect(_on_skill_selected.bind(sd))
		skill_bar.add_child(btn)
		_skill_buttons.append(btn)

func _on_skill_selected(skill: SkillData) -> void:
	_selected_skill = skill
	target_hint.text = "请选择目标"
	_enable_target_selection()

func _enable_target_selection() -> void:
	var targets: Array[Unit] = battle_manager.enemy_units if _current_unit.is_player_unit else battle_manager.player_units
	for target in targets:
		if target.is_alive and _unit_cards.has(target):
			var card = _unit_cards[target]
			card.gui_input.connect(_on_target_clicked.bind(target))

func _on_target_clicked(event: InputEvent, target: Unit) -> void:
	if event is InputEventMouseButton and event.pressed:
		if _current_unit and _selected_skill:
			battle_manager.player_select_action(_current_unit, _selected_skill, [target])

func _on_action_completed(unit: Unit) -> void:
	_current_unit = null
	_selected_skill = null
	for child in skill_bar.get_children():
		child.queue_free()
	target_hint.text = ""

func _on_damage_dealt(source: Unit, target: Unit, amount: float, is_crit: bool) -> void:
	if _unit_cards.has(target):
		var card = _unit_cards[target]
		var dmg_label: Label = Label.new()
		dmg_label.set_script(load("res://scripts/ui/damage_number.gd"))
		card.add_child(dmg_label)
		dmg_label.show_damage(amount, is_crit)
```

- [ ] **Step 7: 创建战斗主场景**

在 Godot 编辑器中创建 `scenes/battle/battle_scene.tscn`：
- 根节点 Node（脚本引用 battle_manager 场景脚本）
- 子节点 Control（BattleUI）：
  - VBoxContainer 布局：EnemyContainer、ATBBar、PlayerContainer、SkillBar、TargetHint

创建 `scenes/battle/battle_scene.gd`：
```gdscript
# scenes/battle/battle_scene.gd
extends Node2D

@onready var battle_ui: Control = $BattleUI
@onready var battle_manager: BattleManager = $BattleManager

func _ready() -> void:
	battle_ui.setup(battle_manager)
	var warrior_data: UnitData = load("res://resources/characters/test_warrior.tres")
	var enemy_data: UnitData = load("res://resources/characters/test_enemy.tres")
	battle_manager.start_battle([warrior_data], [enemy_data])
	battle_ui.create_unit_cards(battle_manager.player_units, battle_ui.player_container)
	battle_ui.create_unit_cards(battle_manager.enemy_units, battle_ui.enemy_container)
```

- [ ] **Step 8: 提交**

```bash
git add scenes/ scripts/ui/
git commit -m "feat: 实现战斗 UI（UnitCard、ATBBar、SkillBar、DamageNumber、BattleUI）"
```

---

### Task 13: 集成验证

**Files:**
- Modify: `project.godot`（设置主场景）

- [ ] **Step 1: 将战斗场景设为主场景**

在 `project.godot` 的 `[application]` 段修改：
```
config/main_scene="res://scenes/battle/battle_scene.tscn"
```

- [ ] **Step 2: 在 Godot 编辑器中运行验证**

在 Godot 编辑器中运行项目，验证：
1. 战斗启动，ATB 条开始充能
2. 我方单位先就绪（速度更高），技能栏显示
3. 点击技能 → 选择目标 → 伤害数字弹出
4. AI 敌方自动行动
5. 一方全灭后战斗结束

- [ ] **Step 3: 修复运行时问题（如有）**

根据运行结果修复任何错误。

- [ ] **Step 4: 提交**

```bash
git add -A
git commit -m "feat: 完成战斗场景集成，设置主场景"
```

---

## 自审检查清单

**Spec 覆盖度：**
- [x] ATB 充能系统 — Task 7
- [x] 暂停式行动 — Task 7 + Task 10
- [x] 速度队列 — Task 7
- [x] Buff 叠加/互斥/驱散 — Task 5
- [x] Buff 属性修正 — Task 5
- [x] 伤害公式（含单位类型差异） — Task 6（由 scaling_ratios 驱动）
- [x] 元素克制 — Task 1 + Task 6
- [x] 暴击/命中 — Task 6
- [x] 装备 6 槽位 — Task 3 + Task 4
- [x] 套装效果 — Task 4（Unit）+ Task 10（BattleManager）
- [x] 技能释放流程 — Task 8
- [x] AI 控制器 — Task 9
- [x] BattleManager 调度 — Task 10
- [x] UI 组件 — Task 12
- [x] 测试数据 — Task 11

**Placeholder 扫描：** 无 TBD/TODO

**类型一致性：** 枚举、Resource、运行时类命名统一
