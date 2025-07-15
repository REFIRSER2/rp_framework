// Menus
const selectionMenu = document.getElementById('selection-menu');
const creationMenu = document.getElementById('creation-menu');
const modelSelector = document.querySelector('.model-selector');

// Character List
const characterList = document.getElementById('character-list');

// Buttons
const goToCreationBtn = document.getElementById('go-to-creation-btn');
const backToSelectionBtn = document.getElementById('back-to-selection-btn');
const createCharBtn = document.getElementById('create-char-btn');
const prevModelBtn = document.getElementById('prev-model');
const nextModelBtn = document.getElementById('next-model');
const genderMaleBtn = document.getElementById('gender-male');
const genderFemaleBtn = document.getElementById('gender-female');

// Inputs & Displays
const charFirstNameInput = document.getElementById('char-first-name');
const charLastNameInput = document.getElementById('char-last-name');
const charAgeInput = document.getElementById('char-age');
const charDescriptionInput = document.getElementById('char-description'); // New textarea
const modelNameDisplay = document.getElementById('model-name-display');

// State
let models = { "0": [], "1": [] };
let selectedGender = 0;
let currentModelIndex = 0;
let playermodel = '';

// --- Age Input Validation ---
charAgeInput.addEventListener('blur', () => {
    let age = parseInt(charAgeInput.value, 10);
    const minAge = parseInt(charAgeInput.min, 10);
    const maxAge = parseInt(charAgeInput.max, 10);

    if (isNaN(age)) {
        age = minAge; // Default to min if input is not a number
    } else if (age < minAge) {
        age = minAge;
    } else if (age > maxAge) {
        age = maxAge;
    }
    charAgeInput.value = age;
});

// --- UI Navigation ---
goToCreationBtn.addEventListener('click', () => {
    selectionMenu.style.display = 'none';
    creationMenu.style.display = 'block';
    $.post('https://fivem-rp-framework/enterCharacterCreation', JSON.stringify({}));
    modelSelector.style.display = 'flex';
    currentModelIndex = 0;
    updateModelPreview();
});

backToSelectionBtn.addEventListener('click', () => {
    creationMenu.style.display = 'none';
    modelSelector.style.display = 'none';
    selectionMenu.style.display = 'flex';
    $.post('https://fivem-rp-framework/exitCharacterCreation', JSON.stringify({}));
});

// --- Gender Selection ---
genderMaleBtn.addEventListener('click', () => setGender(0));
genderFemaleBtn.addEventListener('click', () => setGender(1));

function setGender(gender) {
    selectedGender = gender;
    genderMaleBtn.classList.toggle('selected', gender === 0);
    genderFemaleBtn.classList.toggle('selected', gender === 1);
    currentModelIndex = 0;
    updateModelPreview();
}

// --- Model Selection ---
prevModelBtn.addEventListener('click', () => {
    const currentGenderModels = models[selectedGender] || [];
    if (currentGenderModels.length === 0) return;
    currentModelIndex = (currentModelIndex - 1 + currentGenderModels.length) % currentGenderModels.length;
    updateModelPreview();
});

nextModelBtn.addEventListener('click', () => {
    const currentGenderModels = models[selectedGender] || [];
    if (currentGenderModels.length === 0) return;
    currentModelIndex = (currentModelIndex + 1) % currentGenderModels.length;
    updateModelPreview();
});

function updateModelPreview() {
    const currentGenderModels = models[selectedGender] || [];
    if (currentGenderModels.length > 0) {
        playermodel = currentGenderModels[currentModelIndex];
        modelNameDisplay.textContent = playermodel;
        $.post('https://fivem-rp-framework/previewCharacter', JSON.stringify({ model: playermodel }));
    } else {
        playermodel = '';
        modelNameDisplay.textContent = 'No Models';
    }
}

// --- Character Actions ---
createCharBtn.addEventListener('click', () => {
    const firstName = charFirstNameInput.value;
    const lastName = charLastNameInput.value;
    const age = parseInt(charAgeInput.value);
    const description = charDescriptionInput.value;

	//mp.gui.chat.push('Create Click', firstName, lastName, age);
    if (!firstName || !lastName || !age) {
        console.log('Please fill all character details.');
        return;
    }
	
	
    if (!playermodel) {
        console.log('No model selected.');
        return;
    }

    $.post('https://fivem-rp-framework/createCharacter', JSON.stringify({
        firstName: firstName,
        lastName: lastName,
        age: age,
        description: description,
        gender: selectedGender,
        model: playermodel
    }));
});

characterList.addEventListener('click', (event) => {
    const target = event.target;
    const actionsDiv = target.closest('.char-actions');
    if (!actionsDiv) return;

    const charId = actionsDiv.dataset.charId;
    if (target.classList.contains('select-btn')) {
        $.post('https://fivem-rp-framework/selectCharacter', JSON.stringify({ characterId: parseInt(charId) }));
    }
    if (target.classList.contains('delete-btn')) {
        if (confirm('Are you sure?')) {
            $.post('https://fivem-rp-framework/deleteCharacter', JSON.stringify({ characterId: parseInt(charId) }));
        }
    }
});

// Initialize character system when loaded
window.initCharacterSystem = function(characters, receivedModels) {
    updateCharacterList(characters, receivedModels);
};

window.updateCharacterList = function(characters, receivedModels) {
    // Assign the received models to the global models variable
    if (receivedModels) {
        models = receivedModels;
    }

    characterList.innerHTML = '';
    if (characters && characters.length > 0) {
        characters.forEach(char => {
            const li = document.createElement('li');
            li.innerHTML = `
                <span class="char-name">${char.first_name} ${char.last_name}</span>
                <div class="char-actions" data-char-id="${char.id}">
                    <button class="select-btn">Select</button>
                    <button class="delete-btn">Delete</button>
                </div>
            `;
            characterList.appendChild(li);
        });
    } else {
        characterList.innerHTML = '<li>No characters found.</li>';
    }
    selectionMenu.style.display = 'flex';
    creationMenu.style.display = 'none';
    modelSelector.style.display = 'none';
    setGender(0); // Default to male and update preview
    
    // Re-attach event listeners for dynamically created buttons
    document.querySelectorAll('.select-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            const charId = this.parentElement.dataset.charId;
            $.post('https://fivem-rp-framework/selectCharacter', JSON.stringify({ characterId: parseInt(charId) }));
        });
    });
    
    document.querySelectorAll('.delete-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            const charId = this.parentElement.dataset.charId;
            if (confirm('Are you sure?')) {
                $.post('https://fivem-rp-framework/deleteCharacter', JSON.stringify({ characterId: parseInt(charId) }));
            }
        });
    });
};
