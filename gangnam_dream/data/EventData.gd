## EventData.gd
## 모든 이벤트 데이터 정의
## 랜덤 이벤트 20개 / 투자 이벤트 10개 / 관계 이벤트 10개 / 직업 이벤트 5개
extends Node

# ─────────────────────────────────────────
#  랜덤 이벤트 (20개)
# ─────────────────────────────────────────
static var RANDOM_EVENTS: Array = [
	{
		"id": "health_scare",
		"title": "갑작스런 건강 이상",
		"description": "최근 무리한 생활로 몸에 이상 신호가 왔다. 병원에 가봐야 할 것 같다.",
		"type": "random",
		"weight": 1.5,
		"conditions": { "max_health": 60 },
		"cooldown": 5,
		"choices": [
			{
				"text": "큰 병원 검진 받기 (30만원)",
				"cost": 300000,
				"effects": { "money": -300000, "health": 15, "stress": -10 },
				"result_text": "정밀 검진 결과 초기 단계에서 발견. 치료를 시작했다."
			},
			{
				"text": "동네 의원에서 간단히 처방받기 (5만원)",
				"effects": { "money": -50000, "health": 5 },
				"result_text": "약을 처방받았지만 근본적인 해결은 아니었다."
			},
			{
				"text": "참고 지낸다",
				"effects": { "health": -10, "stress": 5 },
				"result_text": "억지로 버텼지만 건강이 더 나빠졌다."
			}
		]
	},
	{
		"id": "lottery_ticket",
		"title": "복권 당첨?",
		"description": "편의점에서 산 복권. 번호를 긁어보니 꽤 큰 금액이 맞은 것 같다!",
		"type": "random",
		"weight": 0.5,
		"cooldown": 20,
		"choices": [
			{
				"text": "당장 현금으로 수령한다",
				"effects": { "money": 5000000, "luck": -5, "gambling_tendency": 5 },
				"result_text": "500만원 당첨! 세금 제하고 수령했다. 하지만 이제 복권이 더 당기는 것 같다..."
			},
			{
				"text": "당첨금으로 주식에 투자한다",
				"effects": { "money": 4500000, "investment_skill": 3, "gambling_tendency": 3 },
				"result_text": "450만원을 투자 자금으로 활용했다."
			}
		]
	},
	{
		"id": "friend_wedding",
		"title": "친구 결혼식",
		"description": "오랜 친구에게서 청첩장이 왔다. 결혼식에 참석할지 결정해야 한다.",
		"type": "random",
		"weight": 1.2,
		"cooldown": 8,
		"choices": [
			{
				"text": "참석하고 축의금 10만원 낸다",
				"effects": { "money": -100000, "social_skill": 3, "mental": 5, "stress": -5 },
				"result_text": "오랜 친구들과 만나 좋은 시간을 보냈다. 기분이 좋아졌다."
			},
			{
				"text": "참석하고 축의금 30만원 낸다 (인상 남기기)",
				"effects": { "money": -300000, "social_skill": 5, "reputation": 5 },
				"result_text": "넉넉한 축의금에 친구들 사이에서 평판이 올랐다."
			},
			{
				"text": "바빠서 불참한다",
				"effects": { "social_skill": -2, "reputation": -3 },
				"result_text": "인간관계가 조금 멀어진 것 같다."
			}
		]
	},
	{
		"id": "startup_opportunity",
		"title": "스타트업 창업 제안",
		"description": "지인이 IT 스타트업 공동창업을 제안했다. 초기 투자금 500만원이 필요하다.",
		"type": "random",
		"weight": 0.8,
		"conditions": { "min_money": 5000000, "min_intelligence": 55, "min_turn": 6 },
		"cooldown": 15,
		"choices": [
			{
				"text": "참여한다 (500만원 투자)",
				"effects": { "money": -5000000, "intelligence": 5, "social_skill": 3, "flag": "startup_investor" },
				"result_text": "스타트업에 합류했다. 미래가 불확실하지만 기대된다."
			},
			{
				"text": "더 알아보고 결정한다",
				"effects": { "intelligence": 2 },
				"result_text": "신중하게 생각하기로 했다."
			},
			{
				"text": "거절한다",
				"effects": { "stress": -5 },
				"result_text": "위험 부담이 크다고 판단해 거절했다."
			}
		]
	},
	{
		"id": "startup_result",
		"title": "스타트업 성과",
		"description": "투자한 스타트업에서 연락이 왔다. 시리즈 A 투자를 받았다고 한다!",
		"type": "random",
		"weight": 0.6,
		"conditions": { "flag": "startup_investor" },
		"cooldown": 99,
		"choices": [
			{
				"text": "지분 일부 매각 (2000만원 회수)",
				"effects": { "money": 20000000, "investment_skill": 8, "unflag": "startup_investor" },
				"result_text": "4배 수익! 스타트업 투자의 달콤함을 맛봤다."
			},
			{
				"text": "계속 보유한다 (더 큰 기회를 노린다)",
				"effects": { "investment_skill": 5, "flag": "startup_holding" },
				"result_text": "더 큰 수익을 기대하며 보유를 결정했다."
			}
		]
	},
	{
		"id": "burnout",
		"title": "번아웃 위기",
		"description": "몇 달간 쉬지 않고 달려온 탓에 완전히 지쳐버렸다. 모든 것이 무의미하게 느껴진다.",
		"type": "random",
		"weight": 1.3,
		"conditions": { "min_stress": 60 },
		"cooldown": 6,
		"choices": [
			{
				"text": "1주일 완전 휴가 (여행, 30만원)",
				"effects": { "money": -300000, "mental": 25, "health": 10, "stress": -30 },
				"result_text": "제주도 여행. 오랜만에 머리를 식히니 활력이 돌아왔다."
			},
			{
				"text": "상담 치료 받기 (10만원/회)",
				"effects": { "money": -100000, "mental": 15, "stress": -20, "intelligence": 2 },
				"result_text": "전문 상담사와의 대화로 마음의 짐을 덜었다."
			},
			{
				"text": "억지로 계속 버틴다",
				"effects": { "mental": -15, "health": -5, "stress": 10 },
				"result_text": "억지로 버텼지만 몸과 마음이 더 망가졌다."
			}
		]
	},
	{
		"id": "skill_up_course",
		"title": "자기계발 기회",
		"description": "온라인 강의 플랫폼에서 파이썬·데이터 분석 패키지 강좌를 발견했다.",
		"type": "random",
		"weight": 1.2,
		"cooldown": 6,
		"choices": [
			{
				"text": "수강한다 (20만원, 2개월 과정)",
				"effects": { "money": -200000, "intelligence": 8, "stress": 5 },
				"result_text": "새로운 기술을 익혔다. 취업/승진에 도움이 될 것 같다."
			},
			{
				"text": "무료 자료로 독학한다",
				"effects": { "intelligence": 3, "stress": 8 },
				"result_text": "혼자 공부하다 보니 효율이 떨어졌지만 조금은 배웠다."
			},
			{
				"text": "나중에 한다",
				"effects": {},
				"result_text": "바쁘다는 핑계로 미뤘다."
			}
		]
	},
	{
		"id": "scam_call",
		"title": "보이스피싱 전화",
		"description": "검사를 사칭한 전화가 왔다. 계좌가 범죄에 연루됐다며 돈을 이체하라고 한다.",
		"type": "random",
		"weight": 1.0,
		"cooldown": 10,
		"choices": [
			{
				"text": "즉시 끊는다",
				"effects": { "intelligence": 2, "stress": -2 },
				"result_text": "당연히 사기다. 현명하게 끊었다."
			},
			{
				"text": "경찰에 신고한다",
				"effects": { "reputation": 3, "intelligence": 1 },
				"result_text": "신고 접수 완료. 좋은 시민으로서 행동했다."
			},
			{
				"text": "혹시 몰라 이체한다",
				"effects": { "money": -2000000, "mental": -15, "stress": 20 },
				"result_text": "200만원을 날렸다... 완벽한 보이스피싱이었다."
			}
		]
	},
	{
		"id": "side_hustle",
		"title": "부업 기회",
		"description": "주말에 할 수 있는 배달 부업 기회가 생겼다. 월 50~80만원 수입이 예상된다.",
		"type": "random",
		"weight": 1.1,
		"conditions": { "max_health": 80 },
		"cooldown": 10,
		"choices": [
			{
				"text": "시작한다",
				"effects": { "monthly_income": 600000, "health": -5, "stress": 10, "flag": "side_hustle_active" },
				"result_text": "부업을 시작했다. 수입은 늘었지만 피곤하다."
			},
			{
				"text": "거절한다",
				"effects": { "stress": -3 },
				"result_text": "지금은 본업에 집중하기로 했다."
			}
		]
	},
	{
		"id": "neighborhood_dispute",
		"title": "층간소음 분쟁",
		"description": "윗집 소음으로 잠을 제대로 못 자고 있다. 해결책이 필요하다.",
		"type": "random",
		"weight": 1.0,
		"cooldown": 8,
		"choices": [
			{
				"text": "직접 찾아가 정중히 부탁한다",
				"effects": { "social_skill": 3, "stress": -5 },
				"result_text": "이웃이 이해해줬다. 이후 조용해졌다."
			},
			{
				"text": "관리사무소에 민원 넣는다",
				"effects": { "stress": -8, "reputation": -2 },
				"result_text": "민원 처리 후 해결됐지만 이웃 관계가 어색해졌다."
			},
			{
				"text": "이사를 고려한다",
				"effects": { "mental": -5, "stress": 15 },
				"result_text": "이사 비용 압박에 스트레스가 더 쌓였다."
			}
		]
	},
	{
		"id": "unexpected_expense",
		"title": "갑작스런 지출",
		"description": "스마트폰이 고장났다. 수리비 또는 새 폰 구입 비용이 필요하다.",
		"type": "random",
		"weight": 1.3,
		"cooldown": 12,
		"choices": [
			{
				"text": "중고폰 구입 (30만원)",
				"effects": { "money": -300000 },
				"result_text": "실용적인 선택. 30만원으로 해결했다."
			},
			{
				"text": "최신 플래그십 폰 할부 구입",
				"effects": { "money": -200000, "monthly_income": -80000, "appearance": 3, "flag": "flagship_phone" },
				"result_text": "24개월 할부로 최신폰을 샀다. 매월 8만원씩 빠져나간다."
			},
			{
				"text": "수리한다 (10만원)",
				"effects": { "money": -100000 },
				"result_text": "수리로 해결. 알뜰한 선택이었다."
			}
		]
	},
	{
		"id": "health_gym",
		"title": "헬스장 등록",
		"description": "건강을 위해 헬스장 등록을 고려 중이다.",
		"type": "random",
		"weight": 1.0,
		"cooldown": 12,
		"choices": [
			{
				"text": "3개월 등록 (15만원)",
				"effects": { "money": -150000, "health": 10, "appearance": 5, "stress": -8, "flag": "gym_member" },
				"result_text": "꾸준히 다니기 시작했다. 몸이 좋아지는 느낌이다."
			},
			{
				"text": "홈트레이닝으로 대체",
				"effects": { "health": 5, "stress": -3 },
				"result_text": "유튜브 보며 홈트. 효과는 조금 덜하지만 무료다."
			},
			{
				"text": "다음에 한다",
				"effects": {},
				"result_text": "또 미뤘다."
			}
		]
	},
	{
		"id": "reading_club",
		"title": "독서 모임 초대",
		"description": "지인이 재테크·자기계발 독서 모임에 초대했다.",
		"type": "random",
		"weight": 0.9,
		"cooldown": 8,
		"choices": [
			{
				"text": "참여한다 (월 2만원)",
				"effects": { "money": -20000, "intelligence": 4, "social_skill": 4, "investment_skill": 2 },
				"result_text": "좋은 인연들과 지식을 나눴다. 투자 아이디어도 얻었다."
			},
			{
				"text": "거절한다",
				"effects": {},
				"result_text": "바쁘다는 이유로 거절했다."
			}
		]
	},
	{
		"id": "tax_audit",
		"title": "세금 고지서",
		"description": "예상치 못한 세금 고지서가 날아왔다.",
		"type": "random",
		"weight": 0.8,
		"conditions": { "min_money": 10000000 },
		"cooldown": 12,
		"choices": [
			{
				"text": "즉시 납부 (고지 금액)",
				"effects": { "money": -1500000, "stress": 10, "reputation": 2 },
				"result_text": "세금을 납부했다. 성실 납세자가 됐다."
			},
			{
				"text": "세무사에게 문의한다 (10만원)",
				"effects": { "money": -100000, "intelligence": 3 },
				"result_text": "세무사 조언으로 절세 방법을 찾았다."
			}
		]
	},
	{
		"id": "lucky_encounter",
		"title": "행운의 만남",
		"description": "우연히 업계 선배를 만났다. 그는 투자 비결을 살짝 귀띔해줬다.",
		"type": "random",
		"weight": 0.7,
		"conditions": { "min_luck": 60 },
		"cooldown": 10,
		"choices": [
			{
				"text": "조언을 따라 투자한다",
				"effects": { "investment_skill": 5, "money": 2000000 },
				"result_text": "선배의 정보로 200만원을 벌었다!"
			},
			{
				"text": "감사히 듣고 참고만 한다",
				"effects": { "investment_skill": 3, "social_skill": 2 },
				"result_text": "좋은 인연이 생겼다."
			}
		]
	},
	{
		"id": "rent_increase",
		"title": "월세 인상 통보",
		"description": "집주인이 다음 달부터 월세를 10만원 올리겠다고 통보했다.",
		"type": "random",
		"weight": 1.2,
		"cooldown": 12,
		"choices": [
			{
				"text": "수락한다",
				"effects": { "monthly_income": -100000, "stress": 8 },
				"result_text": "어쩔 수 없이 수락했다. 매달 10만원이 더 나간다."
			},
			{
				"text": "협상을 시도한다",
				"effects": { "social_skill": 2 },
				"result_text": "5만원 인상으로 타협했다.",
				"follow_up_event": "rent_negotiation_success"
			},
			{
				"text": "이사를 준비한다",
				"effects": { "money": -500000, "stress": 15 },
				"result_text": "이사 비용이 들었지만 더 나은 집을 찾았다."
			}
		]
	},
	{
		"id": "family_crisis",
		"title": "가족 위기",
		"description": "부모님으로부터 긴급 연락이 왔다. 급전이 필요한 상황이라고 한다.",
		"type": "random",
		"weight": 0.9,
		"cooldown": 15,
		"choices": [
			{
				"text": "500만원을 보낸다",
				"effects": { "money": -5000000, "mental": 10, "reputation": 5 },
				"result_text": "가족을 도왔다. 부모님이 고마워하셨다."
			},
			{
				"text": "200만원만 보낸다",
				"effects": { "money": -2000000, "mental": 5 },
				"result_text": "형편이 어렵다고 설명하며 200만원을 보냈다."
			},
			{
				"text": "도움을 거절한다",
				"effects": { "mental": -10, "stress": 15, "reputation": -5 },
				"result_text": "어쩔 수 없었지만 마음이 무겁다."
			}
		]
	},
	{
		"id": "promotion_exam",
		"title": "자격증 시험 기회",
		"description": "CFA, 공인중개사, IT 자격증 등 취득 기회가 생겼다.",
		"type": "random",
		"weight": 1.0,
		"cooldown": 8,
		"choices": [
			{
				"text": "금융 자격증 도전 (40만원, 3개월 준비)",
				"effects": { "money": -400000, "intelligence": 8, "investment_skill": 6, "stress": 15, "flag": "has_finance_cert" },
				"result_text": "합격! 금융 자격증을 취득했다. 커리어에 큰 도움이 될 것이다."
			},
			{
				"text": "IT 자격증 도전 (20만원)",
				"effects": { "money": -200000, "intelligence": 6, "stress": 8, "flag": "has_it_cert" },
				"result_text": "IT 자격증 취득. 디지털 시대에 맞는 선택이다."
			},
			{
				"text": "다음 기회로 미룬다",
				"effects": {},
				"result_text": "또 미뤘다. 언제 도전하려나."
			}
		]
	},
	{
		"id": "gambling_temptation",
		"title": "카지노 초대",
		"description": "지인이 강원랜드 여행을 제안했다. '소액으로만 즐기자'고 한다.",
		"type": "random",
		"weight": 0.8,
		"conditions": { "min_money": 1000000 },
		"cooldown": 8,
		"choices": [
			{
				"text": "참여한다 (예산 50만원)",
				"effects": { "money": -500000, "mental": 5, "gambling_tendency": 10 },
				"result_text": "즐겼지만 50만원을 모두 잃었다. 짜릿했다..."
			},
			{
				"text": "참여하되 구경만 한다",
				"effects": { "social_skill": 2, "mental": 3 },
				"result_text": "분위기만 즐겼다. 현명한 선택이었다."
			},
			{
				"text": "거절한다",
				"effects": { "gambling_tendency": -5 },
				"result_text": "도박에 흥미 없다고 딱 잘라 거절했다."
			}
		]
	},
	{
		"id": "networking_event",
		"title": "업계 네트워킹 파티",
		"description": "스타트업·투자자 모임에 초대장이 왔다. 인맥을 넓힐 기회다.",
		"type": "random",
		"weight": 1.0,
		"cooldown": 6,
		"choices": [
			{
				"text": "참석한다 (드레스코드 준비 10만원)",
				"effects": { "money": -100000, "social_skill": 6, "reputation": 5, "investment_skill": 3 },
				"result_text": "투자자와 명함을 교환했다. 인맥이 넓어졌다."
			},
			{
				"text": "온라인으로만 참석한다",
				"effects": { "social_skill": 2 },
				"result_text": "비대면으로 참석했지만 인상 남기기 어려웠다."
			},
			{
				"text": "불참한다",
				"effects": {},
				"result_text": "기회를 놓쳤다."
			}
		]
	}
]

# ─────────────────────────────────────────
#  투자 이벤트 (10개)
# ─────────────────────────────────────────
static var INVESTMENT_EVENTS: Array = [
	{
		"id": "crypto_crash",
		"title": "코인 대폭락",
		"description": "갑자기 주요 암호화폐가 40% 이상 폭락했다. 보유 중인 코인의 가치가 급감하고 있다!",
		"type": "investment",
		"weight": 1.2,
		"conditions": { "has_portfolio": true },
		"cooldown": 8,
		"auto_effects": { "stress": 20 },
		"choices": [
			{
				"text": "패닉셀 - 지금 다 판다",
				"effects": { "mental": -10, "gambling_tendency": 5 },
				"result_text": "손실을 확정 지었다. 마음이 아프다."
			},
			{
				"text": "추가 매수 (물타기, 200만원)",
				"effects": { "money": -2000000, "investment_skill": 3, "stress": 15 },
				"result_text": "저점 매수를 시도했다. 성공할지는 미지수..."
			},
			{
				"text": "보유하며 회복을 기다린다",
				"effects": { "investment_skill": 2, "stress": 10 },
				"result_text": "멘탈을 부여잡고 기다리기로 했다."
			}
		]
	},
	{
		"id": "stock_surge",
		"title": "보유 종목 급등",
		"description": "보유한 종목이 호재 발표로 단기간에 30% 급등했다. 매도 타이밍을 잡아야 한다.",
		"type": "investment",
		"weight": 1.0,
		"conditions": { "has_portfolio": true },
		"cooldown": 8,
		"choices": [
			{
				"text": "전량 매도해 수익 실현",
				"effects": { "money": 3000000, "investment_skill": 3 },
				"result_text": "수익 실현 성공! 짭짤한 이익을 챙겼다."
			},
			{
				"text": "절반만 매도",
				"effects": { "money": 1500000, "investment_skill": 4 },
				"result_text": "절반 매도로 리스크를 줄이면서 상승을 기대한다."
			},
			{
				"text": "계속 보유 (더 오를 것 같다)",
				"effects": { "investment_skill": 1 },
				"result_text": "탐욕이 발동했다. 좋은 결과가 오길 바랄 뿐..."
			}
		]
	},
	{
		"id": "real_estate_tip",
		"title": "부동산 투자 정보",
		"description": "지인으로부터 재개발 예정 지역 정보를 들었다. 진위 여부는 불확실하다.",
		"type": "investment",
		"weight": 0.8,
		"conditions": { "min_money": 50000000 },
		"cooldown": 12,
		"choices": [
			{
				"text": "정보를 믿고 투자한다 (5000만원)",
				"effects": { "money": -50000000, "investment_skill": 5, "flag": "real_estate_bet" },
				"result_text": "큰 결단을 내렸다. 결과는 몇 달 후..."
			},
			{
				"text": "소액만 투자한다 (1000만원)",
				"effects": { "money": -10000000, "investment_skill": 3 },
				"result_text": "리스크를 분산했다."
			},
			{
				"text": "정보를 확인 후 판단한다",
				"effects": { "intelligence": 2 },
				"result_text": "신중한 태도를 유지했다."
			}
		]
	},
	{
		"id": "market_recession",
		"title": "경기 침체 공포",
		"description": "미국發 경기침체 우려로 전 세계 증시가 요동치고 있다.",
		"type": "investment",
		"weight": 1.1,
		"cooldown": 12,
		"auto_effects": { "stress": 10 },
		"choices": [
			{
				"text": "안전자산(금, 달러)으로 갈아탄다",
				"effects": { "investment_skill": 4, "stress": -5 },
				"result_text": "리스크 회피 전략을 택했다."
			},
			{
				"text": "저평가된 주식을 저점 매수한다",
				"effects": { "money": -5000000, "investment_skill": 5, "stress": 10 },
				"result_text": "침체기에 오히려 기회를 잡으려 했다."
			},
			{
				"text": "현금 보유 유지",
				"effects": { "investment_skill": 1 },
				"result_text": "관망 모드. 현명한 선택일 수도 있다."
			}
		]
	},
	{
		"id": "dividend_income",
		"title": "배당 수익 발생",
		"description": "보유 중인 배당주에서 분기 배당금이 들어왔다.",
		"type": "investment",
		"weight": 1.3,
		"conditions": { "has_portfolio": true },
		"cooldown": 3,
		"choices": [
			{
				"text": "배당금을 재투자한다",
				"effects": { "money": 800000, "investment_skill": 3 },
				"result_text": "복리의 마법! 배당금을 다시 투자했다."
			},
			{
				"text": "생활비로 사용한다",
				"effects": { "money": 800000, "mental": 5 },
				"result_text": "달콤한 불로소득을 즐겼다."
			}
		]
	},
	{
		"id": "ipo_opportunity",
		"title": "IPO 공모주 기회",
		"description": "핫한 스타트업의 IPO 공모주 청약 기회가 왔다.",
		"type": "investment",
		"weight": 0.9,
		"conditions": { "min_money": 5000000 },
		"cooldown": 8,
		"choices": [
			{
				"text": "최대 청약한다 (500만원)",
				"effects": { "money": -5000000, "investment_skill": 3, "flag": "ipo_applied" },
				"result_text": "청약 완료. 당첨 여부는 추첨으로 결정된다."
			},
			{
				"text": "소액 청약 (100만원)",
				"effects": { "money": -1000000, "investment_skill": 2 },
				"result_text": "적은 금액으로 참여했다."
			},
			{
				"text": "관망한다",
				"effects": {},
				"result_text": "시장 과열이 우려돼 패스했다."
			}
		]
	},
	{
		"id": "crypto_bull",
		"title": "코인 불장 신호",
		"description": "비트코인이 전고점을 돌파하며 알트코인들도 상승 중이다.",
		"type": "investment",
		"weight": 0.9,
		"cooldown": 10,
		"choices": [
			{
				"text": "코인에 올인한다 (보유 현금 30%)",
				"effects": { "gambling_tendency": 10, "investment_skill": 2 },
				"result_text": "고위험 고수익의 베팅을 했다."
			},
			{
				"text": "소액만 투자한다 (100만원)",
				"effects": { "money": -1000000, "investment_skill": 3 },
				"result_text": "리스크 관리를 하면서 진입했다."
			},
			{
				"text": "지켜본다",
				"effects": { "investment_skill": 1 },
				"result_text": "FOMO를 이겨냈다."
			}
		]
	},
	{
		"id": "leveraged_etf",
		"title": "레버리지 ETF 유혹",
		"description": "3배 레버리지 ETF를 소개하는 유튜브를 봤다. '1년에 3배 수익'이라는 문구가 눈에 띈다.",
		"type": "investment",
		"weight": 1.0,
		"cooldown": 10,
		"choices": [
			{
				"text": "투자한다 (300만원)",
				"effects": { "money": -3000000, "gambling_tendency": 8, "investment_skill": 2, "flag": "leveraged_bet" },
				"result_text": "레버리지의 세계에 발을 들였다."
			},
			{
				"text": "공부 먼저 한다",
				"effects": { "intelligence": 3, "investment_skill": 2 },
				"result_text": "리스크를 충분히 파악한 후 결정하기로 했다."
			},
			{
				"text": "패스한다",
				"effects": { "investment_skill": 1 },
				"result_text": "고위험 상품은 아직 이르다고 판단했다."
			}
		]
	},
	{
		"id": "investment_seminar",
		"title": "투자 세미나 초대",
		"description": "유명 투자 강사의 유료 세미나 초대권이 생겼다.",
		"type": "investment",
		"weight": 1.0,
		"cooldown": 8,
		"choices": [
			{
				"text": "참석한다 (50만원)",
				"effects": { "money": -500000, "investment_skill": 7, "intelligence": 3, "social_skill": 2 },
				"result_text": "실전 투자 노하우를 배웠다. 비쌌지만 가치 있었다."
			},
			{
				"text": "무료 세미나만 찾아본다",
				"effects": { "investment_skill": 3 },
				"result_text": "한계는 있었지만 기초를 다졌다."
			},
			{
				"text": "독학으로 충분하다",
				"effects": {},
				"result_text": "책으로 공부하기로 했다."
			}
		]
	},
	{
		"id": "financial_crisis",
		"title": "금융위기 경보",
		"description": "정부가 비상 경제 대책을 발표했다. 금융시장에 극도의 불안감이 퍼지고 있다.",
		"type": "investment",
		"weight": 0.6,
		"conditions": { "min_turn": 12 },
		"cooldown": 24,
		"auto_effects": { "stress": 25 },
		"choices": [
			{
				"text": "전 재산을 현금화한다",
				"effects": { "mental": -5, "investment_skill": 4 },
				"result_text": "공포에 팔았지만 최악의 상황은 피했다."
			},
			{
				"text": "위기를 기회로 - 저점 매수",
				"effects": { "money": -10000000, "investment_skill": 8, "stress": 20 },
				"result_text": "역발상 투자. 역사는 용감한 자의 편이었다."
			},
			{
				"text": "현 포지션 유지",
				"effects": { "stress": 15, "investment_skill": 3 },
				"result_text": "폭풍을 견뎌냈다."
			}
		]
	}
]

# ─────────────────────────────────────────
#  관계 이벤트 (10개)
# ─────────────────────────────────────────
static var RELATIONSHIP_EVENTS: Array = [
	{
		"id": "mentor_meeting",
		"title": "멘토의 조언",
		"description": "당신을 눈여겨봐 온 사업가 선배가 커피 한 잔을 제안했다.",
		"type": "relationship",
		"weight": 1.0,
		"cooldown": 10,
		"choices": [
			{
				"text": "시간을 내서 만난다",
				"effects": { "intelligence": 5, "investment_skill": 4, "social_skill": 3 },
				"result_text": "멘토의 경험에서 귀한 것을 배웠다.",
				"add_relationship": {
					"id": "mentor_kim", "name": "김성준 (멘토)",
					"type": "mentor", "affinity": 60
				}
			},
			{
				"text": "바빠서 다음에 만나자고 한다",
				"effects": { "social_skill": -2 },
				"result_text": "기회를 미뤘다."
			}
		]
	},
	{
		"id": "romantic_interest",
		"title": "소개팅",
		"description": "친구의 소개로 만날 사람이 생겼다. 첫 만남 준비를 어떻게 할까?",
		"type": "relationship",
		"weight": 1.2,
		"cooldown": 8,
		"choices": [
			{
				"text": "정성껏 준비한다 (외모·대화 준비, 5만원)",
				"effects": { "money": -50000, "appearance": 3, "social_skill": 3 },
				"result_text": "좋은 인상을 남겼다. 다음 만남도 기대된다.",
				"add_relationship": {
					"id": "date_" + str(randi()), "name": "소개팅 상대",
					"type": "romantic", "affinity": 50
				}
			},
			{
				"text": "편하게 나간다",
				"effects": { "social_skill": 1 },
				"result_text": "평범하게 마무리됐다."
			},
			{
				"text": "거절한다",
				"effects": { "mental": -3 },
				"result_text": "지금은 연애보다 돈이 먼저라 생각했다."
			}
		]
	},
	{
		"id": "conflict_with_colleague",
		"title": "직장 내 갈등",
		"description": "함께 일하는 동료와 업무 방식에 대한 갈등이 생겼다.",
		"type": "relationship",
		"weight": 1.1,
		"conditions": { "has_job": true },
		"cooldown": 6,
		"choices": [
			{
				"text": "대화로 해결한다",
				"effects": { "social_skill": 4, "stress": -5 },
				"result_text": "갈등을 성숙하게 해결했다. 관계가 오히려 돈독해졌다."
			},
			{
				"text": "상사에게 보고한다",
				"effects": { "reputation": -3, "stress": -8 },
				"result_text": "처리는 됐지만 팀 분위기가 어색해졌다."
			},
			{
				"text": "무시하고 지낸다",
				"effects": { "stress": 10, "mental": -5 },
				"result_text": "갈등이 해결되지 않아 스트레스가 쌓였다."
			}
		]
	},
	{
		"id": "investor_network",
		"title": "투자자 인맥 형성",
		"description": "파티에서 만난 투자자가 연락처를 건넸다.",
		"type": "relationship",
		"weight": 0.8,
		"conditions": { "min_reputation": 20 },
		"cooldown": 12,
		"choices": [
			{
				"text": "적극적으로 관계를 이어간다",
				"effects": { "investment_skill": 5, "social_skill": 3 },
				"result_text": "귀한 인맥이 생겼다.",
				"add_relationship": {
					"id": "investor_contact", "name": "강남 투자자",
					"type": "business", "affinity": 45
				}
			},
			{
				"text": "연락처만 받아둔다",
				"effects": { "social_skill": 1 },
				"result_text": "언젠가 도움이 될 수도 있다."
			}
		]
	},
	{
		"id": "friend_trouble",
		"title": "친구의 부탁",
		"description": "오랜 친구가 사업 자금 500만원을 빌려달라고 한다.",
		"type": "relationship",
		"weight": 1.0,
		"conditions": { "has_relationship": true },
		"cooldown": 10,
		"choices": [
			{
				"text": "빌려준다",
				"effects": { "money": -5000000, "reputation": 5, "mental": -5 },
				"result_text": "친구를 믿기로 했다. 돌아올지는 모르지만..."
			},
			{
				"text": "100만원만 빌려준다",
				"effects": { "money": -1000000, "reputation": 2 },
				"result_text": "형편상 100만원이 최선이라고 했다."
			},
			{
				"text": "거절한다",
				"effects": { "social_skill": -2, "stress": 5 },
				"result_text": "마음은 아프지만 원칙을 지켰다."
			}
		]
	},
	{
		"id": "networking_dinner",
		"title": "업계 인사와 저녁 식사",
		"description": "상사가 중요한 업계 인사와의 저녁 식사에 함께 가자고 했다.",
		"type": "relationship",
		"weight": 1.0,
		"conditions": { "has_job": true },
		"cooldown": 8,
		"choices": [
			{
				"text": "적극 참여해 인상을 남긴다",
				"effects": { "social_skill": 5, "reputation": 5, "appearance": 2 },
				"result_text": "좋은 인상을 남겼다. 인맥이 넓어졌다."
			},
			{
				"text": "조용히 참석한다",
				"effects": { "social_skill": 2 },
				"result_text": "존재감은 없었지만 분위기를 파악했다."
			}
		]
	},
	{
		"id": "relationship_deepen",
		"title": "관계 발전",
		"description": "최근 자주 보는 사람과 관계가 깊어지고 있다. 더 투자할지 결정해야 한다.",
		"type": "relationship",
		"weight": 1.1,
		"conditions": { "has_relationship": true },
		"cooldown": 6,
		"choices": [
			{
				"text": "시간과 돈을 투자한다 (10만원)",
				"effects": { "money": -100000, "mental": 10, "social_skill": 3, "stress": -8 },
				"result_text": "관계가 깊어졌다. 정서적 안정감을 얻었다."
			},
			{
				"text": "현상 유지한다",
				"effects": {},
				"result_text": "현재 상태를 유지하기로 했다."
			},
			{
				"text": "거리를 둔다",
				"effects": { "social_skill": -2, "mental": -5 },
				"result_text": "관계가 소원해졌다."
			}
		]
	},
	{
		"id": "betrayal",
		"title": "배신",
		"description": "믿었던 지인이 사업 파트너에게 당신의 투자 정보를 팔았다는 사실을 알게 됐다.",
		"type": "relationship",
		"weight": 0.7,
		"conditions": { "has_relationship": true },
		"cooldown": 15,
		"choices": [
			{
				"text": "법적 대응을 검토한다",
				"effects": { "money": -500000, "stress": 20, "mental": -10 },
				"result_text": "법적 자문을 구했지만 증거가 부족했다."
			},
			{
				"text": "조용히 관계를 정리한다",
				"effects": { "mental": -15, "intelligence": 3 },
				"result_text": "상처받았지만 경험에서 배웠다."
			},
			{
				"text": "직접 대면해 따진다",
				"effects": { "social_skill": 3, "stress": 15, "mental": -8 },
				"result_text": "직접 물어봤다. 감정이 격해졌지만 속은 시원했다."
			}
		]
	},
	{
		"id": "partnership_offer",
		"title": "동업 제안",
		"description": "신뢰하는 지인이 공동 사업을 제안했다. 각자 2000만원씩 투자하는 조건이다.",
		"type": "relationship",
		"weight": 0.8,
		"conditions": { "has_relationship": true, "min_money": 20000000 },
		"cooldown": 15,
		"choices": [
			{
				"text": "동참한다",
				"effects": { "money": -20000000, "social_skill": 4, "flag": "business_partner" },
				"result_text": "동업을 시작했다. 함께라면 더 멀리 갈 수 있을 것 같다."
			},
			{
				"text": "조건을 협상한다",
				"effects": { "social_skill": 3, "intelligence": 2 },
				"result_text": "더 유리한 조건으로 재협상하기로 했다."
			},
			{
				"text": "거절한다",
				"effects": {},
				"result_text": "혼자가 편하다고 판단했다."
			}
		]
	},
	{
		"id": "social_media_influence",
		"title": "SNS 인플루언서 제안",
		"description": "팔로워가 많은 지인이 재테크 유튜브 채널을 함께 운영하자고 제안했다.",
		"type": "relationship",
		"weight": 0.9,
		"conditions": { "min_investment_skill": 30 },
		"cooldown": 12,
		"choices": [
			{
				"text": "합류한다",
				"effects": { "social_skill": 5, "reputation": 8, "monthly_income": 300000, "flag": "youtuber" },
				"result_text": "채널이 성장하면서 광고 수익이 들어오기 시작했다."
			},
			{
				"text": "단독 채널을 운영한다",
				"effects": { "social_skill": 3, "reputation": 4, "intelligence": 3 },
				"result_text": "혼자 시작했지만 성장이 더디다."
			},
			{
				"text": "거절한다",
				"effects": {},
				"result_text": "관심 없다고 했다."
			}
		]
	}
]

# ─────────────────────────────────────────
#  직업 이벤트 (5개)
# ─────────────────────────────────────────
static var JOB_EVENTS: Array = [
	{
		"id": "promotion_chance",
		"title": "승진 심사",
		"description": "이번 분기 성과 평가로 승진 기회가 왔다. 상사가 눈여겨보고 있다고 한다.",
		"type": "job",
		"weight": 1.0,
		"conditions": { "has_job": true, "min_tenure": 6 },
		"cooldown": 12,
		"choices": [
			{
				"text": "추가 업무 자원해 어필한다",
				"effects": { "monthly_income": 500000, "reputation": 5, "stress": 15, "work_performance": 10 },
				"result_text": "승진 성공! 급여가 올랐다."
			},
			{
				"text": "평소대로 열심히 한다",
				"effects": { "stress": 5 },
				"result_text": "아쉽게 탈락. 다음 기회를 노려야겠다."
			},
			{
				"text": "승진에 관심 없다",
				"effects": { "stress": -5 },
				"result_text": "승진보다 개인 시간이 소중하다."
			}
		]
	},
	{
		"id": "headhunting",
		"title": "헤드헌터 연락",
		"description": "경쟁사 헤드헌터로부터 연락이 왔다. 현재보다 30% 높은 연봉을 제시하고 있다.",
		"type": "job",
		"weight": 0.9,
		"conditions": { "has_job": true, "min_reputation": 30 },
		"cooldown": 12,
		"choices": [
			{
				"text": "이직한다",
				"effects": { "monthly_income": 700000, "social_skill": 2, "stress": 10, "flag": "changed_job" },
				"result_text": "연봉이 크게 올랐다! 새 환경에 적응하는 것이 과제다."
			},
			{
				"text": "현재 회사에 협상 카드로 쓴다",
				"effects": { "monthly_income": 300000, "reputation": 3 },
				"result_text": "협상으로 30만원 연봉 인상을 얻어냈다."
			},
			{
				"text": "거절한다",
				"effects": { "reputation": 2 },
				"result_text": "현재 직장에 만족하기로 했다."
			}
		]
	},
	{
		"id": "company_crisis",
		"title": "회사 경영 위기",
		"description": "회사가 심각한 경영난에 처했다. 구조조정 소문이 돌고 있다.",
		"type": "job",
		"weight": 1.0,
		"conditions": { "has_job": true },
		"cooldown": 15,
		"choices": [
			{
				"text": "빠르게 이직을 준비한다",
				"effects": { "stress": 15, "intelligence": 3 },
				"result_text": "발 빠르게 움직여 안전하게 탈출했다."
			},
			{
				"text": "회사와 함께 버틴다",
				"effects": { "mental": -10, "stress": 20, "reputation": 3 },
				"result_text": "충성심을 보였지만 불안하다."
			},
			{
				"text": "상황을 지켜본다",
				"effects": { "stress": 10 },
				"result_text": "관망 중. 결과를 기다려야 한다."
			}
		]
	},
	{
		"id": "freelance_project",
		"title": "프리랜서 외주 제안",
		"description": "지인 회사에서 단기 프리랜서 프로젝트를 의뢰했다. 3개월, 600만원 조건이다.",
		"type": "job",
		"weight": 1.0,
		"conditions": { "min_intelligence": 55 },
		"cooldown": 8,
		"choices": [
			{
				"text": "수락한다",
				"effects": { "money": 6000000, "intelligence": 4, "stress": 15, "reputation": 5 },
				"result_text": "프로젝트를 성공적으로 마쳤다. 실력과 돈 모두 챙겼다."
			},
			{
				"text": "주업과 병행하기 어려워 거절한다",
				"effects": { "stress": -5 },
				"result_text": "몸이 하나뿐임을 인정했다."
			}
		]
	},
	{
		"id": "workplace_accident",
		"title": "직장 내 사고",
		"description": "업무 중 실수로 큰 손실이 발생했다. 책임 소재가 불분명한 상황이다.",
		"type": "job",
		"weight": 0.7,
		"conditions": { "has_job": true },
		"cooldown": 10,
		"choices": [
			{
				"text": "자신의 책임임을 인정한다",
				"effects": { "reputation": 5, "mental": -10, "money": -1000000 },
				"result_text": "책임감 있는 모습에 오히려 신뢰를 얻었다."
			},
			{
				"text": "책임을 회피한다",
				"effects": { "reputation": -10, "stress": 20 },
				"result_text": "당장은 넘겼지만 평판에 금이 갔다."
			},
			{
				"text": "팀 문제로 공동 책임을 요청한다",
				"effects": { "social_skill": 2, "money": -300000, "stress": 5 },
				"result_text": "합리적인 중재로 상황을 마무리했다."
			}
		]
	}
]
