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
