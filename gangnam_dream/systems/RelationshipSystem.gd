extends Node

signal relationship_added(rel: Dictionary)
signal relationship_changed(rel: Dictionary)

func process_monthly_relationships() -> void:
	for rel in GameState.relationships.duplicate():
		rel["affection"] = clamp(int(rel.get("affection", rel.get("affinity", 40))) - 1, 0, 100)
		var trust_decay := 0
		if GameState.stress > 75:
			trust_decay = 1
		rel["trust"] = clamp(int(rel.get("trust", 40)) - trust_decay, 0, 100)
		_apply_passive(rel)
		if int(rel.get("affection", 0)) <= 0 and int(rel.get("trust", 0)) <= 10:
			GameState.relationships.erase(rel)
			GameState.add_log("%s와의 관계가 끊어졌다." % rel.get("name", "누군가"), "relationship")
		else:
			relationship_changed.emit(rel)

func add_relationship(rel_data: Dictionary) -> void:
	GameState.apply_relationship_effect(rel_data)
	relationship_added.emit(rel_data)

func get_affinity_label(value: int) -> String:
	if value >= 85: return "운명 공동체"
	if value >= 65: return "가까운 사이"
	if value >= 45: return "느슨한 인연"
	if value >= 25: return "불안한 관계"
	return "멀어진 관계"

func _apply_passive(rel: Dictionary) -> void:
	var affection := int(rel.get("affection", 40))
	if affection < 55:
		return
	match str(rel.get("type", "friends")):
		"romantic":
			GameState.modify_stat("mental", 1)
			GameState.modify_hidden_stat("stress", -1)
		"mentor":
			if randf() < 0.45:
				GameState.modify_stat("investment_skill", 1)
		"business":
			if randf() < 0.35:
				GameState.modify_hidden_stat("reputation", 1)
		"family":
			if randf() < 0.35:
				GameState.modify_stat("mental", 1)
