## 📌 게임 개요

- **장르**: 텍스트 기반 턴제 미로 탈출 + 이벤트 기반 스탯 관리
- **영감**: Reigns + 단순한 로그라이크
- **목표**: 8x8 미로에서 출발점→탈출구 도달
- **특징**: 빠른 템포, 단순한 시스템, 높은 재플레이성

---

## 🎯 핵심 시스템

### 🗺️ 미로 시스템
- **크기**: 고정 8x8 그리드 (총 64개 방)
- **미로 풀**: 미리 제작된 여러 미로 중 랜덤 선택
- **구조**: 시작점(0,7) → 탈출구(7,0) 경로 보장
- **이동**: 각 방의 문(door) 정보에 따라 상하좌우 이동 가능 여부 결정
- **문 시스템**: 각 방마다 4방향(북동남서) 문 존재 여부 명시
```
미로 좌표계 (8x8):
┌─────────────────────────────────────┐
│ (0,0) (1,0) (2,0) (3,0) (4,0) (5,0) (6,0) [EXIT] │
│ (0,1) (1,1) (2,1) (3,1) (4,1) (5,1) (6,1) (7,1)  │
│ (0,2) (1,2) (2,2) (3,2) (4,2) (5,2) (6,2) (7,2)  │
│ (0,3) (1,3) (2,3) (3,3) (4,3) (5,3) (6,3) (7,3)  │
│ (0,4) (1,4) (2,4) (3,4) (4,4) (5,4) (6,4) (7,4)  │
│ (0,5) (1,5) (2,5) (3,5) (4,5) (5,5) (6,5) (7,5)  │
│ (0,6) (1,6) (2,6) (3,6) (4,6) (5,6) (6,6) (7,6)  │
│[START](1,7) (2,7) (3,7) (4,7) (5,7) (6,7) (7,7)  │
└─────────────────────────────────────┘

시작점: (0,7) - 왼쪽 아래
출구점: (7,0) - 오른쪽 위
```

### 📊 플레이어 스탯 (개선)
- **HP (체력)**: 0~100, 0이 되면 게임 오버 (배드 엔딩 1)
- **SAN (정신력)**: 0~100, 0이 되면 게임 오버 (배드 엔딩 2)
- **HUNGER (허기)**: 0~100, 0이 되면 다른 모든 스탯이 0-10% 사이로 감소
- **FITNESS (운동능력)**: 0~100, 공격/방어에 가장 큰 영향, 체력/정신력에도 부분적 영향

### 🎲 이벤트 시스템
- **발생 조건**: 모든 방 입장시 강제 발생
- **효과**: 스탯 변화만 (아이템/동료 실제 획득 없음)
- **결과**: Reigns 스타일로 선택지에 따른 스탯 변화

---

## 🔄 게임 플레이 흐름

```
[게임 시작]
    ↓
[미로 랜덤 선택 + 이벤트 배치]
    ↓
[시작점(0,0)에서 시작]
    ↓
┌─ [방향 선택] ←─────────────┐
│    ↓                      │
│ [이동 실행]                │
│    ↓                      │
│ [새 방 진입]               │
│    ↓                      │
│ [이벤트 강제 발생]         │
│    ↓                      │
│ [선택지 제시]              │
│    ↓                      │
│ [결과 처리 (스탯 변화, 상태이상변화, 아이템 변화)]    │
│    ↓                      │
│ [승리/패배 조건 체크] ─────┘
    ↓
[엔딩 (스탯별 멀티엔딩)]
```



---

## 🏗️ 시스템 아키텍처

### 1️⃣ 게임 플레이 앱 (Flutter)

#### 핵심 기능
- 미로 데이터 로딩 및 렌더링
- 이벤트 데이터 파싱 및 실행
- 플레이어 스탯 관리
- UI/UX 처리

#### 폴더 구조
```
/lib
  /models
    - maze_model.dart
    - event_model.dart
    - player_model.dart
  /screens
    - game_screen.dart
    - result_screen.dart
  /services
    - data_loader.dart
    - event_processor.dart
  /widgets
    - maze_view.dart
    - stat_bar.dart
    - choice_buttons.dart
```

### 2️⃣ 데이터 파일 (JSON/CSV)

#### 🗺️ 미로 데이터 구조 (maze_data.json)
```json
{
  "mazes": [
    {
      "id": "maze_001",
      "name": "고전적인 미로",
      "size": [8, 8],
      "startPosition": [0, 7],
      "exitPosition": [7, 0],
      "rooms": [
        {
          "x": 0,
          "y": 7,
          "doors": {
            "north": false,
            "south": false,
            "east": true,
            "west": false
          },
          "isStart": true,
          "isExit": false
        },
        {
          "x": 1,
          "y": 7,
          "doors": {
            "north": true,
            "south": false,
            "east": false,
            "west": true
          },
          "isStart": false,
          "isExit": false
        },
        {
          "x": 7,
          "y": 0,
          "doors": {
            "north": false,
            "south": true,
            "east": false,
            "west": false
          },
          "isStart": false,
          "isExit": true
        }
      ],

**대안: 압축된 문자열 형태**
```json
{
  "mazes": [
    {
      "id": "maze_002", 
      "name": "압축 형태 미로",
      "size": [8, 8],
      "startPosition": [0, 7],
      "exitPosition": [7, 0],
      "roomData": "0111,1010,0100,1001,0110,1100,0011,1111,...",
      "description": "각 방의 문 정보를 4비트로 압축 (북동남서 순서)"
    }
  ]
}
```

## 📋 **최종 통합 이벤트 데이터 구조**

### 🎲 **events_master.json (모든 이벤트 통합)**
```json
  "events": {
    "character_shadow_first_encounter_01": {
      "id": "character_shadow_first_encounter_01",
      "npcId": "shadow",
      "name": "첫 만남",
      "description": "어두운 구석의 그림자가 사람의 형상으로 피어오른다. 형체 없는 목소리가 당신의 머릿속에 직접 울린다. \"...왔는가. 길 잃은 자여.\"",
      "image": "character_shadow_form.png",
      "category": "character",
      "weight": 10,
      "persistence": "oneTime",
      "choices": [
        {
          "text": "당신은 누구냐고 묻는다.",
          "requirements": null,
          "successEffects": {
            "description": "\"나는 메아리이자, 거울이며, 너 자신이다.\" 그림자는 이해할 수 없는 말을 남기고 스르르 사라진다. 머리가 혼란스럽다.",
            "statChanges": { "SAN": -15 },
            "applyStatus": ["dizziness"]
          }
        },
        {
          "text": "아무 말 없이 그를 응시한다.",
          "requirements": null,
          "successEffects": {
            "description": "당신의 침묵에 그림자가 고개를 끄덕이는 듯하다. \"...언어는 때로 진실을 가리는 장막.\" 그림자가 사라진 자리에, 오래된 일기장이 놓여 있다.",
            "statChanges": { "SAN": 5 },
            "itemsGained": ["old_diary"]
          }
        }
      ]
    },
    "character_shadow_riddle_of_choice_01": {
      "id": "character_shadow_riddle_of_choice_01",
      "npcId": "shadow",
      "name": "선택의 수수께끼",
      "description": "그림자가 두 갈래 길 앞에 나타난다. \"하나는 끝으로, 하나는 시작으로 이어진다. 어느 쪽을 택하겠는가?\"",
      "image": "character_shadow_crossroads.png",
      "category": "character",
      "weight": 8,
      "persistence": "oneTime",
      "choices": [
        {
          "text": "'끝'을 선택한다.",
          "requirements": null,
          "successEffects": {
            "description": "당신이 그 길로 들어서자, 막다른 길에 구급상자가 놓여있다. \"...모든 끝은 새로운 시작을 위한 준비.\" 그림자의 목소리가 들려온다.",
            "statChanges": { "SAN": 10 },
            "itemsGained": ["first_aid_kit"]
          }
        },
        {
          "text": "'시작'을 선택한다.",
          "requirements": null,
          "successEffects": {
            "description": "당신이 그 길로 들어서자, 이전에 왔던 방으로 되돌아왔다. \"...모든 시작은 과거의 반복일 뿐.\" 그림자의 비웃음이 들리는 듯하다.",
            "statChanges": { "SAN": -10, "HUNGER": -3 }
          }
        }
      ]
    },
   "item_discovery_first_aid_kit": {
      "id": "item_discovery_first_aid_kit",
      "name": "구급상자 발견",
      "description": "벽에 기대어 놓인, 붉은 십자가가 선명한 구급상자를 발견했다.",
      "image": "discovery_first_aid_kit.png",
      "category": "item", "weight": 20, "persistence": "oneTime",
      "choices": [
        {
          "text": "챙긴다", "successEffects": {
            "description": "든든한 의료용품을 손에 넣었다.",
            "statChanges": { "SAN": 5 }, "itemsGained": ["first_aid_kit"]
          }
        },
        {"text": "그냥 둔다", "successEffects": {"description": "누군가 더 필요한 사람이 있을지도 모른다."}}
      ]
    },
    "monster_spider_sleeping_01": {
      "id": "monster_spider_sleeping_01",
      "name": "잠자는 동굴 거미",
      "description": "거대한 동굴 거미가 거미줄 위에서 잠들어 있다. 주변에는 먹이의 잔해로 보이는 꾸러미들이 널려 있다.",
      "image": "monster_spider.png",
      "category": "monster",
      "weight": 10,
      "persistence": "oneTime",
      "choices": [
        {
          "text": "조용히 지나간다.",
          "requirements": null,
          "successConditions": { "stats": { "FITNESS": { "operator": ">", "value": 30 } } },
          "successEffects": {
            "description": "숨을 죽이고 발소리를 내지 않은 채 무사히 통과했다.",
            "statChanges": { "SAN": 5, "HUNGER": -1 }
          },
          "failureEffects": {
            "description": "발을 헛디뎌 거미를 깨우고 말았다! 분노한 거미에게 다리를 물렸다.",
            "statChanges": { "HP": -10, "SAN": -5 },
            "applyStatus": ["dizziness"]
          }
        },
        {
          "text": "먹이 꾸러미를 훔친다.",
          "requirements": null,
          "successConditions": { "stats": { "FITNESS": { "operator": ">", "value": 50 } } },
          "successEffects": {
            "description": "재빠르게 움직여 꾸러미 하나를 훔치는 데 성공했다! 안에는 정체불명의 육포가 들어있었다.",
            "statChanges": { "SAN": 3 },
            "itemsGained": ["mystery_jerky"]
          },
          "failureEffects": {
            "description": "꾸러미를 건드리자 거미가 깨어나 맹독을 뱉었다.",
            "statChanges": { "HP": -15 },
            "applyStatus": ["hallucination"]
          }
        }
      ]
```


## 🎭 **상태이상 시스템 (별도 관리)**

### 📊 **플레이어 상태이상 데이터 구조**
```json
{
  "statusConditions": {
    "extreme_hunger": {
      "id": "extreme_hunger",
      "name": "극심한 배고픔",
      "type": "negative",
      "trigger": {
        "condition": {"HUNGER": {"operator": "<=", "value": 10}},
        "automatic": true
      },
      "effects": {
        "ongoing": {"FITNESS": -20, "SAN": -5},
        "movement": {"penalty": 0.5}
      },
      "duration": "until_hunger_above_20",
      "stackable": false,
      "priority": 1,
      "description": "배가 너무 고파서 제대로 움직일 수 없다.",
      "icon": "hunger_critical.png",
      "removedBy": ["eat_food", "hunger_increase"]
    },
    "hallucination": {
      "id": "hallucination", 
      "name": "환각 증상",
      "type": "mental",
      "trigger": {
        "condition": {"SAN": {"operator": "<=", "value": 20}},
        "automatic": true
      },
      "effects": {
        "ongoing": {"SAN": -3, "HP": -2},
        "eventDistortion": true,
        "choiceConfusion": 0.3
      },
      "duration": 5,
      "stackable": true,
      "priority": 2,
      "description": "현실과 환상이 구분되지 않는다.",
      "icon": "hallucination.png",
      "removedBy": ["rest", "medical_treatment"]
    },
    "sugar_high": {
      "id": "sugar_high",
      "name": "슈가 하이",
      "type": "temporary_positive",
      "trigger": {
        "condition": "consume_sweet_item",
        "automatic": false
      },
      "effects": {
        "ongoing": {"FITNESS": 15, "SAN": 10, "HUNGER": -5},
        "movement": {"bonus": 1.2}
      },
      "duration": 3,
      "stackable": false,
      "priority": 3,
      "description": "당분 섭취로 일시적으로 기분이 좋아졌다.",
      "icon": "sugar_high.png",
      "removedBy": ["time", "physical_exertion"]
    },
    "fatigue": {
      "id": "fatigue",
      "name": "피곤함",
      "type": "physical",
      "trigger": {
        "condition": "excessive_activity",
        "automatic": false
      },
      "effects": {
        "ongoing": {"FITNESS": -10, "SAN": -2},
        "actionRestrictions": ["no_running", "reduced_combat"]
      },
      "duration": 8,
      "stackable": true,
      "maxStacks": 3,
      "priority": 2,
      "description": "몸이 무겁고 피곤하다.",
      "icon": "fatigue.png",
      "removedBy": ["rest", "sleep"]
    },
    "stomach_ache": {
      "id": "stomach_ache",
      "name": "배탈",
      "type": "illness",
      "trigger": {
        "condition": "consume_bad_food",
        "automatic": false
      },
      "effects": {
        "ongoing": {"HP": -5, "SAN": -8, "HUNGER": -3},
        "foodRestriction": true
      },
      "duration": 6,
      "stackable": false,
      "priority": 2,
      "description": "배가 아파서 음식을 먹기 힘들다.",
      "icon": "stomach_ache.png",
      "removedBy": ["medicine", "time", "rest"]
    },
    "headache": {
      "id": "headache",
      "name": "두통",
      "type": "mental_physical",
      "trigger": {
        "condition": {"SAN": {"operator": "<", "value": 40}},
        "automatic": true,
        "probability": 0.3
      },
      "effects": {
        "ongoing": {"SAN": -5, "FITNESS": -5},
        "concentrationPenalty": 0.2
      },
      "duration": 4,
      "stackable": false,
      "priority": 1,
      "description": "머리가 지끈지끈 아프다.",
      "icon": "headache.png",
      "removedBy": ["painkillers", "rest", "recovery"]
    }
  },
  
  "statusSystem": {
    "maxActiveConditions": 5,
    "checkTriggers": "every_turn",
    "stackingRules": {
      "same_condition": "depends_on_stackable_property",
      "conflicting_conditions": "higher_priority_wins",
      "beneficial_harmful": "both_can_coexist"
    },
    "removalConditions": {
      "automatic": "time_based_or_stat_recovery",
      "item_based": "specific_items_can_cure",
      "action_based": "rest_or_special_actions"
    }
  }
}
```

#### 🎬 인트로 데이터 구조 (intro_data.json)
```json
{
  "introSequence": {
    "id": "main_intro",
    "title": "Maze Reigns",
    "autoAdvance": false,
    "scenes": [
      {
        "id": "scene_01",
        "type": "narrative",
        "background": "dark_corridor.jpg",
        "music": "intro_ambient.mp3",
        "text": "당신은 어둠 속에서 눈을 뜹니다...",
        "textStyle": {
          "color": "white",
          "size": "large",
          "animation": "fadeIn"
        },
        "skipable": true
      },
      {
        "id": "scene_02", 
        "type": "narrative",
        "background": "maze_entrance.jpg",
        "music": "intro_ambient.mp3",
        "text": "앞에는 거대한 미로가 펼쳐져 있고, 뒤돌아볼 길은 이미 사라져버렸습니다.",
        "textStyle": {
          "color": "white",
          "size": "large", 
          "animation": "fadeIn"
        },
        "skipable": true
      },
      {
        "id": "scene_03",
        "type": "character_stats",
        "background": "status_display.jpg",
        "music": "intro_ambient.mp3",
        "text": "왜 이곳에 있는지는 기억이 나지 않지만, 하나만은 알 수 있었다. 살아야 한다. 그리고 살려면 저 미로의 끝까지 가야한다.",
        "textStyle": {
          "color": "yellow",
          "size": "large",
          "animation": "typewriter"
        },
        "skipable": true
      },
      {
        "id": "scene_04",
        "type": "call_to_action",
        "background": "maze_start.jpg", 
        "music": "intro_ambient.mp3",
        "text": "생존하여 이 미로에서 탈출하세요!",
        "textStyle": {
          "color": "white",
          "size": "large", 
          "animation": "fadeIn"
        },
        "skipable": true
      }
    ]
  }
}
```

#### 🎭 멀티 씬 엔딩 데이터 구조 (endings_data.json)
```json
{
  "endings": [
    {
      "id": "perfect_escape",
      "title": "완벽한 탈출",
      "type": "good",
      "totalScenes": 3,
      "conditions": {
        "reachedExit": true,
        "AND": [
          {"HP": {"operator": ">", "value": 70}},
          {"SAN": {"operator": ">", "value": 60}},
          {"HUNGER": {"operator": ">", "value": 50}},
          {"FITNESS": {"operator": ">", "value": 60}}
        ]
      },
      "scenes": [
        {
          "id": "perfect_01",
          "type": "narrative",
          "duration": 4000,
          "background": "exit_found.jpg",
          "music": "victory_theme.mp3",
          "text": "마침내 출구를 발견했습니다!",
          "textStyle": {
            "color": "gold",
            "size": "large",
            "animation": "slideUp"
          }
        },
        {
          "id": "perfect_02",
          "type": "character_reflection",
          "duration": 5000,
          "background": "character_triumphant.jpg",
          "music": "victory_theme.mp3",
          "text": "당신은 모든 시련을 극복하고 완벽한 상태로 탈출에 성공했습니다.",
          "showFinalStats": true,
          "textStyle": {
            "color": "white",
            "size": "medium",
            "animation": "fadeIn"
          }
        },
        {
          "id": "perfect_03",
          "type": "epilogue",
          "duration": -1,
          "background": "outside_world.jpg",
          "music": "peaceful_theme.mp3",
          "text": "밖의 세상이 당신을 기다리고 있습니다. 이 경험은 당신을 더욱 강하게 만들었습니다.",
          "textStyle": {
            "color": "white",
            "size": "medium",
            "animation": "typewriter"
          },
          "achievements": ["perfect_survivor", "mental_fortitude", "physical_excellence"],
          "button": {
            "text": "새 게임",
            "action": "newGame"
          }
        }
      ]
    },
    {
      "id": "death_by_injury",
      "title": "부상으로 인한 죽음",
      "type": "bad_ending_1",
      "totalScenes": 4,
      "conditions": {
        "HP": {"operator": "<=", "value": 0}
      },
      "scenes": [
        {
          "id": "death_01",
          "type": "narrative",
          "duration": 3000,
          "background": "collapse.jpg",
          "music": "tragic_theme.mp3",
          "text": "당신의 몸이 한계에 달했습니다...",
          "textStyle": {
            "color": "red",
            "size": "large",
            "animation": "shake"
          }
        },
        {
          "id": "death_02",
          "type": "flashback",
          "duration": 4000,
          "background": "memories.jpg",
          "music": "melancholic_theme.mp3",
          "text": "미로에서의 여정이 스쳐 지나갑니다...",
          "showJourney": true,
          "textStyle": {
            "color": "gray",
            "size": "medium",
            "animation": "fadeInOut"
          }
        },
        {
          "id": "death_03",
          "type": "final_moment",
          "duration": 5000,
          "background": "darkness.jpg",
          "music": "silence.mp3",
          "text": "의식이 흐려지며 어둠이 찾아옵니다...",
          "textStyle": {
            "color": "darkgray",
            "size": "small",
            "animation": "fadeOut"
          }
        },
        {
          "id": "death_04",
          "type": "game_over",
          "duration": -1,
          "background": "game_over.jpg",
          "music": "game_over_theme.mp3",
          "text": "게임 오버",
          "textStyle": {
            "color": "red",
            "size": "huge",
            "animation": "none"
          },
          "showStats": true,
          "showPlayTime": true,
          "buttons": [
            {
              "text": "다시 시도",
              "action": "restart"
            },
            {
              "text": "메인 메뉴",
              "action": "mainMenu"
            }
          ]
        }
      ]
    },
    {
      "id": "mental_breakdown",
      "title": "정신적 붕괴",
      "type": "bad_ending_2",
      "totalScenes": 3,
      "conditions": {
        "SAN": {"operator": "<=", "value": 0}
      },
      "scenes": [
        {
          "id": "breakdown_01",
          "type": "distorted_reality",
          "duration": 4000,
          "background": "distorted_maze.jpg",
          "music": "distorted_sounds.mp3",
          "text": "현실과 환상의 경계가 흐려집니다...",
          "textStyle": {
            "color": "purple",
            "size": "large",
            "animation": "glitch"
          },
          "visualEffects": ["static_noise", "color_distortion"]
        },
        {
          "id": "breakdown_02",
          "type": "inner_voice",
          "duration": 5000,
          "background": "mind_space.jpg",
          "music": "whispers.mp3", 
          "text": "내면의 목소리들이 당신을 압도합니다...",
          "textStyle": {
            "color": "white",
            "size": "medium",
            "animation": "multiple_voices"
          },
          "multipleTexts": [
            "나갈 수 없어...",
            "포기해...",
            "이게 현실이야..."
          ]
        },
        {
          "id": "breakdown_03",
          "type": "lost_in_mind",
          "duration": -1,
          "background": "void.jpg",
          "music": "eerie_silence.mp3",
          "text": "당신은 자신의 마음 속 미로에서 길을 잃었습니다...",
          "textStyle": {
            "color": "lightgray",
            "size": "medium",
            "animation": "echo"
          },
          "buttons": [
            {
              "text": "다시 시도",
              "action": "restart"
            },
            {
              "text": "메인 메뉴", 
              "action": "mainMenu"
            }
          ]
        }
      ]
    }
  ]
}
```


## 🎮 UI/UX 설계 (단순화)

### 📱 메인 게임 화면
스탯: HP, SAN, FIT, HUNGER
```
┌─────────────────────────────────────────┐
│ HP:██████████   SAN:████████            │
│ FIT:████████     HUNGER:                │
├─────────────────────────────────────────┤
│                                         │
│        [이벤트 일러스트]                  │
│                                         │
│                                         │
│                                         │
│                                         │
│                                         │
│                                         │
│                                         │
│                                         │
│  "어둠 속에서 무언가가 으르렁거린다..."      │
│                                         │
├─────────────────────────────────────────┤
│  [용감하게 맞선다]  [도망친다]          │
│  [숨어서 기다린다]                      │
└─────────────────────────────────────────┘
```

### 🗺️ 미니맵 (옵션)
선택지에서 선택하기 전
오른쪽에서 왼쪽으로 스와이프 했을 때 미니맵 표시.
- 8x8 그리드로 방문한 곳만 표시. 방문된 곳은 문의 위치도 표시
- 방문한 곳에 함정이 있을 경우 함정 아이콘 표시
- 현재 위치와 탈출구 위치 표시

선택지에서 선택하기 전
왼쪽에서 오른쪽으로 스와이프 했을 때 아이템 표시
- 아이템은 최대 5개.
- 사용하면 사라지는 아이템과 사라지지 않는 아이템이 있다.
- 어떤 아이템이든 버릴 수 있다.

---

## 💾 **세이브/로드 시스템**

### 📁 **게임 상태 데이터 구조 (세이브/로드용)**
```json
{
  "saveData": {
    "gameInfo": {
      "saveId": "save_001",
      "playerName": "플레이어",
      "saveDate": "2025-08-08T15:30:00Z",
      "gameVersion": "1.0.0",
      "playtime": 1234567,
      "difficulty": "normal"
    },
    "gameState": {
      "currentMaze": {
        "mazeId": "maze_001",
        "currentPosition": [3, 5],
        "visitedRooms": [
          [0,7], [1,7], [2,7], [2,6], [3,6], [3,5]
        ],
        "roomEventHistory": {
          "0,7": {
            "triggeredEvents": ["empty_room"],
            "consumedOneTimeEvents": ["first_aid_kit"],
            "lastEventTurn": 3
          },
          "1,7": {
            "triggeredEvents": ["rabbit_monster"],
            "consumedOneTimeEvents": ["rabbit_monster"],
            "lastEventTurn": 5
          },
          "2,7": {
            "triggeredEvents": ["pit_trap", "pit_trap"],
            "persistentEvents": ["pit_trap"],
            "lastEventTurn": 8
          }
        },
        "roomVisitCount": {
          "0,7": 1,
          "1,7": 2, 
          "2,7": 3
        },
        "respawningEvents": {
          "3,4": {
            "eventId": "insect_monster",
            "lastDefeated": 5,
            "respawnTurn": 13
          },
          "1,2": {
            "eventId": "water_source", 
            "lastUsed": 7,
            "respawnTurn": 12
          }
        }
      },
      "playerStats": {
        "HP": 75,
        "SAN": 60,
        "HUNGER": 45,
        "FITNESS": 80
      },
      "activeStatusConditions": [
        {
          "id": "headache",
          "remainingDuration": 2,
          "stacks": 1,
          "appliedTurn": 10
        },
        {
          "id": "sugar_high",
          "remainingDuration": 1,
          "stacks": 1,
          "appliedTurn": 11
        }
      ],
      "npcStates": {
        "survivor_alex": {
          "position": [2, 4],
          "relationship": 1.5,
          "lastInteraction": 3,
          "isAlive": true,
          "hasMetPlayer": true
        },
        "mysterious_figure": {
          "position": [5, 3],
          "relationship": -0.5,
          "lastInteraction": 1,
          "isAlive": true,
          "hasMetPlayer": false
        }
      },
      "gameProgress": {
        "turnCount": 12,
        "totalMoves": 15,
        "eventsTriggered": 8,
        "startTime": "2025-08-08T15:20:00Z"
      },
      "eventPool": {
        "globallyConsumedEvents": ["tutorial_event", "special_discovery"],
        "eventCooldowns": {
          "rare_treasure": 10,
          "mysterious_voice": 5
        }
      }
    },
    "settings": {
      "soundEnabled": true,
      "musicEnabled": true,
      "textSpeed": "normal",
      "autoSave": true
    }
  }
}
```

### 🔄 **세이브/로드 메커니즘**

#### 자동 저장
- **방 이동시**: 새로운 방에 진입할 때마다 자동 저장
- **이벤트 완료시**: 선택지 결과 적용 후 자동 저장
- **게임 일시정지시**: 앱이 백그라운드로 갈 때 자동 저장


#### 로드 기능
- **게임 시작시**: 새게임과 이어하기 선택. 이어하기는 마지막으로 플레이한 게임이 엔딩을 보기전이라면 이어할 수 있음. 그렇지 않으면 "이어할 게임이 없습니다." 메세지 표시
- **데이터 검증**: 로드시 세이브 파일 무결성 확인


### 🛡️ **데이터 무결성 보장**
```json
{
  "dataValidation": {
    "checksum": "SHA256_HASH",
    "version": "1.0.0",
    "mandatory_fields": [
      "gameState.playerStats",
      "gameState.currentMaze.currentPosition",
      "gameState.currentMaze.mazeId"
    ],
    "stat_ranges": {
      "HP": [0, 100],
      "SAN": [0, 100], 
      "HUNGER": [0, 100],
      "FITNESS": [0, 100]
    },
    "position_validation": {
      "x_range": [0, 7],
      "y_range": [0, 7]
    }
  }
}
```


### 🎲 **이벤트 선택 알고리즘**
1. **확률적 선택**: 가중치 기반 랜덤 선택
2. **최대 3개 선택지**: 각 이벤트는 최대 3개의 선택지만 제공

### 게임 길이
- **평균 플레이 시간**: 5-10분



## 🎲 **이벤트 분배 시스템**

### 📊 **62개 방 이벤트 분배 비율**
```json
{
  "eventDistribution": {
    "totalRooms": 62,
    "distributionStrategy": "balanced_difficulty_curve",
    
    "baseDistribution": {
      "empty_neutral": {
        "count": 18,
        "percentage": 29,
        "description": "빈 방, 휴식 공간, 중립적 환경 이벤트"
      },
      "items": {
        "count": 12,
        "percentage": 19,
        "description": "유용한 아이템들 (구급상자, 물, 음식 등)"
      },
      "monsters": {
        "count": 10,
        "percentage": 16,
        "description": "약한 몬스터들 (토끼, 곤충 등)"
      },
      "traps": {
        "count": 8,
        "percentage": 13,
        "description": "다양한 함정들"
      },
      "characters": {
        "count": 4,
        "percentage": 6,
        "description": "NPC 캐릭터들"
      }
    },
}
```


### 🎮 **플레이테스트 기반 조정**
```json
{
  "playtestMetrics": {
    "target_completion_rate": "60-80%",
    "average_playtime": "15-25분",
    "resource_exhaustion_rate": "< 20%",
    "player_satisfaction_indicators": [
      "적절한 도전감",
      "의미있는 선택들", 
      "공정한 난이도",
      "재플레이 욕구"
    ]
  },
  
  "adjustment_triggers": {
    "too_easy": {
      "indicators": ["완주율 > 90%", "평균 플레이타임 < 10분"],
      "adjustments": ["위험 이벤트 증가", "자원 감소", "함정 추가"]
    },
    "too_hard": {
      "indicators": ["완주율 < 40%", "조기 포기율 > 50%"],
      "adjustments": ["치료 아이템 증가", "안전한 방 추가", "위험 감소"]
    },
    "too_boring": {
      "indicators": ["재플레이율 < 30%", "플레이타임 편차 작음"],
      "adjustments": ["이벤트 다양성 증가", "랜덤 요소 강화"]
    }
  }
}
```






# 🎒 아이템 시스템 설계 - 미로 탈출 게임

## 📋 아이템 시스템 개요

### 🎯 핵심 설계 원칙
- **단순함**: 복잡한 조합이나 강화 시스템 없음
- **즉시성**: 발견 즉시 사용 또는 보관 선택
- **제한성**: 인벤토리 최대 5개로 관리의 재미
- **의미성**: 모든 아이템이 상황별로 유용함

### 🎒 인벤토리 시스템
- **최대 보관**: 5개 아이템
- **사용 방식**: 
  - 즉시 사용 (아이템 소모)
  - 보관 후 나중 사용
  - 버리기 (공간 확보)

특정 아이템은 상태이상을 치료하거나 부여할 수 있다.
---

## 🗂️ 아이템 데이터 구조



### 📊 items_database.json
```json
{
  "metadata": {
    "version": "1.0.0",
    "totalItems": 50,
    "lastUpdated": "2025-08-08",
    "categories": ["medical", "food", "tool", "special", "weapon"]
  },
  
  "items": {
    "first_aid_kit": {
      "id": "first_aid_kit",
      "name": "구급상자",
      "image": "first_aid_kit.png",
      "description": "상처를 치료할 수 있는 의료용품이 들어있다.",
      "consumeOnUse": true,
      "effects": {
        "immediate": {
          "HP": 25,
          "SAN": 5,
          "HUNGER": -1,
          "FITNESS": 0
        },
        "requirements": null,
        "cooldown": 0
      },
      "flavorText": "붕대와 소독약의 냄새가 난다."
    },

    "energy_bar": {
      "id": "energy_bar",
      "name": "에너지바",
      "image": "energy_bar.png",
      "description": "달콤하고 영양가 있는 간식.",
      "consumeOnUse": true,
      "effects": {
        "immediate": {
          "HP": 5,
          "SAN": 8,
          "HUNGER": 20,
          "FITNESS": 3
        },
        "statusEffect": {
          "id": "sugar_high",
          "duration": 2,
          "probability": 0.4
        }
      },
      "flavorText": "초콜릿과 견과류가 들어있다."
    },

    "water_bottle": {
      "id": "water_bottle",
      "name": "물병",
      "image": "water_bottle.png",
      "description": "깨끗한 식수가 담긴 병.",
      "consumeOnUse": true,
      "effects": {
        "immediate": {
          "HP": 3,
          "SAN": 10,
          "HUNGER": 15,
          "FITNESS": 2
        },
        "statusEffect": {
          "removes": ["dehydration", "fatigue"],
          "probability": 0.8
        }
      },
      "flavorText": "차가운 물이 목을 적신다."
    },

    "flashlight": {
      "id": "flashlight",
      "name": "손전등",
      "image": "flashlight.png",
      "description": "어둠을 밝혀주는 도구.",
      "consumeOnUse": false,
      "effects": {
        "passive": {
          "SAN": 5,
          "FITNESS": 1,
          "HP": -2
        }
      },
      "flavorText": "배터리 표시등이 깜빡인다."
    },

    "rope": {
      "id": "rope",
      "name": "밧줄",
      "image": "rope.png",
      "description": "튼튼한 나일론 밧줄.",
      "effects": {
        "passive": {
          "FITNESS": 4,
          "HP": -2,
          "HUNGER": -1 
        }
      },
      "flavorText": "10미터 정도의 길이로 보인다."
    },

    "lucky_coin": {
      "id": "lucky_coin",
      "name": "행운의 동전",
      "image": "lucky_coin.png",
      "description": "신비로운 힘이 깃든 것 같은 동전.",
      "consumeOnUse": false,
      "effects": {
        "passive": {
          "KARMA": -10, 
          "SAN": -5
        }
      },
      "flavorText": "만지면 따뜻한 기운이 느껴진다."
    },

    "protein_bar": {
      "id": "protein_bar",
      "name": "단백질바",
      "stackable": true,
      "image": "protein_bar.png",
      "description": "근육 회복에 도움되는 영양 보충제.",
      "usageType": "immediate_or_store",
      "consumeOnUse": true,
      "effects": {
        "immediate": {
          "HP": 8,
          "SAN": 3,
          "HUNGER": 25,
          "FITNESS": 8
        },
        "statusEffect": {
          "id": "muscle_recovery",
          "duration": 3,
          "probability": 0.5
        }
      },
      "usageConditions": {
        "canUseWhen": ["any_time"],
        "combatUsable": true
      },
      "flavorText": "운동선수들이 즐겨먹는다는 그것."
    },

    "painkillers": {
      "id": "painkillers",
      "name": "진통제",
      "image": "painkillers.png",
      "description": "통증을 완화시키는 의약품.",
      "consumeOnUse": true,
      "effects": {
        "immediate": {
          "HP": 15,
          "SAN": 12,
          "FITNESS": -3
        },
        "statusEffect": {
          "removes": ["headache", "muscle_pain", "fatigue"],
          "probability": 0.9
        }
      },
      "sideEffects": {
        "probability": 0.1,
        "effects": {
          "SAN": -5,
          "FITNESS": -5,
          "description": "약간의 어지러움을 느낀다."
        }
      },
      "flavorText": "처방전 없이도 구매할 수 있는 종류다."
    },

    "multitool": {
      "id": "multitool",
      "name": "멀티툴",
      "description": "다양한 도구가 하나로 합쳐진 만능 도구.",
      "consumeOnUse": false,
      "effects": {
        "passive": {
          "SAN": 5,
          "KARMA": -2
        },
      },
      "flavorText": "칼, 드라이버, 플라이어 등이 들어있다."
    },

    "energy_drink": {
      "id": "energy_drink",
      "name": "에너지 드링크",
      "image": "energy_drink.png",
      "description": "각성 효과가 있는 음료.",
      "consumeOnUse": true,
      "effects": {
        "immediate": {
          "HP": 3,
          "SAN": 15,
          "HUNGER": 10,
          "FITNESS": 12
        },
        "statusEffect": {
          "id": "caffeine_boost",
          "duration": 4,
          "probability": 0.8
        }
      },
      "sideEffects": {
        "probability": 0.3,
        "effects": {
          "SAN": -8,
          "FITNESS": -10,
          "description": "나중에 급격한 피로감을 느낀다."
        }
      },
      "flavorText": "타우린과 카페인이 가득하다."
    }
  }
}
```


---

## 🎮 아이템 이벤트 통합

### 🔗 item_events.json
```json
{
  "itemDiscoveryEvents": {
    "item_first_aid_01": {
      "id": "item_first_aid_01",
      "category": "item",
      "subcategory": "medical",
      "threatLevel": -2,
      "persistence": "oneTime",
      "weight": 15,
      "image": "first_aid_discovery.png",
      "name": "구급상자 발견",
      "description": "구석에서 먼지가 쌓인 구급상자를 발견했다.",
      "itemReward": "first_aid_kit",
      "choices": [
        {
          "text": "즉시 사용한다",
          "requirements": null,
          "effects": {"HP": 25, "SAN": 5, "HUNGER": -1},
          "description": "상처를 바로 치료했다.",
          "itemConsumed": true
        },
        {
          "text": "보관한다",
          "requirements": {"inventory_space": {"operator": ">", "value": 0}},
          "effects": {"SAN": 3, "HUNGER": -1},
          "description": "나중을 위해 챙겨두었다.",
          "itemConsumed": false,
          "addToInventory": "first_aid_kit"
        },
        {
          "text": "버린다",
          "requirements": null,
          "effects": {"SAN": -2, "HUNGER": -1},
          "description": "의심스러워서 그냥 두고 갔다.",
          "itemConsumed": true
        }
      ]
    },

    "item_energy_bar_01": {
      "id": "item_energy_bar_01", 
      "category": "item",
      "subcategory": "food",
      "threatLevel": -1,
      "persistence": "oneTime",
      "weight": 20,
      "image": "energy_bar_discovery.png",
      "name": "에너지바 발견",
      "description": "누군가 떨어뜨린 듯한 에너지바를 발견했다.",
      "itemReward": "energy_bar",
      "choices": [
        {
          "text": "즉시 먹는다",
          "requirements": null,
          "effects": {"HP": 5, "SAN": 8, "HUNGER": 20, "FITNESS": 3},
          "description": "달콤한 맛이 기운을 북돋운다.",
          "itemConsumed": true,
          "statusChance": {"sugar_high": 0.4}
        },
        {
          "text": "보관한다",
          "requirements": {"inventory_space": {"operator": ">", "value": 0}},
          "effects": {"SAN": 2, "HUNGER": -1},
          "description": "나중에 필요할 때를 위해 보관했다.",
          "itemConsumed": false,
          "addToInventory": "energy_bar"
        },
        {
          "text": "의심스러워 버린다",
          "requirements": null,
          "effects": {"SAN": -1, "HUNGER": -2},
          "description": "누가 일부러 놓은 건 아닐까...",
          "itemConsumed": true
        }
      ]
    }
  }
}
```

## 상태이상 
상태이상은 일정기간동안 스탯에 영향을 주며, 시간이 지나면 사라진다. 
단 특정 아이템은 상태이상을 치료할 수 있다.



### 종류

배탈: HP-5, FIT-5, 3 TURNS
두통: SAT -5, FIT-5, 3 TURN
탈수: HP-5, HUNGER-5, 3 TURNS
중독: 
어지러움
카페인 부스트
슈가 하이



---

## 🎮 UI/UX 아이템 표시

### 📱 인벤토리 화면 레이아웃
```
┌─────────────────────────────────────────┐
│ 인벤토리 (3/5)               [정렬 ▼]  │
├─────────────────────────────────────────┤
│ [🏥] 구급상자              [사용] [버림] │
│     상처를 치료할 수 있다               │
├─────────────────────────────────────────┤  
│ [🍫] 에너지바 x2           [사용] [버림] │
│     달콤하고 영양가 있는 간식           │
├─────────────────────────────────────────┤
│ [🔦] 손전등               [사용] [버림] │
│     어둠을 밝혀주는 도구 (전용)        │
├─────────────────────────────────────────┤
│ [ + ] 빈 슬롯                          │
├─────────────────────────────────────────┤
│ [ + ] 빈 슬롯                          │
└─────────────────────────────────────────┘
```


---

## 🔄 게임플레이 통합

### 🎯 아이템이 게임플레이에 미치는 영향

1. **전략적 선택**: 즉시 사용 vs 보관
2. **자원 관리**: 제한된 인벤토리 공간
3. **상황 대응**: 특정 이벤트에서 아이템 활용
4. **리스크 관리**: 아이템으로 위험 상황 극복

### 🎲 아이템 기반 특수 선택지
- 손전등 보유시: 어두운 방에서 추가 선택지
- 밧줄 보유시: 함정에서 안전한 선택지
- 멀티툴 보유시: 기계적 문제 해결 선택지
- 행운의 동전: 모든 확률 이벤트에 보너스