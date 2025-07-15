local authBrowser = nil
local characterBrowser = nil
local loginCam = nil

-- 로그인 카메라 생성 및 설정
local function CreateLoginCamera()
    loginCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(loginCam, 726.0, 1196.0, 345.0)
    PointCamAtCoord(loginCam, 0.0, 0.0, 50.0)
    SetCamFov(loginCam, 50.0)
    SetCamActive(loginCam, true)
    RenderScriptCams(true, true, 0, true, false)
end

-- 로그인 카메라 제거
local function DestroyLoginCamera()
    if loginCam then
        RenderScriptCams(false, false, 0, true, false)
        SetCamActive(loginCam, false)
        DestroyCam(loginCam, false)
        loginCam = nil
    end
end

-- 플레이어 준비 시
AddEventHandler('playerSpawned', function()
    -- 로그인 카메라 생성
    CreateLoginCamera()
    
    -- HUD와 레이더 숨기기
    DisplayRadar(false)
    DisplayHud(false)
end)

-- 리소스 시작 시
AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print('[RP-Framework] Client initialized')
end)

-- 리소스 중지 시
AddEventHandler('onClientResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- UI 정리
    if authBrowser then
        SetNuiFocus(false, false)
        SendNUIMessage({
            type = 'close'
        })
    end
    
    -- 카메라 정리
    DestroyLoginCamera()
    
    -- HUD 복구
    DisplayRadar(true)
    DisplayHud(true)
end)

-- 플레이어 모델 설정
RegisterNetEvent('rp-framework:setPlayerModel')
AddEventHandler('rp-framework:setPlayerModel', function(modelName)
    local model = GetHashKey(modelName)
    
    if not IsModelValid(model) then
        print('[RP-Framework] Invalid model: ' .. modelName)
        return
    end
    
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
    
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)
    
    -- 기본 ped 설정
    local ped = PlayerPedId()
    SetPedDefaultComponentVariation(ped)
    SetPedComponentVariation(ped, 0, 0, 0, 2) -- Face
    SetPedComponentVariation(ped, 2, 0, 0, 2) -- Hair
end)