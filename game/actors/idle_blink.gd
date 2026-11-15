class_name IdleBlink
extends RefCounted
## Column 1 is a brief eyelid closure, not half of a two-frame idle loop.

const PERIOD := 4.0
const CLOSED_SECONDS := 0.12

static func frame(elapsed: float, identity: String = "founder") -> int:
	var phase := 0.0
	match identity:
		"mira": phase = 0.75
		"theo": phase = 1.5
		"creative": phase = 2.25
	return int(fposmod(elapsed + phase, PERIOD) >= PERIOD - CLOSED_SECONDS)
