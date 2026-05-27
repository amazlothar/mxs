class_name SkillEffect
extends Resource

@export var effect_type: Enums.SkillEffectType = Enums.SkillEffectType.DAMAGE
@export var scaling_ratios: Dictionary = {
	"atk_ratio": 1.0,
	"hp_ratio": 0.0,
	"def_ratio": 0.0,
	"flat": 0.0,
}
@export var buff_data: BuffData = null
@export var dispel_count: int = 0
@export var atb_modify: float = 0.0
