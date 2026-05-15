extends Node

func get_ending(ending_id):
	var ending := DataRegistry.get_ending(ending_id)
	if ending.is_empty():
		return {
			"id": ending_id,
			"title": "미기록 엔딩",
			"grade": "C",
			"description": "이 삶은 아직 정리되지 않은 결말로 남았다.",
		}
	return ending

func evaluate_current_ending():
	var total := GameState.get_total_asset_value()
	if GameState.health <= 0:
		return get_ending("health_collapse")
	if GameState.mental <= 0:
		return get_ending("mental_burnout")
	if total >= 2_000_000_000:
		return get_ending("gangnam_dream")
	if total >= 500_000_000:
		return get_ending("upper_middle")
	if GameState.money < -30_000_000:
		return get_ending("debt_spiral")
	return get_ending("ordinary_retirement")

func get_score():
	return int(GameState.get_total_asset_value() / 100_000.0) + GameState.turn * 10 + GameState.reputation * 100
