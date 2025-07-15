const express = require('express');
const nodemailer = require('nodemailer');
const cors = require('cors');
const helmet = require('helmet');
const { RateLimiterMemory } = require('rate-limiter-flexible');
const Joi = require('joi');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

// 보안 미들웨어
app.use(helmet());
app.use(cors({
    origin: process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : ['http://localhost:30120'],
    credentials: true
}));
app.use(express.json({ limit: '10mb' }));

// Rate Limiting
const rateLimiter = new RateLimiterMemory({
    keyGenerator: (req) => req.ip,
    points: 5, // 5 requests
    duration: 300, // per 5 minutes
});

// API Key 인증 미들웨어
const authenticateApiKey = (req, res, next) => {
    const apiKey = req.headers['x-api-key'];
    const validApiKey = process.env.API_KEY;

    if (!validApiKey) {
        return res.status(500).json({ error: 'Server configuration error' });
    }

    if (!apiKey || apiKey !== validApiKey) {
        return res.status(401).json({ error: 'Invalid API key' });
    }

    next();
};

// 이메일 유효성 검사 스키마
const emailSchema = Joi.object({
    to: Joi.string().email().required(),
    subject: Joi.string().max(200).required(),
    content: Joi.string().max(10000).required(),
    from: Joi.string().email().optional()
});

// Nodemailer 설정
const createTransporter = () => {
    const emailService = process.env.EMAIL_SERVICE || 'gmail';
    
    const transportConfig = {
        gmail: {
            service: 'gmail',
            auth: {
                user: process.env.EMAIL_USER,
                pass: process.env.EMAIL_PASS // Gmail의 경우 앱 비밀번호 사용
            }
        },
        smtp: {
            host: process.env.SMTP_HOST,
            port: parseInt(process.env.SMTP_PORT) || 587,
            secure: process.env.SMTP_SECURE === 'true',
            auth: {
                user: process.env.SMTP_USER,
                pass: process.env.SMTP_PASS
            }
        },
        outlook: {
            service: 'hotmail',
            auth: {
                user: process.env.EMAIL_USER,
                pass: process.env.EMAIL_PASS
            }
        }
    };

    return nodemailer.createTransporter(transportConfig[emailService] || transportConfig.gmail);
};

// 이메일 전송 엔드포인트
app.post('/send-email', authenticateApiKey, async (req, res) => {
    try {
        // Rate limiting 확인
        await rateLimiter.consume(req.ip);

        // 입력 유효성 검사
        const { error, value } = emailSchema.validate(req.body);
        if (error) {
            return res.status(400).json({ error: error.details[0].message });
        }

        const { to, subject, content, from } = value;

        // 이메일 전송
        const transporter = createTransporter();
        
        const mailOptions = {
            from: from || process.env.EMAIL_FROM || process.env.EMAIL_USER,
            to: to,
            subject: subject,
            html: content
        };

        const info = await transporter.sendMail(mailOptions);
        
        console.log(`[${new Date().toISOString()}] Email sent to ${to}: ${info.messageId}`);
        
        res.json({
            success: true,
            messageId: info.messageId,
            message: 'Email sent successfully'
        });

    } catch (error) {
        if (error instanceof Error && error.name === 'RateLimiterError') {
            return res.status(429).json({ 
                error: 'Too many requests. Please try again later.',
                retryAfter: error.msBeforeNext 
            });
        }

        console.error('Email send error:', error);
        res.status(500).json({ 
            error: 'Failed to send email',
            details: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
});

// 인증 코드 이메일 전송 (특별 템플릿)
app.post('/send-verification', authenticateApiKey, async (req, res) => {
    try {
        await rateLimiter.consume(req.ip);

        const schema = Joi.object({
            to: Joi.string().email().required(),
            code: Joi.string().length(6).pattern(/^[0-9]+$/).required(),
            serverName: Joi.string().max(50).optional().default('RP Server')
        });

        const { error, value } = schema.validate(req.body);
        if (error) {
            return res.status(400).json({ error: error.details[0].message });
        }

        const { to, code, serverName } = value;

        // 인증 이메일 HTML 템플릿
        const htmlContent = `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>이메일 인증</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #f4f4f4; margin: 0; padding: 20px; }
        .container { max-width: 600px; margin: 0 auto; background-color: white; border-radius: 10px; overflow: hidden; box-shadow: 0 0 20px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; }
        .content { padding: 30px; }
        .code-box { background-color: #f8f9fa; border: 2px dashed #007bff; border-radius: 10px; padding: 20px; text-align: center; margin: 20px 0; }
        .code { font-size: 32px; font-weight: bold; color: #007bff; letter-spacing: 5px; }
        .footer { background-color: #f8f9fa; padding: 20px; text-align: center; color: #666; font-size: 14px; }
        .warning { background-color: #fff3cd; border: 1px solid #ffeaa7; border-radius: 5px; padding: 15px; margin: 20px 0; color: #856404; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎮 ${serverName}</h1>
            <p>이메일 인증이 필요합니다</p>
        </div>
        <div class="content">
            <h2>안녕하세요!</h2>
            <p>${serverName} 서버에 회원가입을 진행하고 있습니다. 아래 인증 코드를 입력하여 이메일 인증을 완료해주세요.</p>
            
            <div class="code-box">
                <p>인증 코드</p>
                <div class="code">${code}</div>
            </div>
            
            <div class="warning">
                ⚠️ <strong>주의사항:</strong>
                <ul style="margin: 10px 0; padding-left: 20px;">
                    <li>이 코드는 10분간만 유효합니다</li>
                    <li>코드를 다른 사람과 공유하지 마세요</li>
                    <li>만약 본인이 요청하지 않았다면 이 이메일을 무시하세요</li>
                </ul>
            </div>
            
            <p>문제가 있으시면 서버 관리자에게 문의해주세요.</p>
        </div>
        <div class="footer">
            <p>이 이메일은 자동으로 생성되었습니다. 답장하지 마세요.</p>
            <p>&copy; 2024 ${serverName}. All rights reserved.</p>
        </div>
    </div>
</body>
</html>`;

        const transporter = createTransporter();
        
        const mailOptions = {
            from: process.env.EMAIL_FROM || process.env.EMAIL_USER,
            to: to,
            subject: `[${serverName}] 이메일 인증 코드: ${code}`,
            html: htmlContent
        };

        const info = await transporter.sendMail(mailOptions);
        
        console.log(`[${new Date().toISOString()}] Verification email sent to ${to}: ${info.messageId}`);
        
        res.json({
            success: true,
            messageId: info.messageId,
            message: 'Verification email sent successfully'
        });

    } catch (error) {
        if (error instanceof Error && error.name === 'RateLimiterError') {
            return res.status(429).json({ 
                error: 'Too many requests. Please try again later.',
                retryAfter: error.msBeforeNext 
            });
        }

        console.error('Verification email send error:', error);
        res.status(500).json({ 
            error: 'Failed to send verification email',
            details: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
});

// 헬스 체크 엔드포인트
app.get('/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        timestamp: new Date().toISOString(),
        service: 'FiveM Email Backend'
    });
});

// 에러 핸들링 미들웨어
app.use((error, req, res, next) => {
    console.error('Unhandled error:', error);
    res.status(500).json({ error: 'Internal server error' });
});

// 404 핸들러
app.use((req, res) => {
    res.status(404).json({ error: 'Endpoint not found' });
});

// 서버 시작
app.listen(PORT, () => {
    console.log(`[${new Date().toISOString()}] Email backend server running on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`Email service: ${process.env.EMAIL_SERVICE || 'gmail'}`);
});