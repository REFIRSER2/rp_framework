local config = json.decode(LoadResourceFile(GetCurrentResourceName(), 'config.json'))
-- local bcrypt = require 'bcrypt' -- FiveM에서는 별도 설치 필요
local verificationCodes = {}

-- 이메일 전송 함수는 email-service.lua에서 가져옴

-- 비밀번호 해싱 함수 (bcrypt 대신 간단한 해싱 사용)
local function hashPassword(password)
    -- FiveM에서는 GetHashKey 함수를 사용하거나 별도의 해싱 라이브러리가 필요합니다
    return GetHashKey(password)
end

-- 비밀번호 검증 함수
local function verifyPassword(password, hash)
    return GetHashKey(password) == hash
end

-- 로그인 처리
RegisterNetEvent('rp-framework:playerLogin')
AddEventHandler('rp-framework:playerLogin', function(email, password)
    local source = source
    
    local playerData = GetPlayerDataByEmail(email)
    if not playerData then
        TriggerClientEvent('chat:addMessage', source, {
            args = {'[System]', 'Invalid email or password.'}
        })
        return
    end
    
    if verifyPassword(password, playerData.password) then
        -- 로그인 성공
        TriggerClientEvent('rp-framework:closeAuthUI', source)
        
        -- 플레이어 데이터 설정
        Player(source).state.dbId = playerData.id
        Player(source).state.authenticated = true
        
        -- 캐릭터 선택 UI 표시
        TriggerEvent('rp-framework:playerLoggedIn', source, playerData)
    else
        TriggerClientEvent('chat:addMessage', source, {
            args = {'[System]', 'Invalid email or password.'}
        })
    end
end)

-- 이메일 중복 확인
RegisterNetEvent('rp-framework:checkEmail')
AddEventHandler('rp-framework:checkEmail', function(email)
    local source = source
    
    local existingPlayer = GetPlayerDataByEmail(email)
    print(('[RP-Framework] Email check for %s: %s'):format(email, existingPlayer and 'exists' or 'available'))
    
    TriggerClientEvent('rp-framework:setEmailStatus', source, not existingPlayer)
end)

-- 인증 코드 요청
RegisterNetEvent('rp-framework:requestVerificationCode')
AddEventHandler('rp-framework:requestVerificationCode', function(email, password)
    local source = source
    
    -- 이메일 중복 재확인
    local existingPlayer = GetPlayerDataByEmail(email)
    if existingPlayer then
        TriggerClientEvent('rp-framework:setEmailStatus', source, false)
        return
    end
    
    -- 6자리 인증 코드 생성
    local code = tostring(math.random(100000, 999999))
    
    -- 플레이어 식별자와 함께 인증 정보 저장
    local identifier = GetPlayerIdentifier(source, 0)
    verificationCodes[identifier] = {
        email = email,
        password = password,
        code = code,
        timestamp = os.time()
    }
    
    -- 실제 이메일 전송
    SendVerificationEmail(email, code, function(success, error)
        if success then
            TriggerClientEvent('rp-framework:showVerificationInput', source)
            TriggerClientEvent('chat:addMessage', source, {
                args = {'[System]', 'Verification code has been sent to your email.'}
            })
        else
            print(('[RP-Framework] Email send failed: %s'):format(error or 'Unknown error'))
            TriggerClientEvent('chat:addMessage', source, {
                args = {'[System]', 'Failed to send verification email. Please try again.'}
            })
        end
    end)
end)

-- 인증 코드 확인 및 회원가입
RegisterNetEvent('rp-framework:playerVerify')
AddEventHandler('rp-framework:playerVerify', function(providedEmail, code)
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    
    local verificationData = verificationCodes[identifier]
    
    if not verificationData or verificationData.email ~= providedEmail or verificationData.code ~= code then
        TriggerClientEvent('chat:addMessage', source, {
            args = {'[System]', 'Invalid verification code.'}
        })
        return
    end
    
    -- 인증 코드 유효 시간 확인 (10분)
    if os.time() - verificationData.timestamp > 600 then
        TriggerClientEvent('chat:addMessage', source, {
            args = {'[System]', 'Verification code expired. Please request a new one.'}
        })
        verificationCodes[identifier] = nil
        return
    end
    
    local email = verificationData.email
    local password = verificationData.password
    
    -- 비밀번호 해싱 및 플레이어 생성
    local hashedPassword = hashPassword(password)
    
    CreateNewPlayer(email, hashedPassword, function(newPlayer)
        if newPlayer then
            verificationCodes[identifier] = nil
            
            TriggerClientEvent('chat:addMessage', source, {
                args = {'[System]', 'Registration successful! Please log in.'}
            })
            
            -- UI 닫고 다시 로그인 폼 표시
            TriggerClientEvent('rp-framework:closeAuthUI', source)
            Wait(500)
            TriggerClientEvent('rp-framework:showLoginUI', source)
        else
            TriggerClientEvent('chat:addMessage', source, {
                args = {'[System]', 'Registration failed. Please try again.'}
            })
        end
    end)
end)

-- 플레이어 로그인 완료 이벤트
RegisterNetEvent('rp-framework:playerLoggedIn')
AddEventHandler('rp-framework:playerLoggedIn', function(source, playerData)
    -- 캐릭터 선택 UI 표시
    TriggerEvent('rp-framework:showCharacterUI', source)
end)

-- 오래된 인증 코드 정리 (30분마다)
CreateThread(function()
    while true do
        Wait(1800000) -- 30분
        
        local currentTime = os.time()
        for identifier, data in pairs(verificationCodes) do
            if currentTime - data.timestamp > 600 then -- 10분 이상 경과
                verificationCodes[identifier] = nil
            end
        end
    end
end)