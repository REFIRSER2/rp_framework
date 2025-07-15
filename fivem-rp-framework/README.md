# FiveM RP Framework

RageMP에서 FiveM으로 이식된 RP(Role-Play) Framework입니다.

## 기능

- **계정 시스템**: 이메일 기반 회원가입/로그인
- **캐릭터 시스템**: 다중 캐릭터 생성 및 관리
- **데이터베이스**: MySQL을 사용한 영구 데이터 저장
- **캐시 시스템**: 성능 향상을 위한 메모리 캐싱

## 필요 사항

- FiveM 서버
- MySQL 데이터베이스
- Node.js (옵션)

## 의존성

- [mysql-async](https://github.com/brouznouf/fivem-mysql-async) - MySQL 연결

## 설치

1. `fivem-rp-framework` 폴더를 서버의 `resources` 디렉토리에 복사합니다.

2. MySQL 데이터베이스를 설정하고 `config.json`을 수정합니다:
```json
{
  "mysql": {
    "host": "localhost",
    "user": "your_user",
    "password": "your_password",
    "database": "rp_framework"
  }
}
```

3. 서버 설정 파일(`server.cfg`)에 다음을 추가합니다:
```
ensure mysql-async
ensure fivem-rp-framework
```

4. 서버를 시작합니다.

## 구조

```
fivem-rp-framework/
├── fxmanifest.lua      # 리소스 매니페스트
├── server/             # 서버 사이드 스크립트
│   ├── main.lua        # 메인 서버 로직
│   ├── database.lua    # 데이터베이스 관리
│   ├── account-system.lua  # 계정 시스템
│   └── character-system.lua # 캐릭터 시스템
├── client/             # 클라이언트 사이드 스크립트
│   ├── main.lua        # 메인 클라이언트 로직
│   ├── account-system.lua  # 계정 UI 관리
│   ├── character-system.lua # 캐릭터 UI 관리
│   └── nui.lua         # NUI 통합
├── html/               # NUI (UI) 파일
│   ├── index.html      # 메인 HTML
│   ├── style.css       # 메인 스타일
│   ├── script.js       # 메인 스크립트
│   ├── account-system/ # 계정 시스템 UI
│   └── character-system/ # 캐릭터 시스템 UI
├── config.json         # 설정 파일
└── models.json         # 캐릭터 모델 정의
```

## 사용법

### 플레이어 접속 흐름
1. 서버 접속 시 로그인 화면이 표시됩니다.
2. 기존 계정으로 로그인하거나 새 계정을 생성합니다.
3. 로그인 후 캐릭터 선택 화면이 표시됩니다.
4. 캐릭터를 선택하거나 새로 생성할 수 있습니다.
5. 캐릭터 선택 후 게임 월드에 스폰됩니다.

### 이벤트 API

#### 서버 이벤트
- `rp-framework:playerLoggedIn` - 플레이어 로그인 완료
- `rp-framework:characterSelected` - 캐릭터 선택 완료

#### 클라이언트 이벤트
- `rp-framework:showLoginUI` - 로그인 UI 표시
- `rp-framework:showCharacterUI` - 캐릭터 UI 표시

## 주의사항

- 이메일 인증 기능은 현재 콘솔에만 출력됩니다. 실제 이메일 전송을 위해서는 별도의 이메일 서비스 설정이 필요합니다.
- 비밀번호는 기본적인 해싱만 적용되어 있으므로, 프로덕션 환경에서는 더 강력한 암호화를 권장합니다.

## 라이선스

이 프로젝트는 원본 RageMP 프레임워크를 기반으로 FiveM으로 이식되었습니다.