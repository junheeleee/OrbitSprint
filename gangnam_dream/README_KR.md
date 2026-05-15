# 강남드림

## Korean Modern-Life Roguelike Simulator

`강남드림`은 100만원을 가진 스무 살 한국 청년이 현대 한국 사회에서 살아남고, 돈과 관계와 정신력을 갈아 넣어 계층 상승을 노리는 텍스트 기반 로그라이크 인생 시뮬레이션입니다.

톤은 현실적이고 약간 잔인하며, 금융 뉴스의 조급함, 취업 시장의 피로감, 인간관계의 압박, 커뮤니티식 풍자를 섞는 방향입니다.

## 현재 구조

```text
gangnam_dream/
├── autoloads/
│   ├── DataRegistry.gd       # JSON 콘텐츠 로더와 인덱스
│   ├── GameState.gd          # 런 상태, 스탯, 돈, 플래그, 직업, 관계, 포트폴리오
│   ├── EventManager.gd       # 조건/가중치/쿨다운/연쇄 이벤트 처리
│   ├── NewsManager.gd        # 월별 한국 사회/금융 뉴스 생성
│   ├── MetaProgression.gd    # 런 히스토리, 해금, 업적, 영구 진행도
│   └── SaveManager.gd        # 자동저장 + 다중 슬롯 저장
├── content/
│   ├── events/               # 데이터 기반 이벤트 180개
│   ├── assets.json           # 투자 자산
│   ├── jobs.json             # 직업 15개
│   ├── items.json            # 아이템 30개
│   ├── endings.json          # 엔딩 10개
│   ├── news_templates.json   # 뉴스 템플릿
│   └── meta/default_meta.json
├── systems/
│   ├── InvestmentSystem.gd   # 변동성, 공포/탐욕, 버블, 폭락, 매수/매도
│   ├── JobSystem.gd          # 취업, 퇴직, 승진, 월별 스트레스
│   ├── RelationshipSystem.gd # 호감/신뢰, 관계 소멸, 패시브 효과
│   ├── InventorySystem.gd    # 구매/사용/패시브 아이템
│   └── EndingSystem.gd       # 엔딩 조회와 점수 계산
├── scenes/
│   ├── StartMenu.tscn/gd     # 시작 화면, 특성 선택, 저장 슬롯
│   └── MainGame.tscn/gd      # Football Manager식 대시보드 UI
└── ui_components/            # 재사용 UI 컴포넌트
```

## 콘텐츠 수량

- 일반 현대생활 이벤트: 100개
- 투자 이벤트: 30개
- 관계 이벤트: 30개
- 희귀/히든 이벤트: 20개
- 직업: 15개
- 아이템: 30개
- 엔딩: 10개
- 뉴스 템플릿: 79개

## 게임 루프

```text
월 시작
→ 뉴스 생성
→ 뉴스가 시장 심리와 자산 가격에 영향
→ 투자 시장 업데이트
→ 조건에 맞는 이벤트를 가중치로 선택
→ 플레이어 선택
→ 스탯/돈/관계/투자/플래그 변화
→ 직업, 관계, 아이템 월별 처리
→ 생활비와 스트레스 적용
→ 저장 및 다음 달
```

## 이벤트 데이터 형식

```json
{
  "id": "unique_event_id",
  "title": "이벤트 제목",
  "description": "상황 설명",
  "category": "finance",
  "rarity": "common",
  "weight": 1.0,
  "hidden": false,
  "conditions": {
    "min_money": 5000000,
    "max_stress": 80,
    "flag": "insider_tip"
  },
  "tags": ["finance", "anxiety"],
  "cooldown": 6,
  "choices": [
    {
      "text": "선택지",
      "effects": {
        "money": 100000,
        "mental": -3,
        "investment_skill": 2
      },
      "investment_effects": [],
      "relationship_effects": [],
      "follow_up_event": "optional_chain_id",
      "result_text": "결과 문장"
    }
  ]
}
```

## 실행 방법

1. Godot 4.6 이상을 설치합니다.
2. Godot에서 `gangnam_dream/project.godot`를 엽니다.
3. `F5` 또는 실행 버튼으로 시작합니다.

현재 이 작업 환경에는 Godot 실행 파일이 없어 CLI 실행 검증은 하지 못했습니다. JSON 파싱과 프로젝트 파일 상태는 로컬 스크립트로 검증할 수 있게 구성되어 있습니다.
