extends RefCounted
## Teclado, D-pad e analógico usam a mesma validação de equipe.
var held_axes: Dictionary = {}

func decode(event: InputEvent) -> Dictionary:
	var player: int = 0
	var command: String = ""
	var direction: Vector2i = Vector2i.ZERO
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if not key_event.pressed or key_event.echo: return {}
		var code: int = key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
		player = 1 if code in [KEY_A,KEY_D,KEY_W,KEY_S,KEY_Q,KEY_E] else 0
		match code:
			KEY_LEFT, KEY_A: direction = Vector2i.LEFT
			KEY_RIGHT, KEY_D: direction = Vector2i.RIGHT
			KEY_UP, KEY_W: direction = Vector2i.UP
			KEY_DOWN, KEY_S: direction = Vector2i.DOWN
			KEY_Z, KEY_Q: command = "confirm"
			KEY_X, KEY_E: command = "cancel"
			KEY_ENTER, KEY_SPACE: command = "skip"
			KEY_ESCAPE: command = "menu"
	elif event is InputEventJoypadButton:
		var button: InputEventJoypadButton = event as InputEventJoypadButton
		if not button.pressed or button.device < 0 or button.device > 1: return {}
		player = button.device
		match button.button_index:
			JOY_BUTTON_DPAD_LEFT: direction = Vector2i.LEFT
			JOY_BUTTON_DPAD_RIGHT: direction = Vector2i.RIGHT
			JOY_BUTTON_DPAD_UP: direction = Vector2i.UP
			JOY_BUTTON_DPAD_DOWN: direction = Vector2i.DOWN
			JOY_BUTTON_A: command = "confirm"
			JOY_BUTTON_B: command = "cancel"
			JOY_BUTTON_START: command = "menu"
	elif event is InputEventJoypadMotion:
		var motion: InputEventJoypadMotion = event as InputEventJoypadMotion
		if motion.device < 0 or motion.device > 1 or motion.axis not in [JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y]: return {}
		var axis_key: String = "%d/%d" % [motion.device,motion.axis]
		if absf(motion.axis_value) < 0.3:
			held_axes.erase(axis_key)
			return {}
		if absf(motion.axis_value) < 0.55: return {}
		var axis_sign: int = 1 if motion.axis_value > 0 else -1
		if held_axes.get(axis_key,0) == axis_sign: return {}
		held_axes[axis_key] = axis_sign
		player = motion.device
		direction = Vector2i(axis_sign,0) if motion.axis == JOY_AXIS_LEFT_X else Vector2i(0,axis_sign)
	if direction != Vector2i.ZERO: command = "move"
	if command.is_empty(): return {}
	return {"player":player,"command":command,"direction":direction}
