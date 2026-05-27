extends Control

@onready var enemy_container: HBoxContainer = $VBoxContainer/EnemyContainer
@onready var player_container: HBoxContainer = $VBoxContainer/PlayerContainer
@onready var atb_bar_container: HBoxContainer = $VBoxContainer/ATBBar
@onready var skill_bar: HBoxContainer = $VBoxContainer/SkillBar
@onready var target_hint: Label = $VBoxContainer/TargetHint

var battle_manager: BattleManager
var _current_unit: Unit = null
var _selected_skill: SkillData = null
var _unit_cards: Dictionary = {}

func setup(bm: BattleManager) -> void:
	battle_manager = bm
	bm.action_requested.connect(_on_action_requested)
	bm.action_completed.connect(_on_action_completed)
	bm.damage_system.damage_dealt.connect(_on_damage_dealt)

func create_unit_cards(units: Array[Unit], container: HBoxContainer) -> void:
	for child in container.get_children():
		child.queue_free()
	for unit in units:
		var card := _create_unit_card(unit)
		container.add_child(card)
		_unit_cards[unit] = card

func _create_unit_card(unit: Unit) -> HBoxContainer:
	var card := HBoxContainer.new()
	var name_label := Label.new()
	name_label.text = unit.data.unit_name
	name_label.custom_minimum_size.x = 80.0
	var charge_bar := ProgressBar.new()
	charge_bar.custom_minimum_size.x = 100.0
	charge_bar.max_value = 100.0
	charge_bar.value = 0.0
	var hp_bar := ProgressBar.new()
	hp_bar.max_value = unit.max_hp
	hp_bar.value = unit.current_hp
	hp_bar.custom_minimum_size.x = 100.0
	var hp_label := Label.new()
	hp_label.text = "%d/%d" % [unit.current_hp, unit.max_hp]
	hp_label.custom_minimum_size.x = 80.0
	card.add_child(name_label)
	card.add_child(charge_bar)
	card.add_child(hp_bar)
	card.add_child(hp_label)
	_bind_card(card, unit, charge_bar, hp_bar, hp_label)
	return card

func _bind_card(card: HBoxContainer, unit: Unit, charge_bar: ProgressBar, hp_bar: ProgressBar, hp_label: Label) -> void:
	unit.hp_changed.connect(func(u, old_hp, new_hp):
		hp_bar.value = new_hp
		hp_label.text = "%d/%d" % [new_hp, u.max_hp]
	)

func _process(_delta: float) -> void:
	for unit in _unit_cards:
		var card: HBoxContainer = _unit_cards[unit]
		if card and card.is_inside_tree():
			var children := card.get_children()
			if children.size() >= 2:
				var cb: ProgressBar = children[1]
				cb.value = unit.atb_value * 100.0

func _on_action_requested(unit: Unit) -> void:
	_current_unit = unit
	_selected_skill = null
	_show_skills(unit)
	target_hint.text = "请选择技能"

func _show_skills(unit: Unit) -> void:
	for child in skill_bar.get_children():
		child.queue_free()
	for skill_data in unit.data.skills:
		var btn := Button.new()
		btn.text = skill_data.skill_name
		var sd: SkillData = skill_data
		var cd: int = unit.skill_cooldowns.get(sd.id, 0)
		if cd > 0:
			btn.text = "%s (%d)" % [sd.skill_name, cd]
			btn.disabled = true
		btn.pressed.connect(_on_skill_selected.bind(sd))
		skill_bar.add_child(btn)

func _on_skill_selected(skill: SkillData) -> void:
	_selected_skill = skill
	target_hint.text = "请选择目标"
	_enable_target_selection()

func _enable_target_selection() -> void:
	var targets: Array[Unit] = battle_manager.enemy_units if _current_unit.is_player_unit else battle_manager.player_units
	for target in targets:
		if target.is_alive and _unit_cards.has(target):
			var card: HBoxContainer = _unit_cards[target]
			card.gui_input.connect(_on_target_clicked.bind(target))

func _on_target_clicked(event: InputEvent, target: Unit) -> void:
	if event is InputEventMouseButton and event.pressed:
		if _current_unit and _selected_skill:
			battle_manager.player_select_action(_current_unit, _selected_skill, [target])
			target_hint.text = ""

func _on_action_completed(unit: Unit) -> void:
	_current_unit = null
	_selected_skill = null
	for child in skill_bar.get_children():
		child.queue_free()
	target_hint.text = ""

func _on_damage_dealt(source: Unit, target: Unit, amount: float, is_crit: bool) -> void:
	if _unit_cards.has(target):
		var card: HBoxContainer = _unit_cards[target]
		var dmg_label := Label.new()
		dmg_label.set_script(load("res://scripts/ui/damage_number.gd"))
		card.add_child(dmg_label)
		dmg_label.show_damage(amount, is_crit)
