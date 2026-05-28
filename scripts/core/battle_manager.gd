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
	ai_controller.action_selected.connect(_on_ai_action)
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
	_perform_action(unit, skill, targets)

func _on_ai_action(unit: Unit, skill: SkillData, targets: Array[Unit]) -> void:
	_perform_action(unit, skill, targets)

func _on_unit_ready(unit: Unit) -> void:
	if not _is_running:
		return
	_current_unit = unit
	if not unit.is_alive:
		atb_system.reset_unit(unit)
		_current_unit = null
		atb_system.resume()
		return
	var has_control := false
	for b in unit.buff_container:
		if b.data.effect_type == Enums.BuffEffectType.CONTROL:
			has_control = true
			break
	if has_control:
		atb_system.reset_unit(unit)
		_current_unit = null
		atb_system.resume()
		return
	if unit.is_player_unit:
		action_requested.emit(unit)
	else:
		ai_controller.request_action(unit, player_units)

func _perform_action(unit: Unit, skill: SkillData, targets: Array[Unit]) -> void:
	skill_system.execute(unit, skill, targets)
	_finish_action(unit)

func _finish_action(unit: Unit) -> void:
	buff_system.tick_buffs(unit)
	unit.tick_cooldowns()
	_check_set_extra_turn(unit)
	action_completed.emit(unit)
	if unit.is_alive:
		atb_system.reset_unit(unit)
	_current_unit = null
	if _check_battle_end():
		return
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
	var player_alive := false
	var enemy_alive := false
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
