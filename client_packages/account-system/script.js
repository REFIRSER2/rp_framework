const loginForm = document.getElementById('login-form');
const registerForm = document.getElementById('register-form');
const verificationSection = document.getElementById('verification-section');

// --- Form Switching ---
document.getElementById('show-register').addEventListener('click', () => {
    loginForm.style.display = 'none';
    verificationSection.style.display = 'none';
    registerForm.style.display = 'block';
});

document.getElementById('show-login').addEventListener('click', () => {
    registerForm.style.display = 'none';
    loginForm.style.display = 'block';
});

// --- Input Validation States ---
let isEmailValid = false;
let isPasswordValid = false;

const registerEmailInput = document.getElementById('register-email');
const emailStatus = document.getElementById('email-status');
const registerPasswordInput = document.getElementById('register-password');
const registerPasswordConfirmInput = document.getElementById('register-password-confirm');
const passwordStatus = document.getElementById('password-status');
const sendCodeBtn = document.getElementById('send-code-btn');

// --- Event Listeners ---
registerEmailInput.addEventListener('blur', () => {
    const email = registerEmailInput.value;
    if (validateEmail(email)) {
        mp.trigger('client:checkEmail', email);
    } else {
        emailStatus.textContent = 'Invalid email format.';
        emailStatus.className = 'status-error';
        isEmailValid = false;
        updateSendCodeButtonState();
    }
});

registerPasswordInput.addEventListener('input', validatePasswordMatch);
registerPasswordConfirmInput.addEventListener('input', validatePasswordMatch);

sendCodeBtn.addEventListener('click', () => {
    const email = registerEmailInput.value;
    const password = registerPasswordInput.value;
    mp.trigger('client:requestVerificationCode', email, password);
});

document.getElementById('login-btn').addEventListener('click', () => {
    const email = document.getElementById('login-email').value;
    const password = document.getElementById('login-password').value;
    mp.trigger('client:playerLogin', email, password);
});

document.getElementById('verify-btn').addEventListener('click', () => {
    const email = registerEmailInput.value;
    const code = document.getElementById('verify-code').value;
    mp.trigger('client:playerVerify', email, code);
});

// --- Validation Functions ---
function validateEmail(email) {
    const re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    return re.test(String(email).toLowerCase());
}

function validatePasswordMatch() {
    const password = registerPasswordInput.value;
    const confirmPassword = registerPasswordConfirmInput.value;
    if (password && confirmPassword) {
        if (password === confirmPassword) {
            passwordStatus.textContent = 'Passwords match.';
            passwordStatus.className = 'status-success';
            isPasswordValid = true;
        } else {
            passwordStatus.textContent = 'Passwords do not match.';
            passwordStatus.className = 'status-error';
            isPasswordValid = false;
        }
    } else {
        passwordStatus.textContent = '';
        isPasswordValid = false;
    }
    updateSendCodeButtonState();
}

function updateSendCodeButtonState() {
    sendCodeBtn.disabled = !(isEmailValid && isPasswordValid);
}

// --- Functions called from Server ---
function setEmailStatus(isAvailable) {
    if (isAvailable) {
        emailStatus.textContent = 'Email is available.';
        emailStatus.className = 'status-success';
        isEmailValid = true;
    } else {
        emailStatus.textContent = 'Email is already taken.';
        emailStatus.className = 'status-error';
        isEmailValid = false;
    }
    updateSendCodeButtonState();
}

function showVerificationInput() {
    verificationSection.style.display = 'block';
}

function closeAuthUI() {
    const container = document.getElementById('auth-container');
    if (container) {
        container.style.display = 'none';
    }
}
