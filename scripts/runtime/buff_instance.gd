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
