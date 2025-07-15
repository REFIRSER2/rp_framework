-- 플레이어 식별자 가져오기
function GetPlayerIdentifierByType(source, type)
    local identifiers = GetPlayerIdentifiers(source)
    for _, id in ipairs(identifiers) do
        if string.find(id, type) then
            return id
        end
    end
    return nil
end

-- 플레이어가 온라인인지 확인
function IsPlayerOnline(playerId)
    local players = GetPlayers()
    for _, id in ipairs(players) do
        if tonumber(id) == tonumber(playerId) then
            return true
        end
    end
    return false
end

-- 거리 계산
function GetDistance(coords1, coords2)
    local distance = #(coords1 - coords2)
    return distance
end

-- 테이블 덤프 (디버깅용)
function DumpTable(table, indent)
    indent = indent or 0
    local spaces = string.rep("  ", indent)
    
    for k, v in pairs(table) do
        if type(v) == "table" then
            print(spaces .. k .. " = {")
            DumpTable(v, indent + 1)
            print(spaces .. "}")
        else
            print(spaces .. k .. " = " .. tostring(v))
        end
    end
end

-- JSON 안전 파싱
function SafeJsonDecode(str)
    local success, result = pcall(json.decode, str)
    if success then
        return result
    else
        print('[RP-Framework] JSON decode error: ' .. tostring(result))
        return nil
    end
end

-- 이벤트 로깅
function LogEvent(eventName, source, data)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local playerName = source and GetPlayerName(source) or "System"
    
    print(('[RP-Framework] [%s] Event: %s | Player: %s | Data: %s'):format(
        timestamp,
        eventName,
        playerName,
        json.encode(data or {})
    ))
end

-- 권한 확인 (향후 확장 가능)
function HasPermission(source, permission)
    -- 기본적으로 모든 권한 허용
    -- 나중에 권한 시스템 구현 시 수정
    return true
end

-- 안전한 콜백 실행
function SafeCallback(callback, ...)
    if type(callback) == "function" then
        local success, result = pcall(callback, ...)
        if not success then
            print('[RP-Framework] Callback error: ' .. tostring(result))
        end
        return success, result
    end
    return false, "Not a function"
end