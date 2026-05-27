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
