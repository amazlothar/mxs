class_name TestData

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
