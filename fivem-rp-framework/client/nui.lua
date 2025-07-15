-- NUI 포커스 관리
local nuiFocused = false

-- NUI 포커스 설정
local function SetNUIFocusWrapper(focus, cursor)
    nuiFocused = focus
    SetNuiFocus(focus, cursor)
end

-- NUI 메시지 전송
function SendNUIMessage(data)
    SendNuiMessage(json.encode(data))
end

-- ESC 키 처리
CreateThread(function()
    while true do
        Wait(0)
        if nuiFocused then
            if IsControlJustPressed(0, 322) then -- ESC
                -- NUI에 ESC 키 이벤트 전송
                SendNUIMessage({
                    type = 'escapePressed'
                })
            end
        end
    end
end)

-- NUI 콜백: 포커스 해제
RegisterNUICallback('releaseFocus', function(data, cb)
    SetNUIFocusWrapper(false, false)
    cb('ok')
end)

-- NUI 콜백: 에러 리포트
RegisterNUICallback('reportError', function(data, cb)
    print('[RP-Framework] NUI Error: ' .. tostring(data.error))
    cb('ok')
end)

-- NUI 콜백: 디버그 메시지
RegisterNUICallback('debug', function(data, cb)
    print('[RP-Framework] NUI Debug: ' .. tostring(data.message))
    cb('ok')
end)

-- 리소스 정리
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- NUI 포커스 해제
    SetNUIFocus(false, false)
end)