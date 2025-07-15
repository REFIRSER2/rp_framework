// FiveM NUI Communication
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.type) {
        case 'showAuth':
            showAuthUI(data.page || 'login');
            break;
            
        case 'closeAuth':
            hideAuthUI();
            break;
            
        case 'showVerificationInput':
            if (window.showVerificationInput) {
                window.showVerificationInput();
            }
            break;
            
        case 'setEmailStatus':
            if (window.setEmailStatus) {
                window.setEmailStatus(data.available);
            }
            break;
            
        case 'showCharacterUI':
            showCharacterUI(data.characters, data.models);
            break;
            
        case 'hideCharacterUI':
            hideCharacterUI();
            break;
            
        case 'escapePressed':
            handleEscapeKey();
            break;
    }
});

// Show Auth UI
function showAuthUI(page) {
    $('#authContainer').show();
    $('#characterContainer').hide();
    
    // Load auth HTML if not loaded
    if ($('#authContainer').html().trim() === '') {
        $.get('account-system/index.html', function(html) {
            // Extract body content
            const bodyContent = $(html).filter('#app').prop('outerHTML');
            $('#authContainer').html(bodyContent);
            
            // Initialize auth system
            if (window.initAuthSystem) {
                window.initAuthSystem();
            }
        });
    }
}

// Hide Auth UI
function hideAuthUI() {
    $('#authContainer').hide();
}

// Show Character UI
function showCharacterUI(characters, models) {
    $('#characterContainer').show();
    $('#authContainer').hide();
    
    // Load character HTML if not loaded
    if ($('#characterContainer').html().trim() === '') {
        $.get('character-system/index.html', function(html) {
            // Extract body content
            const bodyContent = $(html).filter('#character-container').prop('outerHTML');
            $('#characterContainer').html(bodyContent);
            
            // Initialize character system
            if (window.initCharacterSystem) {
                window.initCharacterSystem(characters, models);
            }
        });
    } else {
        // Update character list
        if (window.updateCharacterList) {
            window.updateCharacterList(characters, models);
        }
    }
}

// Hide Character UI
function hideCharacterUI() {
    $('#characterContainer').hide();
}

// Handle ESC key
function handleEscapeKey() {
    // Check if any modal is open
    if ($('.modal:visible').length > 0) {
        $('.modal').hide();
    } else {
        // Release focus
        $.post('https://fivem-rp-framework/releaseFocus', JSON.stringify({}));
    }
}

// FiveM NUI Callback wrapper
function nuiCallback(endpoint, data = {}) {
    return $.post(`https://fivem-rp-framework/${endpoint}`, JSON.stringify(data));
}

// Global functions for auth and character systems
window.mp = {
    trigger: function(eventName, ...args) {
        nuiCallback(eventName, { args: args });
    }
};

// Initialize
$(document).ready(function() {
    nuiCallback('authReady');
    nuiCallback('characterUIReady');
});