extends Node2D

@onready var battle_manager: BattleManager = $BattleManager
@onready var battle_ui: Control = $BattleUI

func _ready() -> void:
	battle_ui.setup(battle_manager)
	var warrior_data := TestData.create_test_warrior()
	var support_data := TestData.create_test_support()
	var enemy_data := TestData.create_test_enemy()
	battle_manager.start_battle([warrior_data, support_data], [enemy_data, TestData.create_test_enemy()])
	battle_ui.create_unit_cards(battle_manager.player_units, battle_ui.player_container)
	battle_ui.create_unit_cards(battle_manager.enemy_units, battle_ui.enemy_container)
