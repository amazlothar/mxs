extends Node
class_name ATBSystem

signal unit_ready(unit: Unit)

const BASE_CHARGE_RATE: float = 0.6
const SPD_REFERENCE: float = 100.0

var _units: Array[Unit] = []
var _is_paused: bool = false
var _ready_queue: Array[Unit] = []

func add_unit(unit: Unit) -> void:
	if not _units.has(unit):
		_units.append(unit)

func remove_unit(unit: Unit) -> void:
	_units.erase(unit)
	_ready_queue.erase(unit)

func pause() -> void:
	_is_paused = true

func resume() -> void:
	_is_paused = false
	print("[ATB] resume, queue=%d" % _ready_queue.size())
	if _ready_queue.size() > 0:
		_emit_next()

func reset_unit(unit: Unit) -> void:
	unit.atb_value = 0.0

func modify_atb(unit: Unit, percentage: float) -> void:
	unit.atb_value = clampf(unit.atb_value + percentage, 0.0, 1.0)

func _process(delta: float) -> void:
	if _is_paused:
		return
	for unit in _units:
		if not unit.is_alive:
			continue
		if unit.atb_value >= 1.0:
			if not _ready_queue.has(unit):
				_ready_queue.append(unit)
			continue
		var spd: float = unit.get_stat(Enums.StatType.SPD)
		var increment: float = BASE_CHARGE_RATE * (spd / SPD_REFERENCE) * delta
		unit.atb_value = minf(1.0, unit.atb_value + increment)
		if unit.atb_value >= 1.0:
			if not _ready_queue.has(unit):
				_ready_queue.append(unit)
	if _ready_queue.size() > 0:
		_is_paused = true
		_ready_queue.sort_custom(func(a, b): return a.get_stat(Enums.StatType.SPD) > b.get_stat(Enums.StatType.SPD))
		_emit_next()

func _emit_next() -> void:
	while _ready_queue.size() > 0:
		var unit: Unit = _ready_queue.pop_front()
		if unit.is_alive:
			_is_paused = true
			unit_ready.emit(unit)
			return
	if _ready_queue.size() == 0:
		_is_paused = false
