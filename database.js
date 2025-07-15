const mysql = require('mysql2/promise');
const Redis = require('ioredis');
const config = require('./config.json');

let pool;
let redis;

async function initialize() {
    pool = mysql.createPool(config.mysql);
    redis = new Redis(config.redis);

    console.log('MySQL and Redis initialized.');

    // Create characters table if it doesn't exist
    await pool.query(`
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
    `);
    console.log('Characters table checked/created.');

    await loadAllDataToRedis();

    setInterval(saveAllDataFromRedis, config.server.dataSaveInterval);
}

async function loadAllDataToRedis() {
    try {
        const [rows] = await pool.query('SELECT * FROM players');
        for (const row of rows) {
            await redis.set(`player:${row.id}`, JSON.stringify(row));
        }
        console.log('All player data loaded to Redis.');
    } catch (error) {
        console.error('Error loading data to Redis:', error);
    }
}

async function saveAllDataFromRedis() {
    try {
        const keys = await redis.keys('player:*');
        if (keys.length === 0) return;

        const connection = await pool.getConnection();
        await connection.beginTransaction();

        try {
            for (const key of keys) {
                const data = await redis.get(key);
                const playerData = JSON.parse(data);
                const { id, ...updateData } = playerData;
                await connection.query('UPDATE players SET ? WHERE id = ?', [updateData, id]);
            }
            await connection.commit();
            console.log('All player data from Redis saved to MySQL.');
        } catch (error) {
            await connection.rollback();
            throw error;
        } finally {
            connection.release();
        }
    } catch (error) {
        console.error('Error saving data from Redis:', error);
    }
}

async function getPlayerData(playerId) {
    const data = await redis.get(`player:${playerId}`);
    return JSON.parse(data);
}

async function setPlayerData(playerId, data) {
    await redis.set(`player:${playerId}`, JSON.stringify(data));
}

async function getPlayerDataByEmail(email) {
    // For email availability checks, always query the master database directly.
    const [rows] = await pool.query('SELECT id, password FROM players WHERE email = ?', [email]);
    if (rows.length > 0) {
        // Return a simple object to indicate the email is taken.
        return { id: rows[0].id, password: rows[0].password };
    }
    // Return null if the email is available.
    return null;
}

async function createNewPlayer(email, password) {
    const [result] = await pool.query('INSERT INTO players (email, password) VALUES (?, ?)', [email, password]);
    const newPlayerId = result.insertId;
    const [rows] = await pool.query('SELECT * FROM players WHERE id = ?', [newPlayerId]);
    const newPlayerData = rows[0];
    await setPlayerData(newPlayerId, newPlayerData);
    return newPlayerData;
}

async function createCharacter(playerId, firstName, lastName, age, description, gender, model) {
    const [result] = await pool.query(
        'INSERT INTO characters (player_id, first_name, last_name, age, description, gender, model) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [playerId, firstName, lastName, age, description, gender, model]
    );
    return result.insertId;
}

async function getCharactersByPlayerId(playerId) {
    const [rows] = await pool.query('SELECT * FROM characters WHERE player_id = ?', [playerId]);
    return rows;
}

async function deleteCharacter(characterId) {
    await pool.query('DELETE FROM characters WHERE id = ?', [characterId]);
}

async function getCharacterById(characterId) {
    const [rows] = await pool.query('SELECT * FROM characters WHERE id = ?', [characterId]);
    return rows.length > 0 ? rows[0] : null;
}

module.exports = {
    initialize,
    getPlayerData,
    setPlayerData,
    saveAllDataFromRedis,
    getPlayerDataByEmail,
    createNewPlayer,
    createCharacter,
    getCharactersByPlayerId,
    deleteCharacter,
    getCharacterById
};