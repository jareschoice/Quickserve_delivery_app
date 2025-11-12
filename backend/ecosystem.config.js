/**
 * PM2 ecosystem file for QuickServe backend
 * Usage:
 *  - npm install -g pm2
 *  - pm2 start ecosystem.config.js --env production
 *  - pm2 save
 *  - pm2 startup (copy the generated systemd command)
 */

module.exports = {
  apps: [
    {
      name: 'quickserve-backend',
      script: 'server.js',
      cwd: __dirname,
      instances: 1,
      exec_mode: 'cluster',
      autorestart: true,
      watch: false,
      max_memory_restart: '512M',
      env: {
        NODE_ENV: 'development',
        PORT: 5555
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: process.env.PORT || 5555
      }
    }
  ]
};