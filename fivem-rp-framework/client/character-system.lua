local characterUIOpen = false
local currentCharacters = {}
local modelsData = {}

-- 캐릭터 선택 UI 표시
RegisterNetEvent('rp-framework:showCharacterSelection')
AddEventHandler('rp-framework:showCharacterSelection', function(characters, models)
    currentCharacters = characters
    modelsData = models
    
    if not characterUIOpen then
        characterUIOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = 'showCharacterUI',
            characters = characters,
            models = models
        })
        
        -- 채팅 비활성화
        SetTextChatEnabled(false)
        
        -- HUD와 레이더 숨기기
        DisplayRadar(false)
        DisplayHud(false)
    end
end)

-- 캐릭터 UI 숨기기
RegisterNetEvent('rp-framework:hideCharacterUI')
AddEventHandler('rp-framework:hideCharacterUI', function()
    if characterUIOpen then
        characterUIOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({
            type = 'hideCharacterUI'
        })
        
        -- 채팅 활성화
        SetTextChatEnabled(true)
        
        -- HUD와 레이더 표시
        DisplayRadar(true)
        DisplayHud(true)
        
        -- 카메라 정리
        RenderScriptCams(false, false, 0, true, false)
    end
end)

-- NUI 콜백: 캐릭터 생성
RegisterNUICallback('createCharacter', function(data, cb)
    TriggerServerEvent('rp-framework:character:create', 
        data.firstName, 
        data.lastName, 
        data.age, 
        data.description, 
        data.gender, 
        data.model
    )
    cb('ok')
end)

-- NUI 콜백: 캐릭터 삭제
RegisterNUICallback('deleteCharacter', function(data, cb)
    TriggerServerEvent('rp-framework:character:delete', data.characterId)
    cb('ok')
end)

-- NUI 콜백: 캐릭터 선택
RegisterNUICallback('selectCharacter', function(data, cb)
    TriggerServerEvent('rp-framework:character:select', data.characterId)
    cb('ok')
end)

-- NUI 콜백: 캐릭터 미리보기
RegisterNUICallback('previewCharacter', function(data, cb)
    if data.model then
        TriggerServerEvent('rp-framework:previewCharacterModel', data.model)
    end
    cb('ok')
end)

-- NUI 콜백: 캐릭터 UI 준비 완료
RegisterNUICallback('characterUIReady', function(data, cb)
    print('[RP-Framework] Character UI ready')
    cb('ok')
end)

-- 캐릭터 생성 시 카메라 설정
RegisterNUICallback('enterCharacterCreation', function(data, cb)
    -- 캐릭터 생성 뷰로 카메라 이동
    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(cam, -425.5, 1120.5, 327.9)
    PointCamAtCoord(cam, -425.5, 1123.5, 326.9)
    SetCamFov(cam, 50.0)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 500, true, false)
    
    cb('ok')
end)

-- 캐릭터 목록으로 돌아갈 때
RegisterNUICallback('exitCharacterCreation', function(data, cb)
    -- 기본 카메라로 복귀
    RenderScriptCams(false, true, 500, true, false)
    cb('ok')
end)