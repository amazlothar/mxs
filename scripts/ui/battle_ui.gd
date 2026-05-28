extends Control

@onready var enemy_container: HBoxContainer = $MarginContainer/VBoxContainer/EnemyContainer
@onready var player_container: HBoxContainer = $MarginContainer/VBoxContainer/PlayerContainer
@onready var atb_bar_container: HBoxContainer = $MarginContainer/VBoxContainer/ATBBar
@onready var skill_bar: HBoxContainer = $MarginContainer/VBoxContainer/SkillBar
@onready var target_hint: Label = $MarginContainer/VBoxContainer/TargetHint

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

func _create_unit_card(unit: Unit) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(180, 100)

	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 4)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	name_label.text = "%s [%s]" % [unit.data.unit_name, _element_short(unit.data.element)]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var charge_bar := ProgressBar.new()
	charge_bar.custom_minimum_size = Vector2(150, 10)
	charge_bar.max_value = 100.0
	charge_bar.value = 0.0
	charge_bar.show_percentage = false
	if unit.is_player_unit:
		charge_bar.modulate = Color(0.3, 0.6, 1.0)
	else:
		charge_bar.modulate = Color(1.0, 0.3, 0.3)

	var hp_bar := ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(150, 14)
	hp_bar.max_value = unit.max_hp
	hp_bar.value = unit.current_hp
	hp_bar.show_percentage = false
	hp_bar.modulate = Color(0.2, 0.8, 0.2)

	var hp_label := Label.new()
	hp_label.text = "%d / %d" % [int(unit.current_hp), int(unit.max_hp)]
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	card.add_child(name_label)
	card.add_child(charge_bar)
	card.add_child(hp_bar)
	card.add_child(hp_label)
	panel.add_child(card)
	_bind_card(unit, hp_bar, hp_label)
	return panel

func _element_short(element: int) -> String:
	match element:
		Enums.Element.FIRE: return "火"
		Enums.Element.WATER: return "水"
		Enums.Element.WIND: return "风"
		Enums.Element.LIGHT: return "光"
		Enums.Element.DARK: return "暗"
		_: return "?"

func _bind_card(unit: Unit, hp_bar: ProgressBar, hp_label: Label) -> void:
	unit.hp_changed.connect(func(_u, _old_hp, new_hp):
		hp_bar.value = new_hp
		hp_label.text = "%d / %d" % [int(new_hp), int(unit.max_hp)]
	)

func _process(_delta: float) -> void:
	for unit in _unit_cards:
		var panel: PanelContainer = _unit_cards[unit]
		if not panel or not panel.is_inside_tree():
			continue
		var card: VBoxContainer = panel.get_child(0)
		if not card:
			continue
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
		btn.custom_minimum_size = Vector2(140, 45)
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
			var card: PanelContainer = _unit_cards[target]
			if not card.gui_input.is_connected(_on_target_clicked.bind(target)):
				card.gui_input.connect(_on_target_clicked.bind(target))

func _on_target_clicked(event: InputEvent, target: Unit) -> void:
	if event is InputEventMouseButton and event.pressed:
		if _current_unit and _selected_skill:
			battle_manager.player_select_action(_current_unit, _selected_skill, [target])
			target_hint.text = ""

func _on_action_completed(_unit: Unit) -> void:
	_current_unit = null
	_selected_skill = null
	for child in skill_bar.get_children():
		child.queue_free()
	target_hint.text = ""

func _on_damage_dealt(_source: Unit, target: Unit, amount: float, is_crit: bool) -> void:
	if _unit_cards.has(target):
		var panel: PanelContainer = _unit_cards[target]
		var dmg_label := Label.new()
		dmg_label.set_script(load("res://scripts/ui/damage_number.gd"))
		panel.add_child(dmg_label)
		dmg_label.show_damage(amount, is_crit)
