extends Node2D

@onready var battle_manager: BattleManager = $BattleManager
@onready var battle_ui: Control = $BattleUI

func _ready() -> void:
	battle_ui.setup(battle_manager)
	var player_team: Array[UnitData] = [
		TestData.create_test_warrior(),
		TestData.create_tank(),
		TestData.create_test_support(),
		TestData.create_bruiser(),
	]
	var enemy_team: Array[UnitData] = [
		TestData.create_enemy_slime(),
		TestData.create_enemy_goblin(),
		TestData.create_enemy_skeleton(),
		TestData.create_enemy_dark_mage(),
	]
	battle_manager.start_battle(player_team, enemy_team)
	battle_ui.create_unit_cards(battle_manager.player_units, battle_ui.player_container)
	battle_ui.create_unit_cards(battle_manager.enemy_units, battle_ui.enemy_container)
