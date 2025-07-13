const database = require('../database');
const modelsData = require('../models.json'); // Keep the original gender-segregated object

// This event is called from the account system after a successful login
mp.events.add('server:playerLoggedIn', (player, playerData) => {
    // Store the database ID in the player object for this session
    player.setVariable('dbId', playerData.id);

    // Now, call the event to display the character selection UI
    mp.events.call('server:showCharacterUI', player);
});

// This event should be called after a player successfully logs in.
mp.events.add('server:showCharacterUI', async (player) => {
    try {
        const playerId = player.getVariable('dbId');
		console.log(`db id ${playerId}`);
        if (!playerId) {
            return player.outputChatBox('Error: Player not authenticated.');
        }
        const characters = await database.getCharactersByPlayerId(playerId);
		console.log(`characters ${characters}`);
        // Send the original modelsData object to the client
        player.call('client:showCharacterSelection', [characters, modelsData]);
    } catch (error) {
        console.error(`Error getting characters: ${error.message}`);
        player.outputChatBox('Error loading characters.');
    }
});

// Updated to handle detailed character creation including description
mp.events.add('server:character:create', async (player, firstName, lastName, age, description, gender, model) => {
    try {
        console.log('=== CHARACTER CREATION DEBUG ===');
        console.log('Player:', player);
        console.log('First Name:', firstName, 'Type:', typeof firstName);
        console.log('Last Name:', lastName, 'Type:', typeof lastName);
        console.log('Age:', age, 'Type:', typeof age);
        console.log('Description:', description, 'Type:', typeof description);
        console.log('Gender:', gender, 'Type:', typeof gender);
        console.log('Model:', model, 'Type:', typeof model);
        console.log('================================');
        
        const playerId = player.getVariable('dbId');
        if (!playerId) {
			console.log('Error: Player not authenticated.');
            return player.outputChatBox('Error: Player not authenticated.');
        }
		
		console.log('TEST CHARACTER CREATE - Player ID:', playerId);
        
        // Validate parameters
        if (!firstName || !lastName || age === null || age === undefined || gender === null || gender === undefined || !model) {
            console.log('Missing required parameters!');
            player.outputChatBox('Error: Missing required character information.');
            return;
        }

        // Call database with all character details
        await database.createCharacter(playerId, firstName, lastName, age, description, gender, model);
        console.log(`Character ${firstName} ${lastName} created successfully.`);
		player.outputChatBox(`Character ${firstName} ${lastName} created successfully.`);

        // Refresh the character list for the player
        const characters = await database.getCharactersByPlayerId(playerId);
        player.call('client:showCharacterSelection', [characters, modelsData]);
    } catch (error) {
        console.error(`Error creating character: ${error.message}`);
        player.outputChatBox('Error creating character.');
    }
});

mp.events.add('server:character:delete', async (player, characterId) => {
    try {
        const playerId = player.getVariable('dbId');
        if (!playerId) {
            return player.outputChatBox('Error: Player not authenticated.');
        }
        
        const character = await database.getCharacterById(characterId);
        if (!character || character.player_id !== playerId) {
            return player.outputChatBox('You do not own this character.');
        }

        await database.deleteCharacter(characterId);
        player.outputChatBox('Character deleted.');

        // Refresh the character list
        const characters = await database.getCharactersByPlayerId(playerId);
        player.call('client:showCharacterSelection', [characters, modelsData]);
    } catch (error) {
        console.error(`Error deleting character: ${error.message}`);
        player.outputChatBox('Error deleting character.');
    }
});

mp.events.add('server:character:select', async (player, characterId) => {
    try {
        const playerId = player.getVariable('dbId');
        if (!playerId) {
            return player.outputChatBox('Error: Player not authenticated.');
        }

        const character = await database.getCharacterById(characterId);
        if (!character || character.player_id !== playerId) {
            return player.outputChatBox('You do not own this character.');
        }

        player.model = mp.joaat(character.model);
        player.setVariable('characterId', character.id);
        player.spawn(new mp.Vector3(-425.5, 1123.5, 325.9));

        player.outputChatBox(`Playing as ${character.first_name} ${character.last_name}.`);
        player.call('client:hideCharacterUI');

    } catch (error) {
        console.error(`Error selecting character: ${error.message}`);
        player.outputChatBox('Error selecting character.');
    }
});

mp.events.add('client:previewCharacterModel', (player, modelName) => {
    if (modelName) {
        player.model = mp.joaat(modelName);
    }
});
