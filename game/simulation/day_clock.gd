class_name DayClock
extends Node

signal time_changed(day: int, minute_of_day: int, phase: String, speed: float)

const MINUTES_PER_DAY := 24 * 60
const WORK_START := 8 * 60
const LUNCH_START := 12 * 60 + 30
const LUNCH_END := 13 * 60 + 30
const WORK_END := 17 * 60 + 30

var day: int = 1
var minute_of_day: int = WORK_START
var speed: float = 1.0
var phase: String = "work"
var _minute_fraction: float = 0.0
var ui_paused := false
var stop_at_close := true

func _ready() -> void:
	phase = phase_for_minute(minute_of_day)

func _process(delta: float) -> void:
	if speed <= 0.0 or ui_paused or (stop_at_close and minute_of_day >= WORK_END):
		return
	_minute_fraction += delta * speed
	var whole_minutes := int(floor(_minute_fraction))
	if whole_minutes <= 0:
		return
	_minute_fraction -= float(whole_minutes)
	advance_minutes(mini(whole_minutes, WORK_END - minute_of_day) if stop_at_close else whole_minutes)

func restore(restored_day: int, restored_minute: int, restored_speed: float) -> void:
	day = maxi(1, restored_day)
	minute_of_day = clampi(restored_minute, 0, MINUTES_PER_DAY - 1)
	speed = clampf(restored_speed, 0.0, 64.0)
	_minute_fraction = 0.0
	phase = phase_for_minute(minute_of_day)
	time_changed.emit(day, minute_of_day, phase, speed)

func set_speed(new_speed: float) -> void:
	speed = clampf(new_speed, 0.0, 64.0)
	time_changed.emit(day, minute_of_day, phase, speed)

func set_time(new_day: int, new_minute: int) -> void:
	restore(new_day, new_minute, speed)

func advance_minutes(amount: int) -> void:
	if amount <= 0:
		return
	var absolute := minute_of_day + amount
	day += absolute / MINUTES_PER_DAY
	minute_of_day = absolute % MINUTES_PER_DAY
	phase = phase_for_minute(minute_of_day)
	time_changed.emit(day, minute_of_day, phase, speed)

func formatted_time() -> String:
	return "%02d:%02d" % [minute_of_day / 60, minute_of_day % 60]

static func phase_for_minute(minute: int) -> String:
	var normalized := clampi(minute, 0, MINUTES_PER_DAY - 1)
	if normalized >= LUNCH_START and normalized < LUNCH_END:
		return "lunch"
	if (normalized >= WORK_START and normalized < LUNCH_START) or (normalized >= LUNCH_END and normalized < WORK_END):
		return "work"
	return "off"
