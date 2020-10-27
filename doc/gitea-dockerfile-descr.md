# Описание Dockerfile для Gitea:
Для сборки используется язык программирования GO:
```
FROM golang:1.14-alpine3.11 AS build-env
```
Задание аргументов и переменных окружения
```

ARG GOPROXY
ENV GOPROXY ${GOPROXY:-direct}

ARG GITEA_VERSION
ARG TAGS="sqlite sqlite_unlock_notify"
ENV TAGS "bindata $TAGS"
```
Сборка пакетов зависимостей 
```
RUN apk --no-cache add build-base git nodejs npm
```
Создание репозитория 
```
COPY . ${GOPATH}/src/code.gitea.io/gitea
WORKDIR ${GOPATH}/src/code.gitea.io/gitea
```
Проверка версии, если пакеты уже установлены
```
RUN if [ -n "${GITEA_VERSION}" ]; then git checkout "${GITEA_VERSION}"; fi \
 && make clean-all build
 ```
 Открытие портов 22 и 3000
 ```
 EXPOSE 22 3000
 ```
 Установка зависимостей
 ```
 RUN apk --no-cache add \
    bash \
    ca-certificates \
    curl \
    gettext \
    git \
    linux-pam \
    openssh \
    s6 \
    sqlite \
    su-exec \
    tzdata
 ```
 Добавление нового пользователя и новой группы для управления файлами, изменение владельца
 ```
 RUN addgroup \
    -S -g 1000 \
    git && \
  adduser \
    -S -H -D \
    -h /data/git \
    -s /bin/bash \
    -u 1000 \
    -G git \
    git && \
  echo "git:$(dd if=/dev/urandom bs=24 count=1 status=none | base64)" | chpasswd
 ```
 Передача переменных среды пользователя и пути Gitea
 ```
 ENV USER git
ENV GITEA_CUSTOM /data/gitea
 ```
 Формирование хранилища
 ```
 VOLUME ["/data"]
 ```
 Указание путей до инструкций (точки входа)
 ```
 ENTRYPOINT ["/usr/bin/entrypoint"]
CMD ["/bin/s6-svscan", "/etc/s6"]
 ```
 Копирование файлов в контейнер и запуск сервиса
 ```
 COPY docker/root /
COPY --from=build-env /go/src/code.gitea.io/gitea/gitea /app/gitea/gitea
RUN ln -s /app/gitea/gitea /usr/local/bin/gitea
 ```

