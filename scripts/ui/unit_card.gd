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
