## ItemData.gd
## 아이템 데이터 (15개)
extends Node

# 아이템 구조:
# id, name, category, price, description
# effects (사용 시 즉시 효과)
# passive_effects (보유 시 월별 효과)
# one_time (1회용 여부)

static var ITEMS: Array = [
	# ── 건강 아이템 ──
	{
		"id": "energy_drink",
		"name": "에너지 드링크 박스",
		"category": "건강",
		"price": 30000,
		"description": "피로 회복에 효과적. 하지만 너무 자주 마시면 건강에 해롭다.",
		"effects": { "health": 5, "stress": -5, "mental": 3 },
		"passive_effects": {},
		"one_time": true,
		"icon": "⚡"
	},
	{
		"id": "health_supplement",
		"name": "영양제 세트",
		"category": "건강",
		"price": 80000,
		"description": "오메가3, 비타민D, 마그네슘 1개월치. 꾸준히 챙겨먹자.",
		"effects": {},
		"passive_effects": { "health": 3 },
		"duration": 3,
		"one_time": false,
		"icon": "💊"
	},
	{
		"id": "yoga_mat",
		"name": "요가 매트",
		"category": "건강",
		"price": 50000,
		"description": "집에서 스트레칭과 명상에 활용. 스트레스 해소에 좋다.",
		"effects": {},
		"passive_effects": { "health": 1, "mental": 2, "stress": -2 },
		"one_time": false,
		"icon": "🧘"
	},
	# ── 지식/자기계발 ──
	{
		"id": "investment_book",
		"name": "워런 버핏 투자 원칙",
		"category": "지식",
		"price": 18000,
		"description": "투자의 바이블. 정독하면 투자 감각이 늘어난다.",
		"effects": { "investment_skill": 4, "intelligence": 2 },
		"passive_effects": {},
		"one_time": true,
		"icon": "📚"
	},
	{
		"id": "self_dev_book",
		"name": "부의 추월차선",
		"category": "지식",
		"price": 16000,
		"description": "빠른 부의 축적 방법론. 동기 부여가 된다.",
		"effects": { "intelligence": 3, "mental": 5 },
		"passive_effects": {},
		"one_time": true,
		"icon": "📖"
	},
	{
		"id": "coding_course",
		"name": "파이썬 퀀트 강의",
		"category": "지식",
		"price": 200000,
		"description": "파이썬으로 자동 투자 시스템을 구축하는 강의.",
		"effects": { "intelligence": 8, "investment_skill": 6 },
		"passive_effects": {},
		"one_time": true,
		"unlock_job": "it_developer",
		"icon": "🖥️"
	},
	# ── 외모/사회생활 ──
	{
		"id": "suit",
		"name": "정장 한 벌",
		"category": "외모",
		"price": 300000,
		"description": "면접·미팅·네트워킹에 필수. 첫인상을 좌우한다.",
		"effects": {},
		"passive_effects": { "appearance": 2, "social_skill": 1 },
		"one_time": false,
		"icon": "👔"
	},
	{
		"id": "haircut_premium",
		"name": "강남 프리미엄 헤어",
		"category": "외모",
		"price": 80000,
		"description": "강남 유명 미용실. 한 번에 외모가 달라진다.",
		"effects": { "appearance": 5, "social_skill": 2 },
		"passive_effects": {},
		"one_time": true,
		"icon": "✂️"
	},
	{
		"id": "business_card",
		"name": "명함 제작",
		"category": "사회",
		"price": 30000,
		"description": "전문적인 명함. 네트워킹에서 인상을 남긴다.",
		"effects": { "social_skill": 3, "reputation": 3 },
		"passive_effects": {},
		"one_time": true,
		"icon": "💳"
	},
	# ── 투자 도구 ──
	{
		"id": "trading_software",
		"name": "HTS 프리미엄 구독",
		"category": "투자",
		"price": 50000,
		"description": "전문 투자자용 주식 분석 툴. 매달 구독료가 나간다.",
		"effects": {},
		"passive_effects": { "investment_skill": 2 },
		"monthly_cost": 50000,
		"one_time": false,
		"icon": "📈"
	},
	{
		"id": "economic_newspaper",
		"name": "한국경제 구독",
		"category": "투자",
		"price": 20000,
		"description": "매일 아침 경제 뉴스를 읽으면 시장 감각이 생긴다.",
		"effects": {},
		"passive_effects": { "intelligence": 1, "investment_skill": 1 },
		"monthly_cost": 20000,
		"one_time": false,
		"icon": "📰"
	},
	{
		"id": "investment_spreadsheet",
		"name": "투자 포트폴리오 관리 툴",
		"category": "투자",
		"price": 50000,
		"description": "수익률·리스크 분석 엑셀 템플릿. 관리 능력이 오른다.",
		"effects": { "investment_skill": 3 },
		"passive_effects": {},
		"one_time": true,
		"icon": "📊"
	},
	# ── 생활 ──
	{
		"id": "coffee_machine",
		"name": "원두 커피 머신",
		"category": "생활",
		"price": 250000,
		"description": "카페 값을 아끼고 집에서 고급 커피를 즐긴다. 매월 커피값 절약.",
		"effects": {},
		"passive_effects": { "mental": 2, "stress": -2 },
		"monthly_save": 80000,
		"one_time": false,
		"icon": "☕"
	},
	{
		"id": "luxury_dinner",
		"name": "파인다이닝 식사권",
		"category": "사교",
		"price": 200000,
		"description": "강남 유명 레스토랑 식사권. 중요한 미팅이나 특별한 날에 사용.",
		"effects": { "social_skill": 5, "appearance": 3, "mental": 8, "reputation": 5 },
		"passive_effects": {},
		"one_time": true,
		"icon": "🍽️"
	},
	{
		"id": "meditation_app",
		"name": "명상 앱 연간 구독",
		"category": "건강",
		"price": 80000,
		"description": "하루 10분 명상으로 정신 건강을 관리. 스트레스 완화에 효과적.",
		"effects": {},
		"passive_effects": { "mental": 2, "stress": -3 },
		"one_time": false,
		"icon": "🧠"
	}
]

static func get_item(item_id: String) -> Dictionary:
	for item in ITEMS:
		if item["id"] == item_id:
			return item
	return {}

static func get_items_by_category(category: String) -> Array:
	var result: Array = []
	for item in ITEMS:
		if item["category"] == category:
			result.append(item)
	return result

static func get_affordable_items(max_price: float) -> Array:
	var result: Array = []
	for item in ITEMS:
		if float(item["price"]) <= max_price:
			result.append(item)
	return result
