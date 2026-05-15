extends Node

const META_SAVE_PATH = "user://gangnam_dream_meta.json"

var data: Dictionary = {}

func _ready():
	load_meta()

func load_meta():
	data = DataRegistry.default_meta.duplicate(true)
	if FileAccess.file_exists(META_SAVE_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(META_SAVE_PATH))
		if parsed is Dictionary:
			data.merge(parsed, true)

func save_meta():
	var file = FileAccess.open(META_SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))

func get_unlocked_traits():
	return data.get("unlocked_traits", ["흙수저 생존본능"])

func get_trait_bonus(trait_name):
	return data.get("trait_bonuses", {}).get(trait_name, {})

func unlock_trait(trait_name):
	var traits: Array = data.get("unlocked_traits", [])
	if not traits.has(trait_name):
		traits.append(trait_name)
		data["unlocked_traits"] = traits
		save_meta()

func unlock_achievement(achievement_id):
	var achievements: Array = data.get("achievements", [])
	if not achievements.has(achievement_id):
		achievements.append(achievement_id)
		data["achievements"] = achievements
		save_meta()

func is_hidden_event_unlocked(event_id):
	return data.get("rare_event_unlocks", []).has(event_id) or data.get("unlocked_hidden_events", []).has(event_id)

func record_run(summary):
	data["total_runs"] = int(data.get("total_runs", 0)) + 1
	data["best_asset"] = max(float(data.get("best_asset", 0.0)), float(summary.get("total_assets", 0.0)))
	var history: Array = data.get("run_history", [])
	history.append(summary)
	if history.size() > 50:
		history.pop_front()
	data["run_history"] = history
	_check_progression_unlocks(summary)
	save_meta()

func _check_progression_unlocks(summary):
	var total_assets = float(summary.get("total_assets", 0.0))
	if total_assets >= 50_000_000:
		unlock_trait("야근 면역자")
	if total_assets >= 200_000_000:
		unlock_trait("리스크 중독자")
	if int(data.get("total_runs", 0)) >= 5:
		unlock_achievement("five_lives")
