local authUIOpen = false

-- 로그인 UI 표시
RegisterNetEvent('rp-framework:showLoginUI')
AddEventHandler('rp-framework:showLoginUI', function()
    if not authUIOpen then
        authUIOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = 'showAuth',
            page = 'login'
        })
        
        -- 채팅 비활성화
        SetTextChatEnabled(false)
    end
end)

-- 인증 UI 닫기
RegisterNetEvent('rp-framework:closeAuthUI')
AddEventHandler('rp-framework:closeAuthUI', function()
    if authUIOpen then
        authUIOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({
            type = 'closeAuth'
        })
        
        -- 채팅 활성화
        SetTextChatEnabled(true)
    end
end)

-- 인증 입력 표시
RegisterNetEvent('rp-framework:showVerificationInput')
AddEventHandler('rp-framework:showVerificationInput', function()
    SendNUIMessage({
        type = 'showVerificationInput'
    })
end)

-- 이메일 상태 설정
RegisterNetEvent('rp-framework:setEmailStatus')
AddEventHandler('rp-framework:setEmailStatus', function(isAvailable)
    SendNUIMessage({
        type = 'setEmailStatus',
        available = isAvailable
    })
end)

-- NUI 콜백: 이메일 확인
RegisterNUICallback('checkEmail', function(data, cb)
    TriggerServerEvent('rp-framework:checkEmail', data.email)
    cb('ok')
end)

-- NUI 콜백: 인증 코드 요청
RegisterNUICallback('requestVerificationCode', function(data, cb)
    TriggerServerEvent('rp-framework:requestVerificationCode', data.email, data.password)
    cb('ok')
end)

-- NUI 콜백: 로그인
RegisterNUICallback('playerLogin', function(data, cb)
    TriggerServerEvent('rp-framework:playerLogin', data.email, data.password)
    cb('ok')
end)

-- NUI 콜백: 인증
RegisterNUICallback('playerVerify', function(data, cb)
    TriggerServerEvent('rp-framework:playerVerify', data.email, data.code)
    cb('ok')
end)

-- NUI 콜백: UI 준비 완료
RegisterNUICallback('authReady', function(data, cb)
    print('[RP-Framework] Auth UI ready')
    cb('ok')
end)