extends TextureRect

var buff: BuffInstance: set = set_buff
@onready var stack_label: Label = $StackLabel

func set_buff(value: BuffInstance) -> void:
	buff = value
	if buff:
		stack_label.text = str(buff.current_stacks) if buff.current_stacks > 1 else ""
		tooltip_text = "%s (%d回合)" % [buff.data.buff_name, buff.remaining_duration]
