# Описание Dockerfile для Taiga (back):
Использование дистрибутива alpine
```
FROM alpine:3.10
```
Задание используемой версии 
```
ARG VERSION=4.2.14
```
Задание переменных окружения 
```
ENV TAIGA_HOST=localhost \
	TAIGA_SECRET=secret \
	TAIGA_SCHEME=http \
	POSTGRES_HOST=db \
	POSTGRES_DB=taiga \
	POSTGRES_USER=postgres \
	POSTGRES_PASSWORD=password \
	RABBIT_HOST=rabbit \
	RABBIT_PORT=5672 \
	RABBIT_USER=taiga \
	RABBIT_PASSWORD=password \
	RABBIT_VHOST=taiga \
	STARTUP_TIMEOUT=15s
```
Задание рабочей директории для Taiga в целом.
```
WORKDIR /srv/taiga
```
Установка зависимостей
```
RUN apk --no-cache add python3 gettext postgresql-dev libxslt-dev libxml2-dev libjpeg-turbo-dev zeromq-dev libffi-dev nginx \
	&& apk add --no-cache --virtual .build-dependencies git g++ musl-dev linux-headers python3-dev zlib-dev libjpeg-turbo-dev freetype-dev \
	&& mkdir logs \
	&& git clone --depth=1 -b $VERSION https://github.com/taigaio/taiga-back.git back && cd back \
	&& pip3 install --no-cache-dir -r requirements.txt \
	&& rm -rf /root/.cache \
	&& apk del .build-dependencies \
	&& rm /srv/taiga/back/settings/local.py.example \
	&& rm /etc/nginx/conf.d/default.conf
```
Открытие 80 порта
```
EXPOSE 80
```
Задание рабочей директории для back
```
WORKDIR /srv/taiga/back
```
Копирование необходимых файлов для работы контейнера 
```
COPY config.py /tmp/taiga-conf/
COPY nginx.conf /etc/nginx/conf.d/
COPY start.sh /
```
Задание хранилища 
```
VOLUME ["/taiga-conf", "/taiga-media"]
```
Запуск сервиса 
```
CMD ["/start.sh"]
```
# Описание Dockerfile для Taiga (events):
Использование дистрибутива Nodejs
```
FROM node:alpine
```
Задание переменных окружения 
```
```
ENV RABBIT_HOST=rabbit \
```
RABBIT_PORT=5672 \
	RABBIT_VHOST=taiga \
	RABBIT_USER=taiga \
	RABBIT_PASSWORD=password \
	TAIGA_SECRET=secret
```
Установка рабочей директории
```
WORKDIR /usr/src/
```
Установка зависимостей
```
RUN apk add --no-cache --virtual .build-dependencies git perl \
	&& git clone https://github.com/taigaio/taiga-events.git taiga-events && cd taiga-events \
	&& perl -0777 -pe 's/"devDependencies": \{.*?\},//s' -i package.json \
	&& apk del .build-dependencies \
	&& yarn --production && yarn global add coffeescript
```
Установка рабочей директории для скачанного taiga-events 
```
WORKDIR /usr/src/taiga-events
```
Открытие 8888 порта 
```
EXPOSE 8888
```
Копирование необходимых файлов конфигурации и запуска приложения
```
COPY config.json ./
COPY start.sh /
```
Запуск приложения 
```
CMD ["/start.sh"]
```
# Описание Dockerfile для Taiga (front):
Основан на nginx
```
FROM nginx:alpine
```
Задание используемой версии
```
ARG VERSION=4.2.14
```
Задание переменных окружения 
```
ENV TAIGA_HOST=localhosts \
	TAIGA_SCHEME=http
```
Задание рабочей директории для Taiga в целом.
```
WORKDIR /srv/taiga
```
Установка зависимостей
```
RUN apk --no-cache add git \
	&& rm /etc/nginx/conf.d/default.conf \
	&& mkdir /run/nginx \
	&& git clone --depth=1 -b $VERSION-stable https://github.com/taigaio/taiga-front-dist.git front && cd front \
	&& apk del git \   
	&& rm dist/conf.example.json
```
Задание рабочей директории для скачанного taiga-front-dist.
```
WORKDIR /srv/taiga/front/dist
```
Копирование необходимых файлов конфигурации и запуска приложения
```
COPY start.sh /
COPY nginx.conf /etc/nginx/conf.d/
COPY config.json /tmp/taiga-conf/
```
Формирование хранилища
```
VOLUME ["/taiga-conf"]
```
Запуск сервиса
```
CMD ["/start.sh"]
```









