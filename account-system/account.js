const bcrypt = require('bcrypt');
const nodemailer = require('nodemailer');
const database = require('../database');
const config = require('../config.json');
const eventHandler = require('./events');

const saltRounds = 10;
const verificationCodes = new Map();

const transporter = nodemailer.createTransport(config.mailer);

async function handleLogin(player, email, password) {
    const playerData = await database.getPlayerDataByEmail(email);
    if (!playerData) {
        player.outputChatBox('Invalid email or password.');
        return;
    }

    const match = await bcrypt.compare(password, playerData.password);
    if (match) {
        player.call('client:closeAuthUI'); // This closes the UI
        mp.events.call('server:playerLoggedIn', player, playerData);
    } else {
        player.outputChatBox('Invalid email or password.');
    }
}

async function checkEmailAvailability(player, email) {
    const existingPlayer = await database.getPlayerDataByEmail(email);
	console.log('Existing : ', existingPlayer);
    player.call('client:setEmailStatus', !existingPlayer);
}

async function requestVerificationCode(player, email, password) {
    // Re-check just in case
    const existingPlayer = await database.getPlayerDataByEmail(email);
    if (existingPlayer) {
        player.call('client:setEmailStatus', false);
        return;
    }

    const code = Math.floor(100000 + Math.random() * 900000).toString();
    // Store password temporarily with the code, associated with the player object
    verificationCodes.set(player.socialClub, { email, password, code });

    const mailOptions = {
        from: config.mailer.from,
        to: email,
        subject: 'Your Verification Code',
        text: `Your verification code is: ${code}`
    };

    try {
        await transporter.sendMail(mailOptions);
        player.call('client:showVerificationInput');
    } catch (error) {
        console.error('Error sending email:', error);
        player.outputChatBox('Failed to send verification email. Please try again.');
    }
}

async function handleVerifyAndRegister(player, providedEmail, code) {
    const verificationData = verificationCodes.get(player.socialClub);

    if (!verificationData || verificationData.email !== providedEmail || verificationData.code !== code) {
        player.outputChatBox('Invalid verification code.');
        return;
    }

    const { email, password } = verificationData;

    const hashedPassword = await bcrypt.hash(password, saltRounds);
    const newPlayer = await database.createNewPlayer(email, hashedPassword);

    verificationCodes.delete(player.socialClub);

    player.outputChatBox('Registration successful! Please log in.');
    // We can call playerReady to close the UI and let them login manually
    // or automatically log them in.
    player.call('client:closeAuthUI'); // Close UI
    setTimeout(() => player.call('client:showLoginUI'), 500); // Re-open login form
}

mp.events.add('server:playerLogin', handleLogin);
mp.events.add('server:checkEmail', checkEmailAvailability);
mp.events.add('server:requestVerificationCode', requestVerificationCode);
mp.events.add('server:playerVerify', handleVerifyAndRegister);

module.exports = {};