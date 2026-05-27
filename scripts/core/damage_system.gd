# scripts/core/damage_system.gd
extends Node
class_name DamageSystem

signal damage_dealt(source: Unit, target: Unit, amount: float, is_crit: bool)
signal heal_applied(source: Unit, target: Unit, amount: float)
signal unit_died(unit: Unit)

const DEF_COEFFICIENT: float = 300.0
const BASE_HIT_RATE: float = 0.85
const HIT_COEFFICIENT: float = 0.005

var buff_system: BuffSystem

func calculate_raw_damage(source: Unit, scaling: Dictionary) -> float:
	var atk_ratio: float = scaling.get("atk_ratio", 0.0)
	var hp_ratio: float = scaling.get("hp_ratio", 0.0)
	var def_ratio: float = scaling.get("def_ratio", 0.0)
	var flat: float = scaling.get("flat", 0.0)
	return (source.get_stat(Enums.StatType.ATK) * atk_ratio
		+ source.get_stat(Enums.StatType.HP) * hp_ratio
		+ source.get_stat(Enums.StatType.DEF) * def_ratio
		+ flat)

func apply_defense(raw_damage: float, target_def: float) -> float:
	return raw_damage * (target_def / (target_def + DEF_COEFFICIENT))

func roll_crit(source: Unit) -> bool:
	var crit_rate: float = source.get_stat(Enums.StatType.CRI_RATE)
	return randf() < (crit_rate / 100.0)

func roll_hit(source: Unit, target: Unit) -> bool:
	var acc: float = source.get_stat(Enums.StatType.ACC)
	var res: float = target.get_stat(Enums.StatType.RES)
	var hit_rate: float = BASE_HIT_RATE + (acc - res) * HIT_COEFFICIENT
	return randf() < hit_rate

func deal_damage(source: Unit, target: Unit, effect: SkillEffect) -> Dictionary:
	var result: Dictionary = {"hit": false, "damage": 0.0, "is_crit": false}
	if not target.is_alive:
		return result
	if not roll_hit(source, target):
		return result
	result["hit"] = true
	var raw: float = calculate_raw_damage(source, effect.scaling_ratios)
	var after_def: float = raw - apply_defense(raw, target.get_stat(Enums.StatType.DEF))
	var elemental: float = after_def * ElementChart.get_multiplier(source.data.element, target.data.element)
	var is_crit: bool = roll_crit(source)
	result["is_crit"] = is_crit
	var crit_mult: float = 1.0
	if is_crit:
		crit_mult = 1.0 + source.get_stat(Enums.StatType.CRI_DMG) / 100.0
	var final_damage: float = maxf(1.0, elemental * crit_mult)
	result["damage"] = final_damage
	target.take_damage(final_damage)
	damage_dealt.emit(source, target, final_damage, is_crit)
	if not target.is_alive:
		unit_died.emit(target)
	return result

func apply_heal(source: Unit, target: Unit, effect: SkillEffect) -> float:
	var raw: float = calculate_raw_damage(source, effect.scaling_ratios)
	var heal_amount: float = maxf(0.0, raw)
	target.heal(heal_amount)
	heal_applied.emit(source, target, heal_amount)
	return heal_amount
