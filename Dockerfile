FROM php:8.2-cli

# Work directory
WORKDIR /var/www

# Install system dependencies + postgres + node
RUN apt-get update && apt-get install -y \
  git \
  curl \
  unzip \
  libzip-dev \
  zip \
  libpq-dev \
  nodejs \
  npm \
  && docker-php-ext-install \
  pdo \
  pdo_pgsql \
  pdo_mysql \
  zip

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy project files
COPY . .

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Install frontend dependencies + build assets
RUN npm install
RUN npm run build

# Optimize Laravel (important for production)
RUN php artisan config:clear
RUN php artisan cache:clear
RUN php artisan route:clear
RUN php artisan view:clear
RUN php artisan optimize

# Fix permissions
RUN chmod -R 775 storage bootstrap/cache

# If using SQLite (optional)
RUN touch database/database.sqlite

# Expose Render port
EXPOSE 10000

# Start server
CMD php artisan serve --host=0.0.0.0 --port=10000
