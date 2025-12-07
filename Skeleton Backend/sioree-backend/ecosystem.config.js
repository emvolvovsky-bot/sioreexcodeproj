// PM2 Ecosystem Configuration
// This keeps your backend running automatically
// Environment variables are loaded from .env file (not committed to git)
// This file is safe to commit as it doesn't contain secrets

module.exports = {
  apps: [{
    name: 'sioree-backend',
    script: 'src/index.js',
    cwd: __dirname,
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '500M',
    // Default values (override with .env file)
    env: {
      NODE_ENV: 'production',
      PORT: 4000
    },
    // Development overrides (if needed)
    env_development: {
      NODE_ENV: 'development',
      PORT: 4000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true
  }]
};


