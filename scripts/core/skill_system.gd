# scripts/core/skill_system.gd
extends Node
class_name SkillSystem

signal skill_executed(unit: Unit, skill: SkillData, targets: Array[Unit])

var damage_system: DamageSystem
var buff_system: BuffSystem
var atb_system: ATBSystem

func execute(unit: Unit, skill: SkillData, targets: Array[Unit]) -> void:
	for effect in skill.effects:
		match effect.effect_type:
			Enums.SkillEffectType.DAMAGE:
				for target in targets:
					if not target.is_alive:
						continue
					for i in range(skill.multihit):
						damage_system.deal_damage(unit, target, effect)
			Enums.SkillEffectType.HEAL:
				for target in targets:
					if not target.is_alive:
						continue
					damage_system.apply_heal(unit, target, effect)
			Enums.SkillEffectType.APPLY_BUFF:
				if effect.buff_data != null:
					for target in targets:
						if not target.is_alive:
							continue
						buff_system.apply_buff(target, effect.buff_data, unit)
			Enums.SkillEffectType.DISPEL_BUFF:
				for target in targets:
					buff_system.dispel_buffs(target, effect.dispel_count)
			Enums.SkillEffectType.MODIFY_ATB:
				for target in targets:
					atb_system.modify_atb(target, effect.atb_modify)
	if skill.cooldown > 0:
		unit.set_cooldown(skill.id, skill.cooldown)
	skill_executed.emit(unit, skill, targets)
