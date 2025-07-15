local config = json.decode(LoadResourceFile(GetCurrentResourceName(), 'config.json'))
local redisEnabled = false
local redisClient = nil

-- MySQL 연결은 mysql-async가 처리합니다
local dataSaveInterval = config.server.dataSaveInterval

-- Redis 초기화 (FiveM에서는 추가 설정 필요)
local function initializeRedis()
    -- FiveM에서 Redis를 사용하려면 추가적인 리소스나 모듈이 필요합니다
    -- 여기서는 간단한 캐시 테이블로 대체합니다
    redisEnabled = false
    print('[RP-Framework] Redis disabled, using in-memory cache')
end

-- 임시 캐시 테이블
local playerCache = {}

-- 데이터베이스 초기화
function InitializeDatabase()
    -- 테이블 생성
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS players (
            id INT AUTO_INCREMENT PRIMARY KEY,
            email VARCHAR(255) UNIQUE NOT NULL,
            password VARCHAR(255) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]], {})
    
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS characters (
            id INT AUTO_INCREMENT PRIMARY KEY,
            player_id INT NOT NULL,
            first_name VARCHAR(50) NOT NULL,
            last_name VARCHAR(50) NOT NULL,
            description TEXT,
            age INT,
            gender INT,
            model VARCHAR(255) NOT NULL,
            FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE
        )
    ]], {})
    
    print('[RP-Framework] Database tables initialized')
    
    -- Redis 초기화
    initializeRedis()
    
    -- 주기적 저장 설정
    SetTimeout(dataSaveInterval, SaveAllDataFromCache)
end

-- 캐시에서 모든 데이터 저장
function SaveAllDataFromCache()
    for playerId, data in pairs(playerCache) do
        if data and data.id then
            local updateData = {}
            for k, v in pairs(data) do
                if k ~= 'id' then
                    updateData[k] = v
                end
            end
            
            MySQL.Async.execute('UPDATE players SET email = @email WHERE id = @id', {
                ['@email'] = updateData.email or data.email,
                ['@id'] = data.id
            })
        end
    end
    
    print('[RP-Framework] All player data saved from cache')
    
    -- 다음 저장 예약
    SetTimeout(dataSaveInterval, SaveAllDataFromCache)
end

-- 플레이어 데이터 가져오기
function GetPlayerData(playerId)
    if playerCache[playerId] then
        return playerCache[playerId]
    end
    
    local result = MySQL.Sync.fetchAll('SELECT * FROM players WHERE id = @id', {
        ['@id'] = playerId
    })
    
    if result[1] then
        playerCache[playerId] = result[1]
        return result[1]
    end
    
    return nil
end

-- 플레이어 데이터 설정
function SetPlayerData(playerId, data)
    playerCache[playerId] = data
end

-- 이메일로 플레이어 데이터 가져오기
function GetPlayerDataByEmail(email)
    local result = MySQL.Sync.fetchAll('SELECT id, password FROM players WHERE email = @email', {
        ['@email'] = email
    })
    
    if result[1] then
        return result[1]
    end
    
    return nil
end

-- 새 플레이어 생성
function CreateNewPlayer(email, password, callback)
    MySQL.Async.execute('INSERT INTO players (email, password) VALUES (@email, @password)', {
        ['@email'] = email,
        ['@password'] = password
    }, function(rowsChanged)
        if rowsChanged > 0 then
            MySQL.Async.fetchAll('SELECT * FROM players WHERE email = @email', {
                ['@email'] = email
            }, function(result)
                if result[1] then
                    playerCache[result[1].id] = result[1]
                    callback(result[1])
                else
                    callback(nil)
                end
            end)
        else
            callback(nil)
        end
    end)
end

-- 캐릭터 생성
function CreateCharacter(playerId, firstName, lastName, description, age, gender, model, callback)
    MySQL.Async.execute([[
        INSERT INTO characters (player_id, first_name, last_name, description, age, gender, model) 
        VALUES (@playerId, @firstName, @lastName, @description, @age, @gender, @model)
    ]], {
        ['@playerId'] = playerId,
        ['@firstName'] = firstName,
        ['@lastName'] = lastName,
        ['@description'] = description,
        ['@age'] = age,
        ['@gender'] = gender,
        ['@model'] = model
    }, function(rowsChanged)
        if callback then
            callback(rowsChanged > 0)
        end
    end)
end

-- 플레이어 ID로 캐릭터 가져오기
function GetCharactersByPlayerId(playerId, callback)
    MySQL.Async.fetchAll('SELECT * FROM characters WHERE player_id = @playerId', {
        ['@playerId'] = playerId
    }, function(result)
        callback(result)
    end)
end

-- 캐릭터 삭제
function DeleteCharacter(characterId, callback)
    MySQL.Async.execute('DELETE FROM characters WHERE id = @id', {
        ['@id'] = characterId
    }, function(rowsChanged)
        if callback then
            callback(rowsChanged > 0)
        end
    end)
end

-- 캐릭터 ID로 캐릭터 가져오기
function GetCharacterById(characterId, callback)
    MySQL.Async.fetchAll('SELECT * FROM characters WHERE id = @id', {
        ['@id'] = characterId
    }, function(result)
        callback(result[1] or nil)
    end)
end

-- 리소스 시작 시 초기화
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        InitializeDatabase()
    end
end)

-- 리소스 종료 시 데이터 저장
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        SaveAllDataFromCache()
        print('[RP-Framework] All data saved before resource stop')
    end
end)