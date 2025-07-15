local config = json.decode(LoadResourceFile(GetCurrentResourceName(), 'config.json'))

-- SendGrid API를 사용한 이메일 전송
function SendEmailViaSendGrid(toEmail, subject, content, callback)
    local sendGridApiKey = config.email.sendgrid_api_key
    
    if not sendGridApiKey or sendGridApiKey == "" then
        print('[RP-Framework] SendGrid API key not configured')
        if callback then callback(false, 'API key not configured') end
        return
    end
    
    local emailData = {
        personalizations = {
            {
                to = {
                    {
                        email = toEmail
                    }
                },
                subject = subject
            }
        },
        from = {
            email = config.email.from_email or 'noreply@yourserver.com',
            name = config.email.from_name or 'RP Server'
        },
        content = {
            {
                type = 'text/html',
                value = content
            }
        }
    }
    
    local headers = {
        ['Authorization'] = 'Bearer ' .. sendGridApiKey,
        ['Content-Type'] = 'application/json'
    }
    
    PerformHttpRequest('https://api.sendgrid.com/v3/mail/send', function(statusCode, responseText, responseHeaders)
        local success = statusCode >= 200 and statusCode < 300
        
        if success then
            print(('[RP-Framework] Email sent successfully to %s'):format(toEmail))
        else
            print(('[RP-Framework] Failed to send email to %s. Status: %d, Response: %s'):format(toEmail, statusCode, responseText))
        end
        
        if callback then
            callback(success, responseText)
        end
    end, 'POST', json.encode(emailData), headers)
end

-- Mailgun API를 사용한 이메일 전송 (대안)
function SendEmailViaMailgun(toEmail, subject, content, callback)
    local mailgunDomain = config.email.mailgun_domain
    local mailgunApiKey = config.email.mailgun_api_key
    
    if not mailgunDomain or not mailgunApiKey then
        print('[RP-Framework] Mailgun credentials not configured')
        if callback then callback(false, 'Mailgun not configured') end
        return
    end
    
    local fromEmail = config.email.from_email or ('noreply@' .. mailgunDomain)
    
    local postData = string.format(
        'from=%s&to=%s&subject=%s&html=%s',
        fromEmail,
        toEmail,
        subject,
        content
    )
    
    local headers = {
        ['Authorization'] = 'Basic ' .. base64Encode('api:' .. mailgunApiKey),
        ['Content-Type'] = 'application/x-www-form-urlencoded'
    }
    
    local url = string.format('https://api.mailgun.net/v3/%s/messages', mailgunDomain)
    
    PerformHttpRequest(url, function(statusCode, responseText, responseHeaders)
        local success = statusCode >= 200 and statusCode < 300
        
        if success then
            print(('[RP-Framework] Email sent successfully to %s via Mailgun'):format(toEmail))
        else
            print(('[RP-Framework] Failed to send email via Mailgun to %s. Status: %d'):format(toEmail, statusCode))
        end
        
        if callback then
            callback(success, responseText)
        end
    end, 'POST', postData, headers)
end

-- Node.js 백엔드를 사용한 이메일 전송
function SendEmailViaWebService(toEmail, subject, content, callback)
    local webhookUrl = config.email.webhook_url
    local apiKey = config.email.api_key
    
    if not webhookUrl then
        print('[RP-Framework] Email webhook URL not configured')
        if callback then callback(false, 'Webhook not configured') end
        return
    end
    
    if not apiKey then
        print('[RP-Framework] API key not configured for webhook')
        if callback then callback(false, 'API key not configured') end
        return
    end
    
    local emailData = {
        to = toEmail,
        subject = subject,
        content = content,
        from = config.email.from_email or 'noreply@yourserver.com'
    }
    
    local headers = {
        ['Content-Type'] = 'application/json',
        ['x-api-key'] = apiKey
    }
    
    PerformHttpRequest(webhookUrl, function(statusCode, responseText, responseHeaders)
        local success = statusCode >= 200 and statusCode < 300
        
        if success then
            print(('[RP-Framework] Email sent successfully to %s via webhook'):format(toEmail))
        else
            print(('[RP-Framework] Failed to send email via webhook to %s. Status: %d, Response: %s'):format(toEmail, statusCode, responseText))
        end
        
        if callback then
            callback(success, responseText)
        end
    end, 'POST', json.encode(emailData), headers)
end

-- Node.js 백엔드를 사용한 인증 이메일 전송 (전용 엔드포인트)
function SendVerificationEmailViaBackend(toEmail, code, callback)
    local backendUrl = config.email.backend_url or config.email.webhook_url
    local apiKey = config.email.api_key
    
    if not backendUrl then
        print('[RP-Framework] Backend URL not configured')
        if callback then callback(false, 'Backend URL not configured') end
        return
    end
    
    if not apiKey then
        print('[RP-Framework] API key not configured for backend')
        if callback then callback(false, 'API key not configured') end
        return
    end
    
    -- /send-verification 엔드포인트 사용
    local verificationUrl = backendUrl:gsub('/send%-email$', '') .. '/send-verification'
    
    local emailData = {
        to = toEmail,
        code = code,
        serverName = config.email.server_name or 'RP Server'
    }
    
    local headers = {
        ['Content-Type'] = 'application/json',
        ['x-api-key'] = apiKey
    }
    
    PerformHttpRequest(verificationUrl, function(statusCode, responseText, responseHeaders)
        local success = statusCode >= 200 and statusCode < 300
        
        if success then
            print(('[RP-Framework] Verification email sent successfully to %s via backend'):format(toEmail))
        else
            print(('[RP-Framework] Failed to send verification email via backend to %s. Status: %d, Response: %s'):format(toEmail, statusCode, responseText))
        end
        
        if callback then
            callback(success, responseText)
        end
    end, 'POST', json.encode(emailData), headers)
end

-- Base64 인코딩 함수 (Mailgun용)
function base64Encode(data)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

-- 인증 이메일 HTML 템플릿
function GetVerificationEmailTemplate(code, serverName)
    return string.format([[
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>이메일 인증</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #f4f4f4; margin: 0; padding: 20px; }
        .container { max-width: 600px; margin: 0 auto; background-color: white; border-radius: 10px; overflow: hidden; box-shadow: 0 0 20px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #667eea 0%%, #764ba2 100%%); color: white; padding: 30px; text-align: center; }
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
            <h1>🎮 %s</h1>
            <p>이메일 인증이 필요합니다</p>
        </div>
        <div class="content">
            <h2>안녕하세요!</h2>
            <p>%s 서버에 회원가입을 진행하고 있습니다. 아래 인증 코드를 입력하여 이메일 인증을 완료해주세요.</p>
            
            <div class="code-box">
                <p>인증 코드</p>
                <div class="code">%s</div>
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
            <p>&copy; 2024 %s. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
]], serverName, serverName, code, serverName)
end

-- 메인 이메일 전송 함수
function SendVerificationEmail(toEmail, code, callback)
    local emailService = config.email.service or 'sendgrid'
    
    -- Node.js 백엔드를 사용하는 경우 전용 엔드포인트 사용
    if emailService == 'backend' or emailService == 'webhook' then
        SendVerificationEmailViaBackend(toEmail, code, callback)
        return
    end
    
    -- 다른 서비스들은 기존 방식 사용
    local serverName = config.email.server_name or 'RP Server'
    local subject = string.format('[%s] 이메일 인증 코드: %s', serverName, code)
    local content = GetVerificationEmailTemplate(code, serverName)
    
    if emailService == 'sendgrid' then
        SendEmailViaSendGrid(toEmail, subject, content, callback)
    elseif emailService == 'mailgun' then
        SendEmailViaMailgun(toEmail, subject, content, callback)
    else
        print('[RP-Framework] Unknown email service: ' .. emailService)
        if callback then callback(false, 'Unknown email service') end
    end
end