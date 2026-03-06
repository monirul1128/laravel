FROM php:8.2-cli

WORKDIR /var/www

RUN apt-get update && apt-get install -y \
  git curl unzip libzip-dev zip

RUN docker-php-ext-install pdo pdo_mysql zip

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY . .

RUN composer install --no-dev --optimize-autoloader

# Create SQLite database
RUN touch database/database.sqlite

# Fix permissions
RUN chmod -R 775 storage bootstrap/cache database

EXPOSE 10000

CMD php artisan serve --host=0.0.0.0 --port=10000
