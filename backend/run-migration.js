require('dotenv').config();
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

// Create database connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
});

async function runMigration() {
  const client = await pool.connect();
  
  try {
    console.log('🔄 Running migration: 013_add_group_chats.sql');
    
    const migrationPath = path.join(__dirname, 'migrations', '013_add_group_chats.sql');
    const sql = fs.readFileSync(migrationPath, 'utf8');
    
    await client.query('BEGIN');
    
    // Run the migration
    await client.query(sql);
    
    await client.query('COMMIT');
    
    console.log('✅ Migration completed successfully!');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Migration failed:', error.message);
    console.error(error);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

runMigration();

