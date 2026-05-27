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
