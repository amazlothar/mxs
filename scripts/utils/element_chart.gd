class_name ElementChart
extends RefCounted

const _ADVANTAGE: Dictionary = {
	Enums.Element.FIRE: Enums.Element.WIND,
	Enums.Element.WIND: Enums.Element.WATER,
	Enums.Element.WATER: Enums.Element.FIRE,
	Enums.Element.LIGHT: Enums.Element.DARK,
	Enums.Element.DARK: Enums.Element.LIGHT,
}

const ADVANTAGE_MULTIPLIER: float = 1.2
const DISADVANTAGE_MULTIPLIER: float = 0.8
const NEUTRAL_MULTIPLIER: float = 1.0

static func get_multiplier(attacker: Enums.Element, defender: Enums.Element) -> float:
	if _ADVANTAGE.has(attacker) and _ADVANTAGE[attacker] == defender:
		return ADVANTAGE_MULTIPLIER
	if _ADVANTAGE.has(defender) and _ADVANTAGE[defender] == attacker:
		return DISADVANTAGE_MULTIPLIER
	return NEUTRAL_MULTIPLIER
