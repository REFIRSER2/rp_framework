# FiveM Email Backend Server

FiveM RP Framework를 위한 이메일 전송 백엔드 서버입니다.

## 기능

- 이메일 전송 API
- 인증 코드 이메일 템플릿
- Rate limiting 및 보안
- 다중 이메일 서비스 지원 (Gmail, Outlook, SMTP)

## 설치

1. 의존성 설치:
```bash
npm install
```

2. 환경 변수 설정:
```bash
cp .env.example .env
# .env 파일을 편집하여 이메일 설정을 입력하세요
```

3. 서버 실행:
```bash
# 프로덕션
npm start

# 개발 (nodemon 사용)
npm run dev
```

## 환경 변수 설정

### 필수 설정
- `API_KEY`: FiveM 서버에서 인증할 때 사용할 API 키
- `EMAIL_USER`: 이메일 계정
- `EMAIL_PASS`: 이메일 비밀번호 (Gmail의 경우 앱 비밀번호)

### Gmail 설정
1. Gmail 계정에서 2단계 인증 활성화
2. 앱 비밀번호 생성
3. `.env` 파일에 설정:
```
EMAIL_SERVICE=gmail
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password
```

### SMTP 설정
```
EMAIL_SERVICE=smtp
SMTP_HOST=smtp.yourdomain.com
SMTP_PORT=587
SMTP_USER=your-smtp-user
SMTP_PASS=your-smtp-password
```

## API 엔드포인트

### POST /send-verification
인증 코드 이메일 전송

**헤더:**
```
x-api-key: your-api-key
Content-Type: application/json
```

**Body:**
```json
{
  "to": "user@example.com",
  "code": "123456",
  "serverName": "My RP Server"
}
```

### POST /send-email
일반 이메일 전송

**Body:**
```json
{
  "to": "user@example.com",
  "subject": "Subject",
  "content": "<html>HTML content</html>",
  "from": "sender@example.com"
}
```

### GET /health
서버 상태 확인

## FiveM 설정

FiveM의 `config.json`에서 webhook URL을 백엔드 서버로 설정:

```json
{
  "email": {
    "service": "webhook",
    "webhook_url": "http://your-backend-server:3001/send-verification"
  }
}
```

## 보안

- API 키 인증
- Rate limiting (5분에 5회)
- CORS 설정
- 헬멧 보안 헤더

## 배포

### PM2 사용
```bash
npm install -g pm2
pm2 start server.js --name "email-backend"
pm2 save
pm2 startup
```

### Docker 사용
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3001
CMD ["node", "server.js"]
```

## 문제 해결

### Gmail 인증 실패
- 2단계 인증이 활성화되어 있는지 확인
- 앱 비밀번호를 사용하고 있는지 확인

### Rate Limiting 오류
- 요청 빈도를 줄이거나 Rate Limit 설정을 조정

### CORS 오류
- `ALLOWED_ORIGINS`에 FiveM 서버 주소가 포함되어 있는지 확인