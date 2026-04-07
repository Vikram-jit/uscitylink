#!/bin/bash

echo "🚀 Starting deployment..."

BASE_DIR="/var/www/html/uscitylink"
SOURCE_DIR="$BASE_DIR/web"

APP_3004="$BASE_DIR/web-3004"
APP_3012="$BASE_DIR/web-3012"

# ==============================
# 1. Clean old builds
# ==============================
echo "🧹 Cleaning old builds..."
rm -rf $APP_3004
rm -rf $APP_3012

# ==============================
# 2. Copy project
# ==============================
echo "📁 Copying project..."
cp -r $SOURCE_DIR $APP_3004
cp -r $SOURCE_DIR $APP_3012

# ==============================
# 3. Link node_modules (save space)
# ==============================
echo "🔗 Linking node_modules..."
rm -rf $APP_3004/node_modules
rm -rf $APP_3012/node_modules

ln -s $SOURCE_DIR/node_modules $APP_3004/node_modules
ln -s $SOURCE_DIR/node_modules $APP_3012/node_modules

# ==============================
# 4. Build for 3004 (IP)
# ==============================
echo "🏗️ Building app-3004..."

cd $APP_3004

NEXT_PUBLIC_API_URL="http://52.9.12.189:4300/api/v1" \
NEXT_PUBLIC_SOCKET_URL="http://52.9.12.189:4300" \
npm run build

# ==============================
# 5. Build for 3012 (DOMAIN)
# ==============================
echo "🏗️ Building app-3012..."

cd $APP_3012

NEXT_PUBLIC_API_URL="https://chatbox-server.truckcrave.com/api/v1" \
NEXT_PUBLIC_SOCKET_URL="https://chatbox-server.truckcrave.com" \
npm run build

# ==============================
# 6. Restart PM2
# ==============================
echo "🔄 Restarting PM2..."

pm2 restart app-3004 || pm2 start ecosystem.config.js --only app-3004
pm2 restart app-3012 || pm2 start ecosystem.config.js --only app-3012

pm2 save

echo "✅ Deployment completed!"