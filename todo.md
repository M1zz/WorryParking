# TODO

## 완료
- [x] GitHub public 레포 생성 및 초기 커밋/푸시
- [x] 한국어 현지화 (Localizable.xcstrings, InfoPlist.xcstrings, StoreKit 설명)
- [x] 온보딩에 실제 사용 예시 페이지 추가 (적기 → 주차 → 출차)
- [x] GitHub Pages 소개 페이지 + 개인정보 처리방침 (docs/), `AppConfig.privacyURL` 교체, README 링크
- [x] 언어별 지원 페이지·개인정보 처리방침 (docs/ko, docs/en), 앱 내 링크 언어별 연결
- [x] 온보딩: 작동 원리+연구 근거 페이지, 실제 걱정 주차 체험, 체험·첫 출차 피드백(기기에만 저장, 출차 기록에 표시)
- [x] App Store 설명 문구 ko/en (`AppStore/metadata/`)
- [x] 앱스토어 스크린샷 5장 × ko/en (6.5" 1242×2688) — `AppStore/capture_screenshots.sh`로 재생성

## 출시 전
- [ ] App Store Connect에 구독 그룹/상품 생성 (한국어 표시 이름/설명 포함)
- [ ] App Store Connect 현지화별 지원 URL·개인정보 처리방침 URL 입력 (README 표) + 개인정보 라벨 "데이터 수집 안 함"
- [ ] 출시 후 소개 페이지의 "출시 예정" 배지를 App Store 링크로 교체
- [ ] App Store Connect에 메타데이터(`AppStore/metadata/`) 입력 · 스크린샷 업로드 (`docs/screenshots/` — DeployBar 가 배포 때 올림)
- [ ] 새 온보딩(작동 원리·체험 단계)이 반영되도록 스크린샷 재캡처 검토
- [x] 다국어 22개 추가(en-GB, zh-Hans, zh-Hant, ja, ru, es, de, fr, it, pt-BR, th, vi, cs, da, el, fi, id, nb, nl, pl, sv, tr) — 앱 문자열 · 스토어 문구 · docs/<언어>/ · 릴리즈노트 · AppStore/metadata
- [x] Mac에서 24개 언어 스크린샷 캡처·합성(`AppStore/capture_screenshots.sh`) 후 한·중·일·태국어 글꼴과 긴 문구 줄바꿈 확인
- [ ] Xcode 빌드로 22개 언어 문자열 확인, DeployBar 다국어 게이트(LOCALIZATION_GATE=strict) 확인

## 아이폰 듀오 대응 (2026-10-30, LeeoKit 3.26 Fold · 듀오 시뮬레이터 빌드 성공)
- [x] 루트(`RootView`)에 `.foldAware()` 한 번. 시트 · 알림창이 접힌 선을 비킨다
- [x] 펴면(세로 고정 앱이라 세로) 아래 판은 주차장 · 설정, 위 판은 출차 기록(`MainTabView` 의 `foldTab`). 주차해 두는 쪽 | 그 걱정이 어떻게 됐는지
- [x] 출차 기록은 늘 위 판이라 펼친 탭 막대에는 주차장 · 설정만. 출차 기록 탭에서 펴면 주차장으로 옮긴다
- [x] 탭 막대 자리(`.foldTabBarRoom()`)는 주차장 · 설정의 NavigationStack 안에 건다. 판 밖에 걸면 '걱정 주차하기' 버튼이 막대 밑에 깔린다
- [x] 탭 구조를 그대로 두고 `FoldSplitView` 로 나눠, 펴고 접어도 보던 주차장 · 시트가 남는다
- [x] 출차 게이트(fullScreenCover) · 온보딩은 `.foldConfined()` (아래 판에만)
- [x] 툴바 글자 버튼에 아이콘: Cancel · Done · Later · Not now (문자열은 그대로라 번역 추가 없음)
- [ ] 실기기 · Xcode 27.1 빌드로 펼친 화면 확인 (27.0 빌드는 듀오에서 호환 틀로 뜬다)
- 확인 방법: 듀오 시뮬레이터에 `-FoldPretend` 로 실행하면 펼친 배치, 인자 없이 실행하면 지금 화면 그대로
