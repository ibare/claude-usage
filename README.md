# ClaudeUsage

Claude Code 사용량을 macOS 상태바에서 실시간으로 확인할 수 있는 메뉴바 앱입니다.

![macOS](https://img.shields.io/badge/macOS-15.0+-000000?logo=apple)
![Swift](https://img.shields.io/badge/Swift-6.2-F05138?logo=swift&logoColor=white)

## 기능

- **상태바 히트맵** — 3×3 격자 2개로 Session(초록)과 Weekly(주황) 사용량을 한눈에 표시
- **상세 팝오버** — 클릭 시 원형 게이지로 정확한 퍼센트, 리셋 카운트다운 확인
- **자동 갱신** — 1분 간격으로 사용량 자동 업데이트
- **Keychain 연동** — Claude Code의 OAuth 토큰을 자동으로 읽고 만료 시 갱신

## 스크린샷

```
상태바:  [■■□ ■■□]   ← Session 66% (초록) / Weekly 66% (주황)
         [■■□ ■■□]
         [■■□ ■■□]

팝오버:
┌──────────────────────────────┐
│  Claude Usage          [↻]   │
├──────────────────────────────┤
│    ╭───╮        ╭───╮        │
│   │30% │      │29% │        │
│    ╰───╯        ╰───╯        │
│  Session(5h)   Weekly(7d)    │
│   2h 3m         4d 4h        │
├──────────────────────────────┤
│  Updated just now      Quit  │
└──────────────────────────────┘
```

## 요구사항

- macOS 15.0+
- [Xcode](https://developer.apple.com/xcode/) 16+
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- Claude Code에 로그인된 상태 (`claude login`)

## 빌드 & 실행

```bash
# 프로젝트 생성
xcodegen generate

# 빌드
xcodebuild build -project ClaudeUsage.xcodeproj -scheme ClaudeUsage -configuration Debug

# 실행
open ~/Library/Developer/Xcode/DerivedData/ClaudeUsage-*/Build/Products/Debug/ClaudeUsage.app
```

또는 Xcode에서 `ClaudeUsage.xcodeproj`를 열고 Run(⌘R)하면 됩니다.

## 프로젝트 구조

```
Sources/
├── App/
│   └── ClaudeUsageApp.swift        # @main, NSStatusItem + NSPopover
├── Models/
│   └── UsageData.swift             # API 응답 / Credential 모델
├── Services/
│   ├── CredentialService.swift     # Keychain 읽기 (security CLI) + 토큰 갱신
│   ├── UsageAPIService.swift       # GET api.anthropic.com/api/oauth/usage
│   └── UsageMonitor.swift          # @Observable 상태 관리 + 1분 타이머
└── Views/
    ├── HeatmapStatusView.swift     # 상태바 3×3 히트맵 (NSView)
    ├── CircularGaugeView.swift     # 원형 게이지 컴포넌트
    └── MenuContentView.swift       # 팝오버 상세 뷰
```

## 데이터 흐름

```
Keychain ("Claude Code-credentials")
  → CredentialService (/usr/bin/security CLI로 읽기, 만료 시 토큰 갱신)
  → UsageAPIService (GET api.anthropic.com/api/oauth/usage)
  → UsageMonitor (@Observable, 1분 자동 갱신)
  → HeatmapStatusView (상태바) + MenuContentView (팝오버)
```

## 라이선스

MIT
