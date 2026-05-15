## InvestmentData.gd
## 투자 자산 데이터 및 시장 시뮬레이션
extends Node

# 자산 카테고리
enum AssetCategory { KOREAN_STOCK, US_STOCK, CRYPTO, REAL_ESTATE, STARTUP, LEVERAGED }

# 자산 데이터 구조:
# id, name, category, initial_price, volatility (월 변동폭 %)
# min_invest (최소 투자 단위), description
# risk_level (1~5), expected_annual_return

static var ASSETS: Array = [
	# ── 국내 주식 ──
	{
		"id": "samsung",
		"name": "삼성전자",
		"ticker": "005930",
		"category": AssetCategory.KOREAN_STOCK,
		"initial_price": 70000.0,
		"volatility": 0.08,
		"min_invest": 70000.0,
		"description": "대한민국 최대 반도체·전자 기업. 안정적이고 배당도 준다.",
		"risk_level": 2,
		"expected_annual_return": 0.08,
		"color": "#4CAF50"
	},
	{
		"id": "kakao",
		"name": "카카오",
		"ticker": "035720",
		"category": AssetCategory.KOREAN_STOCK,
		"initial_price": 55000.0,
		"volatility": 0.12,
		"min_invest": 55000.0,
		"description": "국민 메신저 카카오. 핀테크·콘텐츠 확장 중.",
		"risk_level": 3,
		"expected_annual_return": 0.10,
		"color": "#FFC107"
	},
	{
		"id": "kospi_etf",
		"name": "KODEX 200 ETF",
		"ticker": "069500",
		"category": AssetCategory.KOREAN_STOCK,
		"initial_price": 35000.0,
		"volatility": 0.06,
		"min_invest": 35000.0,
		"description": "코스피 200 지수를 추종하는 ETF. 분산 투자의 기본.",
		"risk_level": 2,
		"expected_annual_return": 0.07,
		"color": "#4CAF50"
	},
	# ── 미국 주식 ──
	{
		"id": "sp500_etf",
		"name": "S&P500 ETF",
		"ticker": "SPY",
		"category": AssetCategory.US_STOCK,
		"initial_price": 580000.0,
		"volatility": 0.07,
		"min_invest": 580000.0,
		"description": "미국 S&P500 지수 추종. 장기 투자의 정석.",
		"risk_level": 2,
		"expected_annual_return": 0.10,
		"color": "#2196F3"
	},
	{
		"id": "nasdaq_etf",
		"name": "나스닥 100 ETF",
		"ticker": "QQQ",
		"category": AssetCategory.US_STOCK,
		"initial_price": 490000.0,
		"volatility": 0.10,
		"min_invest": 490000.0,
		"description": "애플·마이크로소프트·엔비디아 등 기술주 집약.",
		"risk_level": 3,
		"expected_annual_return": 0.13,
		"color": "#2196F3"
	},
	{
		"id": "nvidia",
		"name": "엔비디아",
		"ticker": "NVDA",
		"category": AssetCategory.US_STOCK,
		"initial_price": 850000.0,
		"volatility": 0.18,
		"min_invest": 850000.0,
		"description": "AI 반도체의 왕자. 고위험 고수익.",
		"risk_level": 4,
		"expected_annual_return": 0.25,
		"color": "#76FF03"
	},
	# ── 암호화폐 ──
	{
		"id": "bitcoin",
		"name": "비트코인",
		"ticker": "BTC",
		"category": AssetCategory.CRYPTO,
		"initial_price": 80_000_000.0,
		"volatility": 0.30,
		"min_invest": 50000.0,
		"description": "디지털 금. 극도로 변동성이 높다.",
		"risk_level": 5,
		"expected_annual_return": 0.40,
		"color": "#FF9800"
	},
	{
		"id": "ethereum",
		"name": "이더리움",
		"ticker": "ETH",
		"category": AssetCategory.CRYPTO,
		"initial_price": 4_500_000.0,
		"volatility": 0.35,
		"min_invest": 50000.0,
		"description": "스마트 컨트랙트 플랫폼의 선두주자.",
		"risk_level": 5,
		"expected_annual_return": 0.45,
		"color": "#9C27B0"
	},
	# ── 부동산 ──
	{
		"id": "reits_etf",
		"name": "부동산 리츠 ETF",
		"ticker": "REIT",
		"category": AssetCategory.REAL_ESTATE,
		"initial_price": 5_000_000.0,
		"volatility": 0.04,
		"min_invest": 5_000_000.0,
		"description": "소액으로 부동산에 투자. 배당 수익률이 높다.",
		"risk_level": 2,
		"expected_annual_return": 0.06,
		"color": "#795548"
	},
	{
		"id": "gangnam_apartment",
		"name": "강남 아파트 지분",
		"ticker": "APTS",
		"category": AssetCategory.REAL_ESTATE,
		"initial_price": 50_000_000.0,
		"volatility": 0.03,
		"min_invest": 50_000_000.0,
		"description": "강남구 소재 아파트 지분 투자. 느리지만 확실한 자산 증식.",
		"risk_level": 2,
		"expected_annual_return": 0.05,
		"color": "#FF5722"
	},
	# ── 레버리지 ──
	{
		"id": "kospi_3x",
		"name": "코스피 3배 레버리지",
		"ticker": "KODEX3X",
		"category": AssetCategory.LEVERAGED,
		"initial_price": 15000.0,
		"volatility": 0.25,
		"min_invest": 15000.0,
		"description": "코스피 일간 수익률의 3배. 단기 투기용. 장기 보유 시 손실 가능.",
		"risk_level": 5,
		"expected_annual_return": 0.20,
		"color": "#F44336"
	}
]

# 자산 찾기
static func get_asset(asset_id: String) -> Dictionary:
	for asset in ASSETS:
		if asset["id"] == asset_id:
			return asset
	return {}

# 카테고리별 자산 목록
static func get_assets_by_category(category: int) -> Array:
	var result: Array = []
	for asset in ASSETS:
		if asset["category"] == category:
			result.append(asset)
	return result

# 카테고리 이름
static func category_name(category: int) -> String:
	match category:
		AssetCategory.KOREAN_STOCK: return "국내 주식"
		AssetCategory.US_STOCK: return "미국 주식"
		AssetCategory.CRYPTO: return "암호화폐"
		AssetCategory.REAL_ESTATE: return "부동산"
		AssetCategory.STARTUP: return "스타트업"
		AssetCategory.LEVERAGED: return "레버리지"
	return "기타"

# 초기 시장 가격 딕셔너리
static func get_initial_prices() -> Dictionary:
	var prices: Dictionary = {}
	for asset in ASSETS:
		prices[asset["id"]] = asset["initial_price"]
	return prices
