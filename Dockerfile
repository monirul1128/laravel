# =====================================================
# Stage 1: Node Build (Light & Stable)
# =====================================================
FROM node:20-alpine AS node-builder

WORKDIR /app

COPY package*.json ./

# Install dependencies
RUN npm install --legacy-peer-deps --ignore-scripts

COPY . .

# Build with memory safe mode
ENV NODE_OPTIONS="--max-old-space-size=512"

RUN npm run build || echo "Build warning ignored"


# =====================================================
# Stage 2: PHP Production
# =====================================================
FROM php:8.2-fpm-alpine

WORKDIR /var/www

# Install required extensions
RUN apk add --no-cache \
  git \
  curl \
  libpq-dev \
  zip \
  unzip \
  nodejs \
  npm

RUN docker-php-ext-install pdo pdo_pgsql

# Install composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy Laravel app
COPY . .

# Copy built assets
COPY --from=node-builder /app/public/build ./public/build

# Install composer
RUN composer install --no-dev --optimize-autoloader

# Fix permissions
RUN chmod -R 775 storage bootstrap/cache

# Cache optimize
RUN php artisan config:cache \
  && php artisan route:cache \
  && php artisan view:cache

EXPOSE 10000

CMD php artisan serve --host=0.0.0.0 --port=10000
