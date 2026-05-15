extends Node

signal stats_changed()
signal money_changed(new_amount: float)
signal turn_advanced(new_turn: int)
signal game_over(ending_id: String)
signal log_added(entry: Dictionary)
signal run_started()

var player_name = "김민준"
var age = 20
var year = 2026
var month = 1
var turn = 1
var is_game_over = false
var current_trait = "흙수저 생존본능"

var money = 1_000_000.0
var monthly_income = 0.0
var fixed_expense = 650_000.0
var health = 70
var mental = 70
var intelligence = 50
var social_skill = 40
var appearance = 50
var investment_skill = 12
var luck = 45

var stress = 25
var reputation = 10
var gambling_tendency = 0
var addiction_tendency = 0

var current_job: Dictionary = {}
var job_tenure = 0
var work_performance = 50

var portfolio: Dictionary = {}
var relationships: Array = []
var inventory: Array = []
var news_log: Array = []
var event_log: Array = []
var action_log: Array = []
var flags: Dictionary = {}
var market_prices: Dictionary = {}
var market_context = {
	"fear_greed": 50,
	"cycle": "neutral",
	"bubble_assets": [],
	"crash_risk": 0.04,
	"momentum": 0.0,
}

func _ready():
	randomize()

func new_game():
	start_new_game("흙수저 생존본능")

func start_new_game(selected_trait):
	player_name = "김민준"
	age = 20
	year = 2026
	month = 1
	turn = 1
	is_game_over = false
	current_trait = selected_trait

	money = 1_000_000.0
	monthly_income = 0.0
	fixed_expense = 650_000.0
	health = 70
	mental = 70
	intelligence = 50
	social_skill = 40
	appearance = 50
	investment_skill = 12
	luck = 45
	stress = 25
	reputation = 10
	gambling_tendency = 0
	addiction_tendency = 0
	current_job = {}
	job_tenure = 0
	work_performance = 50
	portfolio = {}
	relationships = []
	inventory = []
	news_log = []
	event_log = []
	action_log = []
	flags = {}
	market_prices = {}
	market_context = {
		"fear_greed": 50,
		"cycle": "neutral",
		"bubble_assets": [],
		"crash_risk": 0.04,
		"momentum": 0.0,
	}

	_apply_trait_bonus(selected_trait)
	_init_market_prices()
	add_log("새 런 시작: %s" % selected_trait, "system")
	stats_changed.emit()
	run_started.emit()

func _apply_trait_bonus(selected_trait):
	var bonuses = {}
	if has_node("/root/MetaProgression"):
		bonuses = MetaProgression.get_trait_bonus(selected_trait)
	apply_effects(bonuses)

func _init_market_prices():
	for asset in DataRegistry.assets:
		market_prices[asset.get("id", "")] = float(asset.get("initial_price", asset.get("base_price", 10_000.0)))

func advance_calendar():
	if is_game_over:
		return
	turn += 1
	month += 1
	if month > 12:
		month = 1
		year += 1
		age += 1
	turn_advanced.emit(turn)

func apply_monthly_pressure():
	add_money(monthly_income - fixed_expense)
	modify_hidden_stat("stress", 2)
	if stress > 70:
		modify_stat("health", -2)
		modify_stat("mental", -3)
	elif stress > 50:
		modify_stat("mental", -1)
	if money < 0:
		modify_hidden_stat("stress", 5)
		modify_stat("mental", -2)
	check_game_over()

func apply_choice(event, choice):
	apply_effects(choice.get("effects", {}))
	for rel_effect in choice.get("relationship_effects", []):
		apply_relationship_effect(rel_effect)
	for investment_effect in choice.get("investment_effects", []):
		apply_investment_effect(investment_effect)
	for flag_id in choice.get("flags", []):
		flags[str(flag_id)] = true
	event_log.append({
		"turn": turn,
		"event_id": event.get("id", ""),
		"choice": choice.get("text", ""),
		"result": choice.get("result_text", ""),
	})
	add_log("%s: %s" % [event.get("title", "이벤트"), choice.get("result_text", choice.get("text", ""))], "event")

func apply_effects(effects):
	for key in effects:
		var value = effects[key]
		match key:
			"money":
				add_money(float(value))
			"monthly_income":
				monthly_income += float(value)
			"fixed_expense":
				fixed_expense = max(0.0, fixed_expense + float(value))
			"health", "mental", "intelligence", "social_skill", "appearance", "investment_skill", "luck":
				modify_stat(key, int(value))
			"stress", "reputation", "gambling_tendency", "addiction_tendency":
				modify_hidden_stat(key, int(value))
			"flag":
				flags[str(value)] = true
			"unflag":
				flags.erase(str(value))
	stats_changed.emit()

func apply_relationship_effect(effect):
	var rel_id = str(effect.get("id", effect.get("type", "unknown")))
	var found = false
	for rel in relationships:
		if rel.get("id", "") == rel_id:
			rel["affection"] = clamp(int(rel.get("affection", 40)) + int(effect.get("affection", 0)), 0, 100)
			rel["trust"] = clamp(int(rel.get("trust", 40)) + int(effect.get("trust", 0)), 0, 100)
			found = true
			break
	if not found:
		relationships.append({
			"id": rel_id,
			"name": effect.get("name", "새 인연"),
			"type": effect.get("type", "friends"),
			"affection": clamp(int(effect.get("affection", 45)), 0, 100),
			"trust": clamp(int(effect.get("trust", 40)), 0, 100),
			"met_turn": turn,
		})
	stats_changed.emit()

func apply_investment_effect(effect):
	var asset_id = str(effect.get("asset_id", ""))
	if asset_id.is_empty():
		return
	if not market_prices.has(asset_id):
		return
	market_prices[asset_id] *= 1.0 + float(effect.get("price_delta", 0.0))
	if bool(effect.get("bubble", false)):
		var bubble_assets: Array = market_context.get("bubble_assets", [])
		if not bubble_assets.has(asset_id):
			bubble_assets.append(asset_id)
		market_context["bubble_assets"] = bubble_assets

func add_money(amount):
	money += amount
	money_changed.emit(money)
	stats_changed.emit()

func modify_stat(stat_name, amount):
	match stat_name:
		"health":
			health = clamp(health + amount, 0, 100)
		"mental":
			mental = clamp(mental + amount, 0, 100)
		"intelligence":
			intelligence = clamp(intelligence + amount, 0, 100)
		"social_skill":
			social_skill = clamp(social_skill + amount, 0, 100)
		"appearance":
			appearance = clamp(appearance + amount, 0, 100)
		"investment_skill":
			investment_skill = clamp(investment_skill + amount, 0, 100)
		"luck":
			luck = clamp(luck + amount, 0, 100)

func modify_hidden_stat(stat_name, amount):
	match stat_name:
		"stress":
			stress = clamp(stress + amount, 0, 100)
		"reputation":
			reputation = clamp(reputation + amount, -100, 100)
		"gambling_tendency":
			gambling_tendency = clamp(gambling_tendency + amount, 0, 100)
		"addiction_tendency":
			addiction_tendency = clamp(addiction_tendency + amount, 0, 100)

func add_item(item_id, quantity):
	var item = DataRegistry.get_item(item_id)
	if item.is_empty():
		return
	for owned in inventory:
		if owned.get("id", "") == item_id:
			owned["quantity"] = int(owned.get("quantity", 0)) + quantity
			stats_changed.emit()
			return
	var owned_item = item.duplicate(true)
	owned_item["quantity"] = quantity
	inventory.append(owned_item)
	stats_changed.emit()

func remove_item(item_id, quantity):
	for i in range(inventory.size()):
		if inventory[i].get("id", "") == item_id:
			inventory[i]["quantity"] = int(inventory[i].get("quantity", 1)) - quantity
			if int(inventory[i]["quantity"]) <= 0:
				inventory.remove_at(i)
			stats_changed.emit()
			return true
	return false

func add_log(message, log_type):
	var entry = {
		"turn": turn,
		"date": get_date_string(),
		"message": message,
		"type": log_type,
	}
	action_log.append(entry)
	if action_log.size() > 120:
		action_log.pop_front()
	log_added.emit(entry)

func get_date_string():
	return "%d년 %d월" % [year, month]

func format_money(amount):
	var sign = ""
	if amount < 0:
		sign = "-"
	var abs_amount = abs(amount)
	if abs_amount >= 100_000_000:
		return "%s%.1f억원" % [sign, abs_amount / 100_000_000.0]
	if abs_amount >= 10_000:
		return "%s%.0f만원" % [sign, abs_amount / 10_000.0]
	return "%s%.0f원" % [sign, abs_amount]

func get_total_asset_value():
	var total = money
	for asset_id in portfolio:
		var holding: Dictionary = portfolio[asset_id]
		total += float(holding.get("quantity", 0.0)) * float(market_prices.get(asset_id, holding.get("avg_price", 0.0)))
	return total

func get_wealth_tier():
	var total = get_total_asset_value()
	if total >= 2_000_000_000:
		return "강남 상류층"
	if total >= 500_000_000:
		return "자산가"
	if total >= 100_000_000:
		return "중산층"
	if total >= 30_000_000:
		return "버티는 청년"
	return "월세 생존자"

func check_game_over():
	if is_game_over:
		return
	if health <= 0:
		finish_run("health_collapse")
	elif mental <= 0:
		finish_run("mental_burnout")
	elif money < -30_000_000:
		finish_run("debt_spiral")
	elif age >= 65:
		finish_run("ordinary_retirement")
	elif get_total_asset_value() >= 2_000_000_000:
		finish_run("gangnam_dream")

func finish_run(ending_id):
	is_game_over = true
	MetaProgression.record_run({
		"ending_id": ending_id,
		"turn": turn,
		"age": age,
		"total_assets": get_total_asset_value(),
		"trait": current_trait,
	})
	game_over.emit(ending_id)

func serialize():
	return {
		"player_name": player_name,
		"age": age,
		"year": year,
		"month": month,
		"turn": turn,
		"is_game_over": is_game_over,
		"current_trait": current_trait,
		"money": money,
		"monthly_income": monthly_income,
		"fixed_expense": fixed_expense,
		"health": health,
		"mental": mental,
		"intelligence": intelligence,
		"social_skill": social_skill,
		"appearance": appearance,
		"investment_skill": investment_skill,
		"luck": luck,
		"stress": stress,
		"reputation": reputation,
		"gambling_tendency": gambling_tendency,
		"addiction_tendency": addiction_tendency,
		"current_job": current_job,
		"job_tenure": job_tenure,
		"work_performance": work_performance,
		"portfolio": portfolio,
		"relationships": relationships,
		"inventory": inventory,
		"news_log": news_log,
		"event_log": event_log,
		"action_log": action_log,
		"flags": flags,
		"market_prices": market_prices,
		"market_context": market_context,
	}

func load_from_dict(data):
	var allowed = serialize().keys()
	for key in data:
		if allowed.has(key):
			set(key, data[key])
	stats_changed.emit()
