mp.events.add('server:playerLoggedIn', (player, playerData) => {
    player.setVariable('dbId', playerData.id); // Store player's database ID
    player.setVariable('authenticated', true);
    mp.events.call('server:showCharacterUI', player); // Show character selection UI
	console.log('TEST LOGGEDIN');
});