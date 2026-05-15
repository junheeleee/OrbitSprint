extends Node

signal item_purchased(item: Dictionary)
signal item_used(item: Dictionary)

func purchase_item(item_id):
	var item := DataRegistry.get_item(item_id)
	if item.is_empty():
		return {"success": false, "message": "존재하지 않는 아이템입니다."}
	var price := float(item.get("price", 0.0))
	if GameState.money < price:
		return {"success": false, "message": "돈이 부족합니다."}
	GameState.add_money(-price)
	GameState.add_item(item_id, 1)
	GameState.add_log("%s 구매" % item.get("name", item_id), "item")
	item_purchased.emit(item)
	return {"success": true, "message": "구매 완료"}

func use_item(item_id):
	var item := DataRegistry.get_item(item_id)
	if item.is_empty():
		return {"success": false, "message": "아이템 오류"}
	GameState.apply_effects(item.get("effects", {}))
	if bool(item.get("one_time", true)):
		GameState.remove_item(item_id, 1)
	GameState.add_log("%s 사용" % item.get("name", item_id), "item")
	item_used.emit(item)
	return {"success": true, "message": "사용 완료"}

func process_monthly_items():
	for owned in GameState.inventory:
		var item := DataRegistry.get_item(owned.get("id", ""))
		GameState.apply_effects(item.get("passive_effects", {}))

func get_shop_items():
	return DataRegistry.items
