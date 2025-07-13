let authBrowser = null;
let characterBrowser = null;

const loginView = mp.cameras.new('loginView', 
	new mp.Vector3(726.0, 1196.0, 345.0),
	new mp.Vector3(0.0, 0.0, 0.0),
	50
); 

mp.events.add('client:showLoginUI', () => {
    if (!authBrowser) {
        authBrowser = mp.browsers.new('package://account-system/index.html');
        setTimeout(() => {
            mp.gui.cursor.show(true, true);
            mp.gui.chat.activate(false);
            
            mp.game.ui.displayRadar(false);
            mp.game.ui.displayHud(false);
        }, 100);
    }
});

mp.events.add('client:closeAuthUI', () => {
	mp.gui.chat.push('client:closeAuthUI');
    if (authBrowser) {
        authBrowser.destroy();
        authBrowser = null;
    }
	mp.gui.chat.activate(true);
    mp.gui.cursor.show(false, false);
	
    mp.game.ui.displayRadar(true);
    mp.game.ui.displayHud(true);	
	
    mp.game.cam.renderScriptCams(false, false, 0, true, false);
    
    if (mp.cameras.exists(loginView)) {
        loginView.setActive(false);
        loginView.destroy();
    }	
});

mp.events.add('playerReady', (player) => {
	loginView.pointAtCoord(0.0, 0.0, 50.0);
		
	loginView.setActive(true);
	mp.game.cam.renderScriptCams(true, true, 0, true, false);
});

mp.events.add('showVerificationInput', () => {
    if (authBrowser) {
        authBrowser.execute('showVerificationInput();');
    }
});

mp.events.add('client:setEmailStatus', (isAvailable) => {
    if (authBrowser) {
        authBrowser.execute(`setEmailStatus(${!isAvailable});`);
    }
});

// --- Event forwarding to server ---
mp.events.add('client:checkEmail', (email) => {
    mp.events.callRemote('server:checkEmail', email);
});

mp.events.add('client:requestVerificationCode', (email, password) => {
    mp.events.callRemote('server:requestVerificationCode', email, password);
});

mp.events.add('client:playerLogin', (email, password) => {
    mp.events.callRemote('server:playerLogin', email, password);
});

mp.events.add('client:playerVerify', (email, code) => {
    mp.events.callRemote('server:playerVerify', email, code);
});

mp.events.add('client:showCharacterSelection', (characters, modelsData) => {
    if (!characterBrowser) {
        characterBrowser = mp.browsers.new('package://character-system/index.html');
    }
    
    const charactersJson = JSON.stringify(characters);
    const modelsDataJson = JSON.stringify(modelsData);

    setTimeout(() => {
        characterBrowser.execute(`mp.events.call('client:showCharacterUI', ${charactersJson}, ${modelsDataJson})`);
        mp.gui.cursor.show(true, true);
        mp.gui.chat.activate(false);
        mp.game.ui.displayRadar(false);
        mp.game.ui.displayHud(false);
    }, 500); // Increased timeout to allow browser to load
});

mp.events.add('client:hideCharacterUI', () => {
    if (characterBrowser) {
        characterBrowser.destroy();
        characterBrowser = null;
    }
    mp.gui.cursor.show(false, false);
    mp.gui.chat.activate(true);
    mp.game.ui.displayRadar(true);
    mp.game.ui.displayHud(true);
});

mp.events.add('client:previewCharacterModel', (modelName) => {
    mp.events.callRemote('client:previewCharacterModel', modelName);
});
