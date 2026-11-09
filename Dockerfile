# KondoManager di Toto: immagini dal sorgente a monte fissato in versione.lock, portato in sorgente/ da
# prepara_sorgente.sh. Stadi: vendor (composer, senza dipendenze di sviluppo), assets (vite), app (php-fpm, anche per
# il worker), web (nginx con public/), più fonte (il sorgente con le correzioni). Digest fissati: si cambiano dopo il
# collaudo verde (LEGGIMI.md).
# Le correzioni di correzioni/ si applicano qui, nella costruzione, e non in sorgente/: sorgente/ è il clone a monte al
# commit di versione.lock e prepara_sorgente.sh rifiuta ogni modifica locale. Le patch stanno fuori da /src, perché
# non finiscano nelle immagini; una che non si applica ferma la costruzione.
FROM composer:2@sha256:8de2184c6de224f4689e8f80ed5f5edaf0030b6b8b7839a22a2bcb6722ac87d0 AS fonte
COPY sorgente/ /src
COPY correzioni/ /correzioni/
COPY applica_correzioni.sh /applica_correzioni.sh
COPY sorgente_pubblico.sh /sorgente_pubblico.sh
RUN sh /applica_correzioni.sh /src /correzioni
# il collegamento al sorgente delle pagine del programma punta al deposito pubblico delle correzioni (AGPL-3.0, sez. 13)
RUN sh /sorgente_pubblico.sh /src https://github.com/steketo/kondomanager-correzioni

FROM composer:2@sha256:8de2184c6de224f4689e8f80ed5f5edaf0030b6b8b7839a22a2bcb6722ac87d0 AS vendor
WORKDIR /app
COPY --from=fonte /src ./
# il lock del kit al posto di quello a monte: le librerie di librerie.txt alle versioni corrette (rifai_lock.sh)
COPY composer.lock ./composer.lock
# --no-scripts: package:discover lo rifà Laravel nel contenitore, dove bootstrap/cache è un tmpfs che riparte vuoto;
# --ignore-platform-reqs: l'immagine composer non ha gd e intl, che ha lo stadio app
RUN composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader --no-scripts --ignore-platform-reqs

FROM node:22-bookworm-slim@sha256:5ec23b7c622b00547753bc6ffd78085dd868a68aeb41c8e0a1418f033e13d96d AS assets
WORKDIR /app
COPY --from=fonte /src ./
# vite risolve ziggy-js dal pacchetto PHP (vite.config.ts a monte)
COPY --from=vendor /app/vendor/tightenco/ziggy ./vendor/tightenco/ziggy
RUN npm ci --no-audit --no-fund && npm run build

FROM php:8.4-fpm-bookworm@sha256:b75642e8c89c321039f351466134df951576fb0f7017117b3931e9a19b908d6c AS app
ARG KONDO_COMMIT
LABEL toto.kondo.commit=$KONDO_COMMIT
# estensioni di docker/standard/Dockerfile:9 a monte, più opcache; supervisor per il worker
RUN apt-get update && apt-get install -y --no-install-recommends libpng-dev libonig-dev libxml2-dev libzip-dev \
      libicu-dev supervisor \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip intl opcache \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
COPY php.ini /usr/local/etc/php/conf.d/zz-toto.ini
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
WORKDIR /var/www
COPY --from=vendor /app /var/www
COPY --from=assets /app/public/build /var/www/public/build
# punti di montaggio già nell'immagine (docker diff resta vuoto): storage/ e .env vengono dalla radice, bootstrap/cache
# e vendor/mpdf/mpdf/tmp sono tmpfs (compose.yaml)
RUN rm -rf storage bootstrap/cache/* node_modules tests .env && mkdir storage && touch .env
# psysh (tinker) e fontconfig scrivono sotto HOME: /tmp è un tmpfs
ENV HOME=/tmp
# in fondo, dopo apt-get: un elenco diverso di correzioni non ricompila le estensioni
ARG KONDO_CORREZIONI
LABEL toto.kondo.correzioni=$KONDO_CORREZIONI

FROM nginx:stable-alpine@sha256:583b7f2fce1cdb8da5ad5c39ebd3c33b98b87d493190e548bdee1fa8c619c311 AS web
ARG KONDO_COMMIT
LABEL toto.kondo.commit=$KONDO_COMMIT
COPY --from=vendor /app/public /var/www/public
COPY --from=assets /app/public/build /var/www/public/build
COPY nginx.conf /etc/nginx/conf.d/default.conf
RUN mkdir -p /var/www/storage/app/public
ARG KONDO_CORREZIONI
LABEL toto.kondo.correzioni=$KONDO_CORREZIONI
