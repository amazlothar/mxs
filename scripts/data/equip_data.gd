class_name EquipData
extends Resource

@export var id: String = ""
@export var equip_name: String = ""
@export var description: String = ""
@export var slot: Enums.EquipSlot = Enums.EquipSlot.WEAPON
@export var set_type: String = ""
@export var main_stat: Dictionary = { "stat_type": Enums.StatType.ATK, "value": 10.0 }
@export var sub_stats: Array[Dictionary] = []
