# Use PHP 8.2 CLI
FROM php:8.2-cli

WORKDIR /var/www

# Install system dependencies
RUN apt-get update && apt-get install -y \
  git curl unzip libzip-dev zip nodejs npm \
  && docker-php-ext-install pdo pdo_mysql zip

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy project files
COPY . .

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Install Node dependencies + Build assets
RUN npm install \
  && npm run build

# Storage + permission fix
RUN chmod -R 775 storage bootstrap/cache

# Optional: If using sqlite
RUN touch database/database.sqlite

# Expose port for Render
EXPOSE 10000

# Run Laravel
CMD php artisan optimize:clear \
  && php artisan config:cache \
  && php artisan route:cache \
  && php artisan view:cache \
  && php artisan serve --host=0.0.0.0 --port=10000
