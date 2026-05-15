extends Node

signal price_updated(asset_id: String, new_price: float, change_pct: float)
signal trade_executed(asset_id: String, action: String, quantity: float, price: float)
signal portfolio_updated()

var cycle_timer := 0

func initialize():
	if GameState.market_prices.is_empty():
		for asset in DataRegistry.assets:
			GameState.market_prices[asset.get("id", "")] = float(asset.get("initial_price", asset.get("base_price", 10_000.0)))
	_roll_cycle()

func process_month(news_items):
	cycle_timer -= 1
	if cycle_timer <= 0:
		_roll_cycle()
	for asset in DataRegistry.assets:
		_update_asset(asset, news_items)
	_apply_dividends()
	portfolio_updated.emit()

func buy_asset(asset_id, amount_krw):
	var asset := DataRegistry.get_asset(asset_id)
	if asset.is_empty():
		return {"success": false, "message": "존재하지 않는 자산입니다."}
	var current_price := float(GameState.market_prices.get(asset_id, asset.get("initial_price", 0.0)))
	var min_invest := float(asset.get("min_invest", current_price))
	if amount_krw < min_invest:
		return {"success": false, "message": "최소 투자 금액은 %s입니다." % GameState.format_money(min_invest)}
	if amount_krw > GameState.money:
		return {"success": false, "message": "잔액이 부족합니다."}

	var decision_penalty := clamp(float(GameState.stress - 55) / 250.0, 0.0, 0.2)
	var fee := amount_krw * (0.003 + decision_penalty)
	var quantity := max(0.0, amount_krw - fee) / current_price
	if GameState.portfolio.has(asset_id):
		var holding: Dictionary = GameState.portfolio[asset_id]
		var total_quantity := float(holding.get("quantity", 0.0)) + quantity
		var total_cost := float(holding.get("quantity", 0.0)) * float(holding.get("avg_price", current_price)) + quantity * current_price
		holding["quantity"] = total_quantity
		holding["avg_price"] = total_cost / max(total_quantity, 0.0001)
	else:
		GameState.portfolio[asset_id] = {"quantity": quantity, "avg_price": current_price}
	GameState.add_money(-amount_krw)
	if randf() < 0.35:
		GameState.modify_stat("investment_skill", 1)
	GameState.add_log("%s 매수: %s" % [asset.get("name", asset_id), GameState.format_money(amount_krw)], "trade")
	trade_executed.emit(asset_id, "buy", quantity, current_price)
	portfolio_updated.emit()
	return {"success": true, "message": "매수 완료", "quantity": quantity}

func sell_asset(asset_id, sell_ratio):
	if not GameState.portfolio.has(asset_id):
		return {"success": false, "message": "보유하지 않은 자산입니다."}
	var asset := DataRegistry.get_asset(asset_id)
	var holding: Dictionary = GameState.portfolio[asset_id]
	var current_price := float(GameState.market_prices.get(asset_id, holding.get("avg_price", 0.0)))
	var sell_quantity := float(holding.get("quantity", 0.0)) * clamp(sell_ratio, 0.0, 1.0)
	var gross := sell_quantity * current_price
	var net := gross * 0.995
	var cost := sell_quantity * float(holding.get("avg_price", current_price))
	var profit := net - cost
	holding["quantity"] = float(holding.get("quantity", 0.0)) - sell_quantity
	if float(holding["quantity"]) <= 0.0001:
		GameState.portfolio.erase(asset_id)
	GameState.add_money(net)
	GameState.add_log("%s 매도: %s / 손익 %s" % [asset.get("name", asset_id), GameState.format_money(net), GameState.format_money(profit)], "trade")
	trade_executed.emit(asset_id, "sell", sell_quantity, current_price)
	portfolio_updated.emit()
	return {"success": true, "message": "매도 완료", "profit": profit}

func get_asset_rows():
	var rows: Array = []
	for asset in DataRegistry.assets:
		var id := str(asset.get("id", ""))
		var price := float(GameState.market_prices.get(id, asset.get("initial_price", 0.0)))
		var owned := GameState.portfolio.get(id, {})
		var owned_value := float(owned.get("quantity", 0.0)) * price
		rows.append({
			"id": id,
			"name": asset.get("name", id),
			"category": asset.get("category", ""),
			"price": price,
			"owned_value": owned_value,
			"risk_level": asset.get("risk_level", 1),
		})
	return rows

func _roll_cycle():
	cycle_timer = randi_range(5, 11)
	var fear_greed := int(GameState.market_context.get("fear_greed", 50))
	var roll := randf()
	var cycle := "neutral"
	if roll < 0.25 or fear_greed < 30:
		cycle = "bear"
	elif roll > 0.72 or fear_greed > 70:
		cycle = "bull"
	GameState.market_context["cycle"] = cycle
	GameState.market_context["crash_risk"] = 0.02 + max(0.0, float(fear_greed - 70)) / 450.0
	GameState.add_log("시장 국면 전환: %s" % cycle, "market")

func _update_asset(asset, news_items):
	var id := str(asset.get("id", ""))
	var old_price := float(GameState.market_prices.get(id, asset.get("initial_price", 10_000.0)))
	var volatility := float(asset.get("volatility", 0.1))
	var fear_greed := float(GameState.market_context.get("fear_greed", 50))
	var cycle_bias := 0.0
	match str(GameState.market_context.get("cycle", "neutral")):
		"bull":
			cycle_bias = volatility * 0.25
		"bear":
			cycle_bias = -volatility * 0.28
	var greed_bias := (fear_greed - 50.0) / 1000.0 * float(asset.get("fear_greed_sensitivity", 0.1))
	var random_move := (randf() + randf() + randf() - 1.5) * volatility
	var news_bias := _news_bias_for_asset(asset, news_items)
	var bubble_bonus := 0.0
	if GameState.market_context.get("bubble_assets", []).has(id):
		bubble_bonus = volatility * 0.6
	var crash := 0.0
	if randf() < float(GameState.market_context.get("crash_risk", 0.03)) * volatility:
		crash = -randf_range(0.22, 0.55)
	var total_change := clamp(cycle_bias + greed_bias + random_move + news_bias + bubble_bonus + crash, -0.65, 0.95)
	var new_price := max(10.0, old_price * (1.0 + total_change))
	GameState.market_prices[id] = new_price
	price_updated.emit(id, new_price, (new_price - old_price) / max(old_price, 0.01))

func _news_bias_for_asset(asset, news_items):
	var bias := 0.0
	for news in news_items:
		var effect: Dictionary = news.get("market_effect", news.get("market_effects", {}))
		if effect.get("category", "") == asset.get("category", ""):
			bias += float(effect.get("power", 0.0))
	return bias

func _apply_dividends():
	for asset_id in GameState.portfolio:
		var asset := DataRegistry.get_asset(asset_id)
		if asset.get("category", "") in ["korean_stock", "real_estate"]:
			var holding: Dictionary = GameState.portfolio[asset_id]
			var dividend := float(holding.get("quantity", 0.0)) * float(GameState.market_prices.get(asset_id, 0.0)) * 0.002
			if dividend > 0:
				GameState.add_money(dividend)
