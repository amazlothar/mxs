# scripts/core/buff_system.gd
extends Node
class_name BuffSystem

signal buff_applied(unit: Unit, buff: BuffInstance)
signal buff_removed(unit: Unit, buff: BuffInstance)
signal buff_stack_changed(unit: Unit, buff: BuffInstance, new_count: int)
signal buff_ticked(unit: Unit, buff: BuffInstance)
signal unit_buffs_changed(unit: Unit)

func apply_buff(target: Unit, buff_data: BuffData, source: Unit = null) -> BuffInstance:
	var existing: BuffInstance = _find_by_mutex_group(target, buff_data.mutex_group)
	if existing:
		_remove_buff_internal(target, existing)

	var existing_same: BuffInstance = _find_by_id(target, buff_data.id)
	if existing_same:
		match buff_data.stack_strategy:
			Enums.BuffStackStrategy.REFRESH_DURATION:
				existing_same.refresh_duration()
				buff_stack_changed.emit(target, existing_same, existing_same.current_stacks)
				return existing_same
			Enums.BuffStackStrategy.ADD_STACK:
				if existing_same.current_stacks < buff_data.max_stacks:
					existing_same.add_stack()
				existing_same.refresh_duration()
				buff_stack_changed.emit(target, existing_same, existing_same.current_stacks)
				return existing_same
			Enums.BuffStackStrategy.REPLACE:
				_remove_buff_internal(target, existing_same)

	var instance: BuffInstance = BuffInstance.new(buff_data, source)
	target.buff_container.append(instance)
	buff_applied.emit(target, instance)
	_recalc_stat_modifiers(target)
	unit_buffs_changed.emit(target)
	return instance

func dispel_buffs(target: Unit, count: int) -> void:
	var dispellable: Array[BuffInstance] = []
	for b in target.buff_container:
		if b.data.dispellable:
			dispellable.append(b)
	dispellable.sort_custom(func(a, b): return a.data.priority < b.data.priority)
	var to_remove: int = mini(count, dispellable.size())
	for i in range(to_remove):
		remove_buff(target, dispellable[i])

func remove_buff(target: Unit, buff: BuffInstance) -> void:
	_remove_buff_internal(target, buff)

func tick_buffs(unit: Unit) -> void:
	var to_remove: Array[BuffInstance] = []
	for b in unit.buff_container:
		match b.data.effect_type:
			Enums.BuffEffectType.DOT, Enums.BuffEffectType.HOT:
				buff_ticked.emit(unit, b)
		b.tick()
		if b.is_expired():
			to_remove.append(b)
	for b in to_remove:
		_remove_buff_internal(unit, b)

func get_stat_modifier(unit: Unit, stat_type: int) -> float:
	var total: float = 0.0
	for b in unit.buff_container:
		if b.data.effect_type == Enums.BuffEffectType.STAT_MODIFY:
			if b.data.effect_params.has("stat_type") and b.data.effect_params["stat_type"] == stat_type:
				var per_stack: float = b.data.effect_params.get("value", 0.0)
				total += per_stack * b.current_stacks
	return total

func _remove_buff_internal(target: Unit, buff: BuffInstance) -> void:
	target.buff_container.erase(buff)
	buff_removed.emit(target, buff)
	_recalc_stat_modifiers(target)
	unit_buffs_changed.emit(target)

func _find_by_mutex_group(unit: Unit, group: String) -> BuffInstance:
	if group == "":
		return null
	for b in unit.buff_container:
		if b.data.mutex_group == group:
			return b
	return null

func _find_by_id(unit: Unit, buff_id: String) -> BuffInstance:
	for b in unit.buff_container:
		if b.data.id == buff_id:
			return b
	return null

func _recalc_stat_modifiers(unit: Unit) -> void:
	var modifiers: Dictionary = {}
	for st in Enums.StatType.values():
		modifiers[st] = 0.0
	for b in unit.buff_container:
		if b.data.effect_type == Enums.BuffEffectType.STAT_MODIFY:
			if b.data.effect_params.has("stat_type"):
				var st: int = b.data.effect_params["stat_type"]
				var val: float = b.data.effect_params.get("value", 0.0)
				modifiers[st] = modifiers.get(st, 0.0) + val * b.current_stacks
	for st in modifiers:
		var base: float = unit.data.base_stats.get(st, 0.0)
		var equip_val: float = _get_equip_stat_total(unit, st)
		unit.set_stat(st, base + equip_val + modifiers[st])

func _get_equip_stat_total(unit: Unit, stat_type: int) -> float:
	var total: float = 0.0
	for equip in unit.equip_slots.values():
		if equip.main_stat.get("stat_type") == stat_type:
			total += equip.main_stat.get("value", 0.0)
		for sub in equip.sub_stats:
			if sub.get("stat_type") == stat_type:
				total += sub.get("value", 0.0)
	return total
