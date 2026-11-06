# 밑바닥 인생 — Android 1.0.0 RC1 출시 확인표

이 버전은 출시 후보(RC)이며 APK 설치 및 실기기 테스트 전에는 정식 완성으로 표시하지 않습니다.

## 1. GitHub Actions
1. Actions > Build Android APK > 최신 main 실행을 엽니다.
2. `Validate Godot project and scripts`, `Check gameplay and save invariants`, `Run gameplay smoke tests`, `Import and export APK`, `Verify APK package and signing`이 모두 성공했는지 확인합니다.
3. `BottomLife-APK` 아티팩트에서 APK를 받습니다.
4. APK가 설치되지 않으면 해당 실행의 `BottomLife-Diagnostics` 아티팩트 로그를 확인합니다.

## 2. 안드로이드 실기기 점검
- 새 설치 후 실행/종료/재실행 시 강제 종료 없음
- 거리: 터치 수익, 콤보, 이벤트, 캐릭터와 배경 그래픽 표시
- 사업: x1/x10/최대 구매, 구매 금액, 수익 증가, 스크롤 유지
- 광산: 기력 회복, 채굴, 층 이동, 드릴/정제 설비, 광물 판매
- 성장: 보석 사용, 업그레이드, 스크롤 유지
- 환생: 보상 수령, 초기화, 영구 업그레이드와 누적 업적 유지
- 앱 종료/재실행 후 저장 상태 복원
- 몇 분간 백그라운드에 뒀다가 실행 시 오프라인 수익과 기력 회복
- 작은 화면에서 버튼이 겹치거나 하단 내비게이션이 사라지지 않음

## 3. 정식 1.0 승격 조건
- 최신 GitHub Actions 실행 성공
- APK 서명/패키지/버전 확인
- 안드로이드 실기기에서 위 핵심 경로 통과
- 발견된 크래시 및 진행 불가 오류 수정
- 완료 후 export_presets.cfg의 version/name을 1.0.0으로 변경하고 version/code 증가

주의: 디버그 APK는 기기/설치 출처에 따라 보안 경고가 발생할 수 있습니다. 기존 앱과 서명 키가 다르면 업데이트 설치가 안 될 수 있으므로, 기존 데이터 보존을 확인하기 전 앱을 삭제하지 마세요.
