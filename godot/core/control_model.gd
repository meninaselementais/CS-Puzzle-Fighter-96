extends RefCounted

const FRAMES_PER_SECOND: float = 8000000.0 / (512 * 262)

var directions: Array[int] = [0,0]
var horizontal_frames: Array[int] = [0,0]
var down_frames: Array[int] = [1,1]
var down_timer: Array[int] = [0,0]

func horizontal(player: int, direction: int) -> bool:
	assert(direction in [-1,0,1])
	if direction != directions[player]:
		directions[player] = direction
		horizontal_frames[player] = 0
		return direction != 0
	if direction == 0: return false
	horizontal_frames[player] += 1
	return horizontal_frames[player] >= 12

func reset_pair(player: int) -> void:
	down_frames[player] = 1
	down_timer[player] = 0

func drop(player: int, pressed: bool, pair_age: int = 100) -> bool:
	if not pressed or pair_age <= 16: return false
	down_frames[player] += 1
	down_timer[player] += 1
	var interval := 4 if down_frames[player] < 6 else 2 if down_frames[player] < 12 else 1
	if down_timer[player] < interval: return false
	down_timer[player] = 0
	return true
