## JobData.gd
## 직업 데이터 (5개 직업)
extends Node

# 직업 구조:
# id, name, category, description
# base_salary (월), requirements (조건), stress_per_month
# promotion_bonus, stat_gains (월별 스탯 성장)
# special (특수 혜택)

static var JOBS: Array = [
	{
		"id": "convenience_store",
		"name": "편의점 아르바이트",
		"category": "아르바이트",
		"description": "24시간 편의점 야간·주간 근무. 낮은 수입이지만 진입 장벽이 없다.",
		"base_salary": 1_800_000,
		"requirements": {},
		"stress_per_month": 10,
		"stat_gains": {
			"social_skill": 1
		},
		"promotion_threshold": 6,
		"promotion_bonus": 200_000,
		"special": "야간 수당 가능 (+20만원/월)",
		"tier": 1,
		"icon": "🏪"
	},
	{
		"id": "junior_office",
		"name": "중소기업 사무직",
		"category": "사무직",
		"description": "작은 회사의 사무직. 안정적이지만 성장이 느리다. 경험을 쌓기에 좋다.",
		"base_salary": 2_800_000,
		"requirements": { "min_intelligence": 45 },
		"stress_per_month": 15,
		"stat_gains": {
			"intelligence": 1,
			"social_skill": 1
		},
		"promotion_threshold": 12,
		"promotion_bonus": 400_000,
		"special": "경력 6개월 이후 이직 프리미엄",
		"tier": 2,
		"icon": "🏢"
	},
	{
		"id": "financial_analyst",
		"name": "금융권 애널리스트",
		"category": "금융",
		"description": "증권사·은행 분석 업무. 스트레스가 높지만 수입과 성장이 빠르다.",
		"base_salary": 4_500_000,
		"requirements": { "min_intelligence": 65, "min_investment_skill": 25 },
		"stress_per_month": 25,
		"stat_gains": {
			"intelligence": 2,
			"investment_skill": 3
		},
		"promotion_threshold": 18,
		"promotion_bonus": 1_000_000,
		"special": "내부 투자 정보 접근 가능",
		"tier": 3,
		"icon": "📊"
	},
	{
		"id": "it_developer",
		"name": "IT 개발자",
		"category": "IT",
		"description": "스타트업 또는 IT 기업의 개발자. 시장 수요가 높고 원격근무 가능.",
		"base_salary": 5_000_000,
		"requirements": { "min_intelligence": 70, "flag": "has_it_cert" },
		"stress_per_month": 20,
		"stat_gains": {
			"intelligence": 2,
			"social_skill": 1
		},
		"promotion_threshold": 12,
		"promotion_bonus": 800_000,
		"special": "스톡옵션 기회, 사이드 프로젝트 수입",
		"tier": 3,
		"icon": "💻"
	},
	{
		"id": "startup_founder",
		"name": "스타트업 창업자",
		"category": "창업",
		"description": "직접 사업을 운영한다. 초기에는 수입이 불안정하지만 성공 시 폭발적 성장.",
		"base_salary": 0,
		"requirements": {
			"min_intelligence": 60,
			"min_social": 60,
			"min_money": 20_000_000
		},
		"stress_per_month": 35,
		"stat_gains": {
			"intelligence": 3,
			"social_skill": 3,
			"investment_skill": 2
		},
		"promotion_threshold": 0,
		"promotion_bonus": 0,
		"special": "사업 성장 시 월 수입 무한 확장, 투자 유치 가능",
		"tier": 4,
		"variable_income": true,
		"income_range": [0, 20_000_000],
		"icon": "🚀"
	}
]

# 직업 찾기
static func get_job(job_id: String) -> Dictionary:
	for job in JOBS:
		if job["id"] == job_id:
			return job
	return {}

# 지원 가능한 직업 목록
static func get_available_jobs() -> Array:
	var available: Array = []
	for job in JOBS:
		if _check_requirements(job.get("requirements", {})):
			available.append(job)
	return available

static func _check_requirements(req: Dictionary) -> bool:
	for key in req:
		var val = req[key]
		match key:
			"min_intelligence":
				if GameState.intelligence < int(val): return false
			"min_social":
				if GameState.social_skill < int(val): return false
			"min_investment_skill":
				if GameState.investment_skill < int(val): return false
			"min_money":
				if GameState.money < float(val): return false
			"flag":
				if not GameState.flags.get(val, false): return false
	return true
