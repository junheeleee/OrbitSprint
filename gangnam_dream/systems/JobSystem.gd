extends Node

signal job_changed(new_job: Dictionary)
signal promoted(job: Dictionary, bonus: float)

func apply_for_job(job_id: String) -> Dictionary:
	var job := DataRegistry.get_job(job_id)
	if job.is_empty():
		return {"success": false, "message": "존재하지 않는 직업입니다."}
	if not _check_requirements(job.get("requirements", {})):
		return {"success": false, "message": "지원 조건이 부족합니다."}
	if not GameState.current_job.is_empty():
		quit_job(false)
	GameState.current_job = job.duplicate(true)
	GameState.job_tenure = 0
	GameState.work_performance = 50
	GameState.monthly_income += float(job.get("base_salary", 0.0))
	GameState.flags["has_job"] = true
	GameState.add_log("%s 취업. 월급 %s" % [job.get("name", "직장"), GameState.format_money(job.get("base_salary", 0.0))], "job")
	job_changed.emit(job)
	return {"success": true, "message": "취업 완료"}

func quit_job(voluntary: bool = true) -> void:
	if GameState.current_job.is_empty():
		return
	GameState.monthly_income -= float(GameState.current_job.get("base_salary", 0.0))
	GameState.add_log("%s 퇴사" % GameState.current_job.get("name", "직장"), "job")
	GameState.current_job = {}
	GameState.job_tenure = 0
	GameState.flags.erase("has_job")
	if voluntary:
		job_changed.emit({})

func process_monthly_job() -> void:
	if GameState.current_job.is_empty():
		GameState.modify_hidden_stat("stress", 2)
		return
	var job := GameState.current_job
	GameState.job_tenure += 1
	GameState.modify_hidden_stat("stress", int(job.get("stress_per_month", 6)))
	for stat in job.get("stat_gains", {}):
		if randf() < 0.55:
			GameState.modify_stat(stat, int(job["stat_gains"][stat]))
	GameState.work_performance = clamp(GameState.work_performance + randi_range(-4, 8), 0, 100)
	if GameState.job_tenure >= int(job.get("promotion_threshold", 999)) and GameState.work_performance >= 60 and randf() < 0.35:
		_promote(job)

func get_available_jobs() -> Array:
	var rows: Array = []
	for job in DataRegistry.jobs:
		var row := job.duplicate(true)
		row["eligible"] = _check_requirements(job.get("requirements", {}))
		rows.append(row)
	return rows

func _promote(job: Dictionary) -> void:
	var bonus := float(job.get("promotion_bonus", 0.0))
	GameState.monthly_income += bonus
	GameState.add_money(bonus * 2.0)
	GameState.modify_hidden_stat("reputation", 6)
	GameState.job_tenure = 0
	GameState.add_log("승진: 월급 +%s" % GameState.format_money(bonus), "job")
	promoted.emit(job, bonus)

func _check_requirements(req: Dictionary) -> bool:
	for key in req:
		var val = req[key]
		match key:
			"min_intelligence":
				if GameState.intelligence < int(val): return false
			"min_social", "min_social_skill":
				if GameState.social_skill < int(val): return false
			"min_investment_skill":
				if GameState.investment_skill < int(val): return false
			"min_money":
				if GameState.money < float(val): return false
			"flag":
				if not GameState.flags.get(str(val), false): return false
	return true
