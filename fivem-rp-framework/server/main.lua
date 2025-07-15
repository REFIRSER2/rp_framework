local config = json.decode(LoadResourceFile(GetCurrentResourceName(), 'config.json'))

-- 플레이어 접속 시
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local source = source
    
    deferrals.defer()
    deferrals.update('Connecting to RP Framework...')
    
    Wait(100)
    deferrals.done()
end)

-- 플레이어 스폰 시
AddEventHandler('playerSpawned', function()
    local source = source
    local playerName = GetPlayerName(source)
    
    print(('[RP-Framework] %s has joined the server!'):format(playerName))
    
    -- 플레이어를 숨김 위치로 이동
    local hidePos = config.spawn.hidePosition
    SetEntityCoords(GetPlayerPed(source), hidePos.x, hidePos.y, hidePos.z, false, false, false, false)
    FreezeEntityPosition(GetPlayerPed(source), true)
    
    -- 플레이어 디멘션 설정 (FiveM에서는 라우팅 버킷 사용)
    SetPlayerRoutingBucket(source, source + 1000)
    
    -- 인증 상태 설정
    Player(source).state.authenticated = false
    
    -- 로그인 UI 표시
    TriggerClientEvent('rp-framework:showLoginUI', source)
end)

-- 플레이어 퇴장 시
AddEventHandler('playerDropped', function(reason)
    local source = source
    local playerName = GetPlayerName(source)
    
    print(('[RP-Framework] %s has left the server. Reason: %s'):format(playerName, reason))
    
    -- 플레이어 데이터 저장
    SaveAllDataFromCache()
end)

-- 서버 시작 시 초기화
AddEventHandler('onServerResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print('[RP-Framework] Initializing...')
        Wait(1000) -- 데이터베이스 초기화 대기
        print('[RP-Framework] Initialized successfully!')
    end
end)

-- 서버 종료 시 데이터 저장
AddEventHandler('onServerResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print('[RP-Framework] Server is shutting down...')
        SaveAllDataFromCache()
        print('[RP-Framework] All data saved. Goodbye!')
    end
end)