# Worry Parking (걱정 주차장)

자기 전 걱정을 "주차"해두면, 지정한 **Worry Time**까지 숨겨뒀다가 출차 알림으로 돌려주는 iOS 앱.
CBT의 걱정 미루기(worry postponement / scheduled worry) 기법을 주차장 메타포로 제품화했습니다.

## 요구사항
- Xcode 16 이상 (폴더 동기화 그룹 형식, objectVersion 77)
- iOS 17.0+ / iPhone 전용 / SwiftUI + SwiftData + StoreKit 2 + Swift Charts
- 외부 의존성 없음

## 실행
1. `WorryParking.xcodeproj` 열기
2. Target ▸ Signing & Capabilities 에서 Team 선택 (Bundle ID: `com.devkoan.worryparking`)
3. 시뮬레이터에서 Run — 스킴에 `Products.storekit`이 연결돼 있어 구독 결제를 로컬에서 테스트할 수 있습니다.
   - 연결이 안 돼 있으면: Product ▸ Scheme ▸ Edit Scheme ▸ Run ▸ Options ▸ StoreKit Configuration ▸ `Products.storekit`

## 주차장 컨셉 매핑
| 앱 기능 | 주차장 메타포 |
|---|---|
| 걱정 작성 | 주차권 발급 (차단기 올라가는 애니메이션) |
| 걱정 숨김 | 주차된 차 — 주차권 내용은 블러 처리, "지금은 네 일이 아니야" |
| Worry Time 알림 | "P3 출차 준비 완료" (알림에 걱정 내용은 절대 포함 안 함) |
| 검토 세션 | 출차 게이트 — 15분 타이머, "실제로 일어났나?", 현재 강도, 처리 방식 |
| 처리 방식 | 떠나보내기 / 다음 행동 계획 / 재주차 |
| 기록 | Exit Log — 이력 + 인사이트 ("걱정의 N%는 일어나지 않았음") |

## 수익화 ($3.99/월)
- 제품 ID: `com.devkoan.worryparking.pro.monthly` (1주 무료 체험 포함, StoreKit 설정 파일 기준)
- 무료: 동시 주차 3칸, Worry Time 기반 출차 시간
- Pro: 무제한 주차 칸, 사용자 지정 출차 시간, Exit 인사이트(차트)
- 페이월은 `SubscriptionStoreView` 사용 → App Store Connect에 같은 ID로 구독 상품만 만들면 그대로 동작

## 현지화
- 영어(기본) + 한국어. `WorryParking/Localizable.xcstrings`(UI), `InfoPlist.xcstrings`(앱 이름: 걱정 주차장)
- 새 문자열은 `Text("...")` 리터럴 또는 `String(localized:)`로 작성하면 빌드 시 카탈로그에 자동 추출됩니다.
- 시뮬레이터에서 확인: Scheme ▸ Run ▸ Options ▸ App Language ▸ Korean

## 구조
```
WorryParking/
├─ App/          앱 진입점, AppDelegate(포그라운드 알림), 설정 상수
├─ Models/       Worry(@Model), 인사이트 집계
├─ Services/     WorryTime 계산, 알림, StoreKit 2 구독 관리
├─ Components/   테마, 주차권(TicketView), 차단기, 공용 컨트롤
└─ Views/        온보딩(실제 예시 포함), 주차장, 주차하기, 주차권 시트, 출차 게이트, Exit Log, 설정, 페이월
```

## 출시 전 TODO
- `AppConfig.privacyURL` / `termsURL`를 실제 문서로 교체
- App Store Connect에 구독 그룹/상품 생성
- 웰니스 카테고리 심사 대비: 앱 내 "의료기기 아님" 고지는 Settings ▸ About에 포함됨
