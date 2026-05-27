class_name TestData
extends RefCounted

static func create_atk_up_buff() -> BuffData:
	var buff := BuffData.new()
	buff.id = "atk_up"
	buff.buff_name = "攻击提升"
	buff.description = "攻击力提升"
	buff.effect_type = Enums.BuffEffectType.STAT_MODIFY
	buff.effect_params = {"stat_type": Enums.StatType.ATK, "value": 20.0}
	buff.max_stacks = 3
	buff.stack_strategy = Enums.BuffStackStrategy.ADD_STACK
	buff.duration = 3
	buff.priority = 5
	buff.dispellable = true
	return buff

static func create_poison_buff() -> BuffData:
	var buff := BuffData.new()
	buff.id = "poison"
	buff.buff_name = "中毒"
	buff.description = "每回合扣除体力"
	buff.effect_type = Enums.BuffEffectType.DOT
	buff.effect_params = {"damage_percent": 5.0}
	buff.max_stacks = 1
	buff.stack_strategy = Enums.BuffStackStrategy.REPLACE
	buff.duration = 3
	buff.priority = 3
	buff.dispellable = true
	return buff

static func create_stun_buff() -> BuffData:
	var buff := BuffData.new()
	buff.id = "stun"
	buff.buff_name = "眩晕"
	buff.description = "无法行动"
	buff.effect_type = Enums.BuffEffectType.CONTROL
	buff.effect_params = {}
	buff.max_stacks = 1
	buff.stack_strategy = Enums.BuffStackStrategy.REPLACE
	buff.mutex_group = "control"
	buff.duration = 1
	buff.priority = 10
	buff.dispellable = true
	return buff

static func create_normal_attack() -> SkillData:
	var effect := SkillEffect.new()
	effect.effect_type = Enums.SkillEffectType.DAMAGE
	effect.scaling_ratios = {"atk_ratio": 1.0, "hp_ratio": 0.0, "def_ratio": 0.0, "flat": 0.0}
	var skill := SkillData.new()
	skill.id = "normal_attack"
	skill.skill_name = "普攻"
	skill.skill_type = Enums.SkillType.NORMAL
	skill.cooldown = 0
	skill.multihit = 1
	skill.target_mode = Enums.TargetMode.SINGLE_ENEMY
	skill.effects = [effect]
	return skill

static func create_fire_slash() -> SkillData:
	var dmg_effect := SkillEffect.new()
	dmg_effect.effect_type = Enums.SkillEffectType.DAMAGE
	dmg_effect.scaling_ratios = {"atk_ratio": 2.5, "hp_ratio": 0.0, "def_ratio": 0.0, "flat": 0.0}
	var buff_effect := SkillEffect.new()
	buff_effect.effect_type = Enums.SkillEffectType.APPLY_BUFF
	buff_effect.buff_data = create_atk_up_buff()
	var skill := SkillData.new()
	skill.id = "fire_slash"
	skill.skill_name = "火焰斩"
	skill.description = "造成2.5倍攻击伤害，并提升自身攻击力"
	skill.skill_type = Enums.SkillType.ACTIVE
	skill.cooldown = 3
	skill.multihit = 2
	skill.target_mode = Enums.TargetMode.SINGLE_ENEMY
	skill.effects = [dmg_effect, buff_effect]
	return skill

static func create_heal_skill() -> SkillData:
	var effect := SkillEffect.new()
	effect.effect_type = Enums.SkillEffectType.HEAL
	effect.scaling_ratios = {"atk_ratio": 0.5, "hp_ratio": 0.1, "def_ratio": 0.0, "flat": 0.0}
	var skill := SkillData.new()
	skill.id = "heal"
	skill.skill_name = "治疗"
	skill.description = "恢复体力"
	skill.skill_type = Enums.SkillType.ACTIVE
	skill.cooldown = 2
	skill.multihit = 1
	skill.target_mode = Enums.TargetMode.SELF
	skill.effects = [effect]
	return skill

static func create_test_warrior() -> UnitData:
	var data := UnitData.new()
	data.id = "test_warrior"
	data.unit_name = "战士"
	data.element = Enums.Element.FIRE
	data.unit_type = Enums.UnitType.ATTACK
	data.base_stats = {
		Enums.StatType.HP: 500.0,
		Enums.StatType.ATK: 120.0,
		Enums.StatType.DEF: 40.0,
		Enums.StatType.SPD: 110.0,
		Enums.StatType.ACC: 0.0,
		Enums.StatType.RES: 0.0,
		Enums.StatType.CRI_RATE: 20.0,
		Enums.StatType.CRI_DMG: 50.0,
	}
	data.skills = [create_normal_attack(), create_fire_slash()]
	return data

static func create_test_enemy() -> UnitData:
	var data := UnitData.new()
	data.id = "test_enemy"
	data.unit_name = "史莱姆"
	data.element = Enums.Element.WATER
	data.unit_type = Enums.UnitType.HP
	data.base_stats = {
		Enums.StatType.HP: 800.0,
		Enums.StatType.ATK: 60.0,
		Enums.StatType.DEF: 50.0,
		Enums.StatType.SPD: 90.0,
		Enums.StatType.ACC: 0.0,
		Enums.StatType.RES: 15.0,
		Enums.StatType.CRI_RATE: 10.0,
		Enums.StatType.CRI_DMG: 50.0,
	}
	data.skills = [create_normal_attack()]
	return data

static func create_test_support() -> UnitData:
	var data := UnitData.new()
	data.id = "test_support"
	data.unit_name = "祭司"
	data.element = Enums.Element.WIND
	data.unit_type = Enums.UnitType.SUPPORT
	data.base_stats = {
		Enums.StatType.HP: 400.0,
		Enums.StatType.ATK: 80.0,
		Enums.StatType.DEF: 35.0,
		Enums.StatType.SPD: 100.0,
		Enums.StatType.ACC: 0.0,
		Enums.StatType.RES: 30.0,
		Enums.StatType.CRI_RATE: 10.0,
		Enums.StatType.CRI_DMG: 50.0,
	}
	data.skills = [create_normal_attack(), create_heal_skill()]
	return data

static func create_water_strike() -> SkillData:
	var effect := SkillEffect.new()
	effect.effect_type = Enums.SkillEffectType.DAMAGE
	effect.scaling_ratios = {"atk_ratio": 2.0, "hp_ratio": 0.0, "def_ratio": 0.0, "flat": 0.0}
	var skill := SkillData.new()
	skill.id = "water_strike"
	skill.skill_name = "水压冲击"
	skill.skill_type = Enums.SkillType.ACTIVE
	skill.cooldown = 2
	skill.multihit = 1
	skill.target_mode = Enums.TargetMode.SINGLE_ENEMY
	skill.effects = [effect]
	return skill

static func create_rock_smash() -> SkillData:
	var effect := SkillEffect.new()
	effect.effect_type = Enums.SkillEffectType.DAMAGE
	effect.scaling_ratios = {"atk_ratio": 0.3, "hp_ratio": 0.0, "def_ratio": 2.0, "flat": 0.0}
	var skill := SkillData.new()
	skill.id = "rock_smash"
	skill.skill_name = "岩碎"
	skill.skill_type = Enums.SkillType.ACTIVE
	skill.cooldown = 3
	skill.multihit = 1
	skill.target_mode = Enums.TargetMode.SINGLE_ENEMY
	skill.effects = [effect]
	return skill

static func create_earthquake() -> SkillData:
	var effect := SkillEffect.new()
	effect.effect_type = Enums.SkillEffectType.DAMAGE
	effect.scaling_ratios = {"atk_ratio": 0.3, "hp_ratio": 0.15, "def_ratio": 0.0, "flat": 0.0}
	var skill := SkillData.new()
	skill.id = "earthquake"
	skill.skill_name = "大地震击"
	skill.skill_type = Enums.SkillType.ACTIVE
	skill.cooldown = 4
	skill.multihit = 1
	skill.target_mode = Enums.TargetMode.ALL_ENEMY
	skill.effects = [effect]
	return skill

static func create_dark_bolt() -> SkillData:
	var effect := SkillEffect.new()
	effect.effect_type = Enums.SkillEffectType.DAMAGE
	effect.scaling_ratios = {"atk_ratio": 3.0, "hp_ratio": 0.0, "def_ratio": 0.0, "flat": 0.0}
	var skill := SkillData.new()
	skill.id = "dark_bolt"
	skill.skill_name = "暗影弹"
	skill.skill_type = Enums.SkillType.ACTIVE
	skill.cooldown = 3
	skill.multihit = 1
	skill.target_mode = Enums.TargetMode.SINGLE_ENEMY
	skill.effects = [effect]
	return skill

static func create_tank() -> UnitData:
	var data := UnitData.new()
	data.id = "tank"
	data.unit_name = "守护者"
	data.element = Enums.Element.FIRE
	data.unit_type = Enums.UnitType.DEFENSE
	data.base_stats = {
		Enums.StatType.HP: 700.0,
		Enums.StatType.ATK: 50.0,
		Enums.StatType.DEF: 80.0,
		Enums.StatType.SPD: 85.0,
		Enums.StatType.ACC: 0.0,
		Enums.StatType.RES: 20.0,
		Enums.StatType.CRI_RATE: 5.0,
		Enums.StatType.CRI_DMG: 50.0,
	}
	data.skills = [create_normal_attack(), create_rock_smash()]
	return data

static func create_bruiser() -> UnitData:
	var data := UnitData.new()
	data.id = "bruiser"
	data.unit_name = "巨人"
	data.element = Enums.Element.WIND
	data.unit_type = Enums.UnitType.HP
	data.base_stats = {
		Enums.StatType.HP: 900.0,
		Enums.StatType.ATK: 70.0,
		Enums.StatType.DEF: 45.0,
		Enums.StatType.SPD: 80.0,
		Enums.StatType.ACC: 0.0,
		Enums.StatType.RES: 10.0,
		Enums.StatType.CRI_RATE: 10.0,
		Enums.StatType.CRI_DMG: 50.0,
	}
	data.skills = [create_normal_attack(), create_earthquake()]
	return data

static func create_enemy_slime() -> UnitData:
	var data := UnitData.new()
	data.id = "enemy_slime"
	data.unit_name = "史莱姆"
	data.element = Enums.Element.WATER
	data.unit_type = Enums.UnitType.HP
	data.base_stats = {
		Enums.StatType.HP: 800.0,
		Enums.StatType.ATK: 60.0,
		Enums.StatType.DEF: 50.0,
		Enums.StatType.SPD: 90.0,
		Enums.StatType.ACC: 0.0,
		Enums.StatType.RES: 15.0,
		Enums.StatType.CRI_RATE: 10.0,
		Enums.StatType.CRI_DMG: 50.0,
	}
	data.skills = [create_normal_attack()]
	return data

static func create_enemy_goblin() -> UnitData:
	var data := UnitData.new()
	data.id = "enemy_goblin"
	data.unit_name = "哥布林"
	data.element = Enums.Element.WIND
	data.unit_type = Enums.UnitType.ATTACK
	data.base_stats = {
		Enums.StatType.HP: 350.0,
		Enums.StatType.ATK: 100.0,
		Enums.StatType.DEF: 25.0,
		Enums.StatType.SPD: 120.0,
		Enums.StatType.ACC: 10.0,
		Enums.StatType.RES: 0.0,
		Enums.StatType.CRI_RATE: 25.0,
		Enums.StatType.CRI_DMG: 60.0,
	}
	data.skills = [create_normal_attack(), create_water_strike()]
	return data

static func create_enemy_skeleton() -> UnitData:
	var data := UnitData.new()
	data.id = "enemy_skeleton"
	data.unit_name = "骷髅兵"
	data.element = Enums.Element.FIRE
	data.unit_type = Enums.UnitType.DEFENSE
	data.base_stats = {
		Enums.StatType.HP: 600.0,
		Enums.StatType.ATK: 55.0,
		Enums.StatType.DEF: 70.0,
		Enums.StatType.SPD: 75.0,
		Enums.StatType.ACC: 0.0,
		Enums.StatType.RES: 10.0,
		Enums.StatType.CRI_RATE: 5.0,
		Enums.StatType.CRI_DMG: 50.0,
	}
	data.skills = [create_normal_attack(), create_rock_smash()]
	return data

static func create_enemy_dark_mage() -> UnitData:
	var data := UnitData.new()
	data.id = "enemy_dark_mage"
	data.unit_name = "暗影法师"
	data.element = Enums.Element.DARK
	data.unit_type = Enums.UnitType.ATTACK
	data.base_stats = {
		Enums.StatType.HP: 300.0,
		Enums.StatType.ATK: 130.0,
		Enums.StatType.DEF: 20.0,
		Enums.StatType.SPD: 105.0,
		Enums.StatType.ACC: 20.0,
		Enums.StatType.RES: 10.0,
		Enums.StatType.CRI_RATE: 30.0,
		Enums.StatType.CRI_DMG: 70.0,
	}
	data.skills = [create_normal_attack(), create_dark_bolt()]
	return data
