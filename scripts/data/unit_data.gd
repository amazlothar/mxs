class_name UnitData
extends Resource

@export var id: String = ""
@export var unit_name: String = ""
@export var element: Enums.Element = Enums.Element.FIRE
@export var unit_type: Enums.UnitType = Enums.UnitType.ATTACK
@export var base_stats: Dictionary = {
	Enums.StatType.HP: 100.0,
	Enums.StatType.ATK: 50.0,
	Enums.StatType.DEF: 30.0,
	Enums.StatType.SPD: 100.0,
	Enums.StatType.ACC: 0.0,
	Enums.StatType.RES: 0.0,
	Enums.StatType.CRI_RATE: 15.0,
	Enums.StatType.CRI_DMG: 50.0,
}
@export var skills: Array[SkillData] = []
