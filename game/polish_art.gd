class_name PolishArt
extends RefCounted

const WORLD_VFX: Texture2D = preload("res://assets/runtime/effects/world-state-vfx.png")
const AMBIENT_OFFICE: Texture2D = preload("res://assets/runtime/effects/ambient-office.png")
const CHARACTER_SHADOWS: Texture2D = preload("res://assets/runtime/effects/character-shadows.png")
const OFFICE_UNLOCK: Texture2D = preload("res://assets/runtime/effects/office-unlock.png")
const LAYERED_FURNITURE: Texture2D = preload("res://assets/runtime/office/layered-furniture.png")

const EFFECT_ROWS: Dictionary = {
	&"thinking": 0,
	&"typing": 1,
	&"research": 2,
	&"approval": 3,
	&"completion": 4,
	&"failure": 5,
}

static func effect_region(kind: StringName, frame: int) -> Rect2:
	var row := int(EFFECT_ROWS.get(kind, 0))
	return Rect2(float(clampi(frame, 0, 3) * 24), float(row * 24), 24.0, 24.0)

static func ambient_region(row: int, frame: int) -> Rect2:
	return Rect2(float(clampi(frame, 0, 3) * 32), float(clampi(row, 0, 4) * 32), 32.0, 32.0)

static func shadow_region(kind: int) -> Rect2:
	return Rect2(float(clampi(kind, 0, 2) * 32), 0.0, 32.0, 16.0)

static func furniture_region(row: int, column: int) -> Rect2:
	return Rect2(float(clampi(column, 0, 1) * 128), float(clampi(row, 0, 1) * 96), 128.0, 96.0)

static func unlock_region(frame: int) -> Rect2:
	return Rect2(float(clampi(frame, 0, 5) * 64), 0.0, 64.0, 64.0)
