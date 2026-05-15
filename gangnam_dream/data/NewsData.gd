## NewsData.gd
## 뉴스 헤드라인 생성 시스템
extends Node

# 뉴스 카테고리별 템플릿
static var ECONOMIC_HEADLINES: Array = [
	{ "text": "한국은행, 기준금리 {action}... 부동산 시장 {reaction}", "action": ["0.25%p 인상", "동결", "0.25%p 인하"], "reaction": ["긴장", "안도", "요동"], "market_effect": {} },
	{ "text": "코스피 {change}... 외국인 {flow}", "change": ["2% 급등", "1.5% 하락", "3% 폭락", "0.5% 소폭 상승"], "flow": ["순매수", "순매도", "관망"], "market_effect": {"samsung": 0.02, "kospi_etf": 0.02} },
	{ "text": "원/달러 환율 {rate}원 돌파... 수출기업 {impact}", "rate": ["1,350", "1,400", "1,300", "1,250"], "impact": ["환호", "우려", "혼조"], "market_effect": {} },
	{ "text": "삼성전자, {quarter}분기 실적 {result}... 반도체 업황 {outlook}", "quarter": ["1", "2", "3", "4"], "result": ["어닝 서프라이즈", "기대 이하", "예상 부합"], "outlook": ["회복", "불투명", "청신호"], "market_effect": {"samsung": 0.05} },
	{ "text": "부동산 시장 {status}... 강남 아파트 {price}", "status": ["회복세", "침체 지속", "급등 경고"], "price": ["신고가 경신", "거래절벽", "관망세"], "market_effect": {"gangnam_apartment": 0.03, "reits_etf": 0.01} },
	{ "text": "美 연준 FOMC 회의... 금리 {fed_action} 시사", "fed_action": ["인하", "동결", "인상"], "market_effect": {"sp500_etf": 0.02, "nasdaq_etf": 0.02} },
	{ "text": "국내 소비자물가지수 {cpi}% 상승... 체감 물가는 {feel}", "cpi": ["2.1", "3.5", "4.2", "1.8"], "feel": ["더 높아", "안정적", "둔화"], "market_effect": {} },
	{ "text": "정부, {policy} 정책 발표... 시장 {market_reaction}", "policy": ["부동산 규제 완화", "가상자산 과세", "증시 부양"], "market_reaction": ["환영", "실망", "관망"], "market_effect": {} },
]

static var CRYPTO_HEADLINES: Array = [
	{ "text": "비트코인 {price}만원 {direction}... 알트코인 {alt_status}", "price": ["8,500", "7,200", "9,800", "6,500"], "direction": ["돌파", "하회", "터치"], "alt_status": ["동반 상승", "동반 하락", "혼조"], "market_effect": {"bitcoin": 0.05, "ethereum": 0.07} },
	{ "text": "美 SEC, 비트코인 ETF {approval}... 기관 투자자들 {reaction}", "approval": ["승인", "거부", "심사 연장"], "reaction": ["환호", "실망", "주시"], "market_effect": {"bitcoin": 0.10} },
	{ "text": "국내 가상자산 거래소 {status}... 투자자 {investor_reaction}", "status": ["거래 급증", "과부하 장애", "제도권 편입"], "investor_reaction": ["몰려들어", "우려 표명", "관심 증가"], "market_effect": {"bitcoin": 0.03, "ethereum": 0.03} },
	{ "text": "이더리움 업그레이드 {result}... 생태계 {ecosystem}", "result": ["성공적 완료", "지연", "논란"], "ecosystem": ["확장", "혼란", "성장"], "market_effect": {"ethereum": 0.08} },
]

static var SOCIAL_HEADLINES: Array = [
	{ "text": "MZ세대 재테크 관심 급증... '{trend}' 투자법 화제", "trend": ["ETF 적립식", "미국주식 직투", "코인 소액", "배당주"], "market_effect": {} },
	{ "text": "강남 직장인 평균 자산 {amount}억원... 현실과 {gap}", "amount": ["5", "3", "10", "2"], "gap": ["격차 확대", "괴리감", "충격"], "market_effect": {} },
	{ "text": "2030세대 {percent}% '노후 준비 전혀 안 돼'... 경각심 {response}", "percent": ["68", "74", "82", "55"], "response": ["커져", "무감각", "퍼져"], "market_effect": {} },
	{ "text": "재테크 유튜브 구독자 {num}만 돌파... '일반인도 {claim}'", "num": ["100", "500", "1000"], "claim": ["부자 될 수 있다", "연봉 뛰어넘는다", "조기 은퇴 가능"], "market_effect": {} },
]

static var COMPANY_HEADLINES: Array = [
	{ "text": "카카오 {division} 사업 {status}... 주가 {stock}", "division": ["핀테크", "게임", "엔터"], "status": ["호조", "부진", "구조조정"], "stock": ["강세", "약세", "혼조"], "market_effect": {"kakao": 0.05} },
	{ "text": "엔비디아 AI 칩 {chip_news}... 수혜 종목 {beneficiary}", "chip_news": ["공급 부족", "신제품 출시", "실적 서프라이즈"], "beneficiary": ["들썩", "주목", "급등"], "market_effect": {"nvidia": 0.08, "nasdaq_etf": 0.03} },
	{ "text": "국내 스타트업 투자 유치 {amount}억원... VC 업계 {vibe}", "amount": ["50", "100", "200", "30"], "vibe": ["활기", "냉각", "선별적"], "market_effect": {} },
]

# ─────────────────────────────────────────
#  헤드라인 생성
# ─────────────────────────────────────────
static func generate_headlines(month, year):
	var headlines: Array = []
	var count = randi_range(2, 4)

	var all_pools = [ECONOMIC_HEADLINES, CRYPTO_HEADLINES, SOCIAL_HEADLINES, COMPANY_HEADLINES]
	all_pools.shuffle()

	for i in range(count):
		var pool = all_pools[i % all_pools.size()]
		var template = pool[randi() % pool.size()]
		headlines.append(_resolve_headline(template, month, year))

	return headlines

static func _resolve_headline(template, month, year):
	var text: String = template["text"]

	# 템플릿 변수 치환
	for key in template:
		if key in ["text", "market_effect"]:
			continue
		var options = template[key]
		if options is Array and not options.is_empty():
			var chosen = options[randi() % options.size()]
			text = text.replace("{" + key + "}", str(chosen))

	return {
		"text": text,
		"month": month,
		"year": year,
		"market_effect": template.get("market_effect", {})
	}

# 월별 특수 뉴스 (계절·이벤트)
static func get_seasonal_news(month):
	match month:
		1: return "새해 증시 개장... 투자자들 '올해는 다르다' 다짐"
		2: return "설 연휴 앞두고 소비 심리 지수 {dir}".format({"dir": ["상승", "하락"][randi() % 2]})
		3: return "1분기 실적 시즌 개막... 어닝 서프라이즈 기대감"
		4: return "배당 시즌 마무리... 배당락 이후 주가 동향 주목"
		5: return "'5월에 팔고 떠나라(Sell in May)' 속설... 올해는?"
		6: return "반기 결산 시즌... 기관투자자 포트폴리오 재정비"
		7: return "여름 휴가 시즌 소비 지출 {dir}".format({"dir": ["확대", "위축"][randi() % 2]})
		8: return "광복절 연휴 증시 휴장... 해외 시장 변동성 주시"
		9: return "3분기 실적 발표 앞두고 시장 기대감 고조"
		10: return "코리아 디스카운트 해소 논의... 외국인 투자 {dir}".format({"dir": ["유입", "이탈"][randi() % 2]})
		11: return "연말 배당주 투자 관심 증가... 우량주 주목"
		12: return "연말 결산 랠리 기대감... 산타 클로스 랠리 현실화될까"
	return ""
