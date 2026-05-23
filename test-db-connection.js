// backend/scripts/test-db-connection.js
require('dotenv').config();
const { connectDB } = require('../src/config/db');

(async () => {
    try {
        await connectDB();
        console.log('Test script finished successfully');
        process.exit(0);
    } catch (err) {
        console.error('Test script error:', err && err.message ? err.message : err);
        process.exit(1);
    }
})();
