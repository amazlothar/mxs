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
