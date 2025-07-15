local modelsData = json.decode(LoadResourceFile(GetCurrentResourceName(), 'models.json'))
local config = json.decode(LoadResourceFile(GetCurrentResourceName(), 'config.json'))

-- 캐릭터 UI 표시
RegisterNetEvent('rp-framework:showCharacterUI')
AddEventHandler('rp-framework:showCharacterUI', function(source)
    local playerId = Player(source).state.dbId
    
    print(('[RP-Framework] Showing character UI for player ID: %s'):format(tostring(playerId)))
    
    if not playerId then
        TriggerClientEvent('chat:addMessage', source, {
            args = {'[System]', 'Error: Player not authenticated.'}
        })
        return
    end
    
    GetCharactersByPlayerId(playerId, function(characters)
        print(('[RP-Framework] Found %d characters for player %d'):format(#characters, playerId))
        
        -- 캐릭터 선택 UI 표시
        TriggerClientEvent('rp-framework:showCharacterSelection', source, characters, modelsData)
    end)
end)

-- 캐릭터 생성
RegisterNetEvent('rp-framework:character:create')
AddEventHandler('rp-framework:character:create', function(firstName, lastName, age, description, gender, model)
    local source = source
    local playerId = Player(source).state.dbId
    
    if not playerId then
        print('[RP-Framework] Error: Player not authenticated.')
        TriggerClientEvent('chat:addMessage', source, {
            args = {'[System]', 'Error: Player not authenticated.'}
        })
        return
    end
    
    print('[RP-Framework] Creating character...')
    
    CreateCharacter(playerId, firstName, lastName, description, age, gender, model, function(success)
        if success then
            print(('[RP-Framework] Character %s %s created successfully.'):format(firstName, lastName))
            TriggerClientEvent('chat:addMessage', source, {
                args = {'[System]', ('Character %s %s created successfully.'):format(firstName, lastName)}
            })
            
            -- 캐릭터 목록 새로고침
            GetCharactersByPlayerId(playerId, function(characters)
                TriggerClientEvent('rp-framework:showCharacterSelection', source, characters, modelsData)
            end)
        else
            print('[RP-Framework] Error creating character.')
            TriggerClientEvent('chat:addMessage', source, {
                args = {'[System]', 'Error creating character.'}
            })
        end
    end)
end)

-- 캐릭터 삭제
RegisterNetEvent('rp-framework:character:delete')
AddEventHandler('rp-framework:character:delete', function(characterId)
    local source = source
    local playerId = Player(source).state.dbId
    
    if not playerId then
        TriggerClientEvent('chat:addMessage', source, {
            args = {'[System]', 'Error: Player not authenticated.'}
        })
        return
    end
    
    GetCharacterById(characterId, function(character)
        if not character or character.player_id ~= playerId then
            TriggerClientEvent('chat:addMessage', source, {
                args = {'[System]', 'You do not own this character.'}
            })
            return
        end
        
        DeleteCharacter(characterId, function(success)
            if success then
                TriggerClientEvent('chat:addMessage', source, {
                    args = {'[System]', 'Character deleted.'}
                })
                
                -- 캐릭터 목록 새로고침
                GetCharactersByPlayerId(playerId, function(characters)
                    TriggerClientEvent('rp-framework:showCharacterSelection', source, characters, modelsData)
                end)
            else
                TriggerClientEvent('chat:addMessage', source, {
                    args = {'[System]', 'Error deleting character.'}
                })
            end
        end)
    end)
end)

-- 캐릭터 선택
RegisterNetEvent('rp-framework:character:select')
AddEventHandler('rp-framework:character:select', function(characterId)
    local source = source
    local playerId = Player(source).state.dbId
    
    if not playerId then
        TriggerClientEvent('chat:addMessage', source, {
            args = {'[System]', 'Error: Player not authenticated.'}
        })
        return
    end
    
    GetCharacterById(characterId, function(character)
        if not character or character.player_id ~= playerId then
            TriggerClientEvent('chat:addMessage', source, {
                args = {'[System]', 'You do not own this character.'}
            })
            return
        end
        
        -- 플레이어 모델 설정
        TriggerClientEvent('rp-framework:setPlayerModel', source, character.model)
        
        -- 캐릭터 ID 저장
        Player(source).state.characterId = character.id
        Player(source).state.characterData = character
        
        -- 스폰 위치로 이동
        local spawnPos = config.spawn.spawnpoint
        SetEntityCoords(GetPlayerPed(source), spawnPos.x, spawnPos.y, spawnPos.z, false, false, false, false)
        SetEntityHeading(GetPlayerPed(source), spawnPos.heading or 0.0)
        
        -- 기본 라우팅 버킷으로 복귀
        SetPlayerRoutingBucket(source, 0)
        
        -- 플레이어 동결 해제
        FreezeEntityPosition(GetPlayerPed(source), false)
        
        TriggerClientEvent('chat:addMessage', source, {
            args = {'[System]', ('Playing as %s %s.'):format(character.first_name, character.last_name)}
        })
        
        -- UI 숨기기
        TriggerClientEvent('rp-framework:hideCharacterUI', source)
    end)
end)

-- 캐릭터 모델 미리보기
RegisterNetEvent('rp-framework:previewCharacterModel')
AddEventHandler('rp-framework:previewCharacterModel', function(modelName)
    local source = source
    
    if modelName then
        TriggerClientEvent('rp-framework:setPlayerModel', source, modelName)
    end
end)