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
