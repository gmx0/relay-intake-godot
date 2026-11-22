extends Node2D

const GAP_LIMIT := 6
const STRIKE_LIMIT := 3
const FILES := [
	["Lark / calibration", 6, false, true, true],
	["Lark / calibration", 7, false, true, true],
	["Mica / day watch", 7, true, true, true],
	["Sable / night watch", 7, true, false, true],
	["Fennel / dish crew", 2, false, true, false],
	["Kite / spare crew", 4, false, true, true],
	["Rue / polar watch", 10, false, false, true],
	["Copper / uplink", 9, true, true, true],
]

const BG := Color("#09151b")
const PANEL := Color("#14262e")
const LINE := Color("#294651")
const INK := Color("#e5f1eb")
const MUTE := Color("#9cbbc1")
const MINT := Color("#80eed2")
const ROSE := Color("#ffad96")
const GOLD := Color("#f3cf86")

enum Phase { REVIEW, FEEDBACK, COMPLETE, LOCKOUT }
var phase := Phase.REVIEW
var processed := 0
var advanced := 0
var rejected := 0
var strikes := 0
var audit: Array[bool] = []
var feedback := PackedStringArray()
var accept_button: Button
var return_button: Button
var next_button: Button
var restart_button: Button
var font := ThemeDB.fallback_font

func _ready() -> void:
	accept_button = make_button("A   Advance", Rect2(50, 622, 230, 54), MINT,
		func(): stamp(true))
	return_button = make_button("R   Return", Rect2(294, 622, 230, 54), ROSE,
		func(): stamp(false))
	next_button = make_button("Enter   Next file", Rect2(50, 622, 248, 54), GOLD, next_file)
	restart_button = make_button("F2   Restart shift", Rect2(890, 622, 180, 54), MUTE, restart)
	refresh()
	if "--smoke-test" in OS.get_cmdline_user_args():
		call_deferred("smoke_test")

func make_button(label: String, rect: Rect2, color: Color, action: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.position = rect.position
	b.size = rect.size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 19)
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = PANEL.lerp(color, 0.19 if state != "normal" else 0.08)
		style.border_color = color
		style.set_border_width_all(1)
		style.set_corner_radius_all(6)
		b.add_theme_stylebox_override(state, style)
	for key in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(key, color)
	add_child(b)
	b.pressed.connect(action)
	return b

func violations(file: Array) -> PackedStringArray:
	var issues := PackedStringArray()
	if file[1] > GAP_LIMIT and not file[2]:
		issues.append("Gap over %d cycles: stamp missing." % GAP_LIMIT)
	if not file[3]:
		issues.append("Relay credential is not current.")
	if not file[4]:
		issues.append("Callsign check is not signed.")
	return issues

func stamp(approve: bool) -> void:
	if phase != Phase.REVIEW:
		return
	var issues := violations(FILES[processed])
	var should_advance := issues.is_empty()
	var compliant := approve == should_advance
	if approve:
		advanced += 1
	else:
		rejected += 1
	if not compliant:
		strikes += 1
	audit.append(compliant)
	processed += 1
	feedback = PackedStringArray([
		("CORRECT" if compliant else "AUDIT STRIKE") + " / " + ("ADVANCED" if approve else "RETURNED"),
		"Advance: all three checks passed." if should_advance else "Return: see failed checks."
	])
	feedback.append_array(issues)
	if strikes >= STRIKE_LIMIT:
		phase = Phase.LOCKOUT
	elif processed == FILES.size():
		phase = Phase.COMPLETE
	else:
		phase = Phase.FEEDBACK
	refresh()

func next_file() -> void:
	if phase != Phase.FEEDBACK:
		return
	phase = Phase.REVIEW
	feedback.clear()
	refresh()

func restart() -> void:
	phase = Phase.REVIEW
	processed = 0
	advanced = 0
	rejected = 0
	strikes = 0
	audit.clear()
	feedback.clear()
	refresh()

func refresh() -> void:
	accept_button.visible = phase == Phase.REVIEW
	return_button.visible = phase == Phase.REVIEW
	next_button.visible = phase == Phase.FEEDBACK
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_A: stamp(true)
		KEY_R: stamp(false)
		KEY_ENTER, KEY_KP_ENTER: next_file()
		KEY_F2: restart()
		_: return
	get_viewport().set_input_as_handled()

func txt(at: Vector2, value: String, px: int, color: Color = INK) -> void:
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)

func card(rect: Rect2) -> void:
	draw_rect(rect, PANEL)
	draw_rect(rect, LINE, false, 1.0)

func mark(at: Vector2, yes: bool, good: String, bad: String) -> void:
	txt(at, good if yes else bad, 20, MINT if yes else GOLD)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1120, 720), BG)
	# Original instrument-panel illustration; no external art assets.
	for i in range(21):
		var h := 6.0 + 25.0 * absf(sin(float(i) * 0.77) * sin(float(i) * 0.2))
		draw_rect(Rect2(920 + i * 7, 71 - h, 3, h), LINE if i % 3 else MINT.darkened(0.45))
	txt(Vector2(50, 52), "SELENE ARRAY     /     GATE 05     /     NIGHT OPERATIONS", 15, MINT)
	txt(Vector2(47, 109), "Relay Intake", 50)
	txt(Vector2(50, 142), "Review eight fictional crew files before three audit strikes close the desk.", 19, MUTE)

	card(Rect2(50, 174, 645, 326))
	card(Rect2(719, 174, 351, 326))
	txt(Vector2(744, 209), "INTAKE RULE CARD", 16, MINT)
	txt(Vector2(744, 251), "01   Relay credential must be current.", 17)
	txt(Vector2(744, 286), "02   Callsign check must be signed.", 17)
	txt(Vector2(744, 321), "03   Gap over %d cycles requires" % GAP_LIMIT, 17)
	txt(Vector2(780, 349), "a renewal stamp.", 17)
	draw_line(Vector2(744, 377), Vector2(1042, 377), LINE, 1.0)
	txt(Vector2(744, 413), "Advance if all requirements pass.", 17, MINT)
	txt(Vector2(744, 451), "Otherwise, return the file.", 17, ROSE)

	var shown := clampi(processed if phase == Phase.REVIEW else processed - 1, 0, FILES.size() - 1)
	var file: Array = FILES[shown]
	var caption := "FILE %02d / %02d" % [shown + 1, FILES.size()]
	if shown < 2:
		caption += "     /     CALIBRATION"
	txt(Vector2(76, 212), caption, 16, MINT)
	txt(Vector2(75, 259), file[0], 34)
	draw_line(Vector2(76, 279), Vector2(667, 279), LINE, 1.0)
	txt(Vector2(76, 321), "Relay-log gap", 20, MUTE)
	txt(Vector2(76, 360), "Renewal stamp", 20, MUTE)
	txt(Vector2(76, 399), "Relay credential", 20, MUTE)
	txt(Vector2(76, 438), "Callsign check", 20, MUTE)
	txt(Vector2(425, 321), "%d cycles" % file[1], 24)
	mark(Vector2(425, 360), file[2], "Present", "None")
	mark(Vector2(425, 399), file[3], "Current", "Expired")
	mark(Vector2(425, 438), file[4], "Signed", "Unsigned")

	txt(Vector2(50, 535), "SHIFT LEDGER", 15, MINT)
	var ledger := "%d / %d filed     %d advanced     %d returned     %d / %d strikes"
	txt(Vector2(50, 569), ledger % [processed, FILES.size(), advanced, rejected, strikes, STRIKE_LIMIT], 20)
	for i in range(FILES.size()):
		var rect := Rect2(51 + i * 32, 589, 24, 14)
		var tint := LINE
		if i < audit.size():
			tint = MINT if audit[i] else ROSE
		draw_rect(rect, tint)
		if i < audit.size():
			var stamp_text := "+" if audit[i] else "×"
			txt(rect.position + Vector2(8, 12), stamp_text, 13, BG)

	if phase != Phase.REVIEW:
		card(Rect2(719, 378, 351, 226))
		var tint := MINT if audit.back() else ROSE
		txt(Vector2(744, 412), feedback[0], 17, tint)
		for i in range(1, feedback.size()):
			txt(Vector2(744, 414 + i * 27), feedback[i], 15)
		if phase == Phase.LOCKOUT:
			txt(Vector2(744, 570), "DESK LOCKED / THREE STRIKES", 17, ROSE)
		elif phase == Phase.COMPLETE:
			txt(Vector2(744, 570), "SHIFT COMPLETE", 20, MINT)

func press(code: Key, held: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	event.echo = held
	get_viewport().push_input(event)

func click(at: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = at
	event.pressed = true
	get_viewport().push_input(event, true)
	event.pressed = false
	get_viewport().push_input(event, true)

func smoke_test() -> void:
	# The same keyboard/mouse dispatcher runs inside exported packs.
	await get_tree().process_frame
	var clears := [true, false, true, false, false, true, false, true]
	var errors := PackedStringArray()
	for i in range(clears.size()):
		if i == 0:
			click(Vector2(165, 648))
			press(KEY_R) # Rapid click plus key must not stamp twice.
		else:
			press(KEY_A if clears[i] else KEY_R)
		if processed != i + 1 or processed != advanced + rejected or strikes != 0:
			errors.append("Bad boundary, double input or ledger on file %d." % (i + 1))
		if feedback.is_empty() or not feedback[0].begins_with("CORRECT"):
			errors.append("Feedback missing on file %d." % (i + 1))
		elif i == 1 and not feedback.has("Gap over %d cycles: stamp missing." % GAP_LIMIT):
			errors.append("Correct return omitted the deciding rule.")
		elif i == 3 and not feedback.has("Relay credential is not current."):
			errors.append("Stamp bypassed credential or lost its explanation.")
		elif i == 6 and feedback.size() != 4:
			errors.append("Multi-violation return must list both missing checks.")
		for line in feedback:
			if font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x > 302:
				errors.append("Audit text exceeds its card.")
		if i < clears.size() - 1:
			if i == 0:
				click(Vector2(165, 648))
			else:
				press(KEY_ENTER)
			if phase != Phase.REVIEW or not feedback.is_empty():
				errors.append("Next file must clear feedback.")
	if phase != Phase.COMPLETE or advanced != 4 or rejected != 4:
		errors.append("Clean shift failed.")
	press(KEY_A)
	if processed != FILES.size():
		errors.append("Complete shift accepted another file.")
	press(KEY_F2)
	for i in range(3):
		press(KEY_R if clears[i] else KEY_A)
		if strikes != i + 1:
			errors.append("Incorrect decision must add exactly one strike.")
		press(KEY_ENTER)
	press(KEY_A)
	if phase != Phase.LOCKOUT or processed != 3 or strikes != 3:
		errors.append("Third-strike lockout failed.")
	press(KEY_F2)
	press(KEY_A, true)
	if processed != 0:
		errors.append("Held key admitted a decision.")
	press(KEY_A)
	if phase != Phase.FEEDBACK:
		errors.append("Restart did not return to first file.")
	click(Vector2(980, 648))
	await get_tree().process_frame
	if phase != Phase.REVIEW or processed != 0 or strikes != 0 or advanced != 0 or rejected != 0 or not audit.is_empty():
		errors.append("Click restart did not clear feedback or the ledger.")
	if errors.is_empty():
		print("RELAY INTAKE SMOKE PASSED: six/seven boundary, stamp limits, clear audit, mixed input, full shift, lockout, restart")
	else:
		for error in errors:
			push_error(error)
	get_tree().quit(0 if errors.is_empty() else 1)
