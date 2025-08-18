# YAKUSOKU (約束)

작은 약속이 하루를 바꿔요

## 프로젝트 구조

```
YAKUSOKU/
├── Models/           # SwiftData 모델
│   ├── Commitment.swift    # 약속 모델
│   ├── Checkin.swift       # 체크인 기록 모델
│   └── AppSetting.swift    # 앱 설정 모델
├── Views/            # UI 컴포넌트
│   ├── HomeView.swift          # 메인 홈 화면
│   ├── CommitmentCard.swift    # 약속 카드 컴포넌트
│   ├── AddCommitmentView.swift # 약속 추가 화면
│   ├── EditCommitmentView.swift    # 약속 편집 화면
│   ├── CommitmentDetailView.swift  # 약속 상세 화면
│   ├── WeeklyReportView.swift      # 주간 리포트 화면
│   └── SettingsView.swift          # 설정 화면
├── Widgets/          # 위젯 관련
│   ├── YakusokuWidget.swift    # 위젯 구현
│   └── CheckInIntent.swift     # AppIntents 체크인
├── Utilities/        # 유틸리티
│   └── SharedContainer.swift   # 공유 데이터 컨테이너
└── Extensions/       # 확장
    └── Date+Extensions.swift    # Date 확장

```

## Xcode 설정 필요 사항

### 1. Widget Extension 추가
1. Xcode에서 File > New > Target
2. "Widget Extension" 선택
3. Product Name: "YakusokuWidget"
4. Include Configuration Intent 체크 해제

### 2. App Groups 설정
1. 메인 앱 타겟 > Signing & Capabilities
2. "+ Capability" > App Groups 추가
3. "group.app.yakusoku" 추가
4. Widget Extension에도 동일하게 설정

### 3. 파일 타겟 설정
- `Widgets/` 폴더의 파일들은 Widget Extension 타겟에 추가
- 나머지 파일들은 메인 앱 타겟에 추가
- `Models/`, `Utilities/`, `Extensions/`는 양쪽 타겟에 모두 추가

### 4. Info.plist 권한 추가
```xml
<key>NSUserNotificationUsageDescription</key>
<string>매일 약속을 상기시켜드리기 위해 알림을 보냅니다</string>
```

## 빌드 및 실행

1. Xcode에서 프로젝트 열기
2. 위의 설정 완료
3. 시뮬레이터 또는 실제 기기에서 실행

## 주요 기능

- ✅ 약속 생성 (장점/단점/If-Then 전략)
- ✅ 3단계 체크인 (😣 못함 / 😐 보통 / 🙂 잘함)
- ✅ 홈/락스크린 위젯
- ✅ 위젯에서 바로 체크인 (Interactive)
- ✅ 7일 스트릭 표시
- ✅ 주간 리포트 및 인사이트
- ✅ 알림 설정
- ✅ 테마 선택
- ✅ iCloud 동기화 옵션