const database = require('./database');
require('./account-system/account'); 
require('./character-system/character'); // Load character system 

mp.events.add('packagesLoaded', async () => {
    await database.initialize();
    console.log('RP Framework Initialized.');
});

mp.events.add('playerJoin', (player) => {
	console.log(`[SERVER]: ${player.name} has joined the server!`);
    
    player.dimension = player.id + 1000;
    player.position = new mp.Vector3(0, 0, -1000);
	player.freezePosition = true;
    player.setVariable('authenticated', false);	
	
	player.call('client:showLoginUI');
});

mp.events.add('playerQuit', async (player) => {
    await database.saveAllDataFromRedis();
});

process.on('exit', async (code) => {
    console.log(`Server is shutting down with code: ${code}`);
    await database.saveAllDataFromRedis();
    console.log('All data saved. Goodbye!');
});
