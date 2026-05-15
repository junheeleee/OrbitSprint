extends Node

signal news_generated(news_items: Array)

var last_news: Array = []

func generate_monthly_news():
	var pool = DataRegistry.news_templates.duplicate(true)
	pool.shuffle()
	var count = randi_range(3, 5)
	var selected: Array = []
	for i in range(min(count, pool.size())):
		var item: Dictionary = pool[i].duplicate(true)
		item["misleading"] = randf() < float(item.get("misleading_chance", 0.15))
		item["month"] = GameState.month
		item["year"] = GameState.year
		selected.append(item)
		_apply_news_pressure(item)
	GameState.news_log.append_array(selected)
	if GameState.news_log.size() > 80:
		GameState.news_log = GameState.news_log.slice(GameState.news_log.size() - 80)
	last_news = selected
	news_generated.emit(selected)
	return selected

func _apply_news_pressure(item):
	var sentiment = str(item.get("sentiment", "neutral"))
	var fear_delta = 0
	match sentiment:
		"greed":
			fear_delta = 7
		"fear":
			fear_delta = -9
		"panic":
			fear_delta = -16
		"euphoria":
			fear_delta = 13
	if bool(item.get("misleading", false)):
		fear_delta = int(round(float(fear_delta) * -0.35))
	GameState.market_context["fear_greed"] = clamp(int(GameState.market_context.get("fear_greed", 50)) + fear_delta, 0, 100)

	var market_effects: Dictionary = item.get("market_effects", {})
	for asset_id in market_effects:
		if GameState.market_prices.has(asset_id):
			var delta = float(market_effects[asset_id])
			if bool(item.get("misleading", false)):
				delta *= -0.45
			GameState.market_prices[asset_id] *= 1.0 + delta

	if item.get("bubble_asset", "") != "":
		var bubble_assets: Array = GameState.market_context.get("bubble_assets", [])
		if not bubble_assets.has(item["bubble_asset"]):
			bubble_assets.append(item["bubble_asset"])
		GameState.market_context["bubble_assets"] = bubble_assets
