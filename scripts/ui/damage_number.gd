extends Label

var _timer: float = 1.0

func show_damage(amount: float, is_crit: bool) -> void:
	text = str(int(amount))
	if is_crit:
		text = "暴击! " + text
		add_theme_color_override("font_color", Color.YELLOW)
	else:
		add_theme_color_override("font_color", Color.WHITE)
	_timer = 1.0

func _process(delta: float) -> void:
	_timer -= delta
	position.y -= 30.0 * delta
	if _timer <= 0.0:
		queue_free()
