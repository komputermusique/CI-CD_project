# Описание Dockerfile для GoCD (Сервер):
Использование дистрибутива alpine и установка зависимостей 
```
FROM alpine:latest as gocd-server-unzip
ARG UID=1000
RUN \
  apk --no-cache upgrade && \
  apk add --no-cache curl && \
  curl --fail --location --silent --show-error "https://download.gocd.org/binaries/20.8.0-12213/generic/go-server-20.8.$RUN unzip /tmp/go-server-20.8.0-12213.zip -d /
RUN mkdir -p /go-server/wrapper /go-server/bin && \
    mv /go-server-20.8.0/LICENSE /go-server/LICENSE && \
    mv /go-server-20.8.0/bin/go-server /go-server/bin/go-server && \
    mv /go-server-20.8.0/lib /go-server/lib && \
    mv /go-server-20.8.0/logs /go-server/logs && \
    mv /go-server-20.8.0/run /go-server/run && \
    mv /go-server-20.8.0/wrapper-config /go-server/wrapper-config && \
    mv /go-server-20.8.0/wrapper/wrapper-linux* /go-server/wrapper/ && \
    mv /go-server-20.8.0/wrapper/libwrapper-linux* /go-server/wrapper/ && \
    mv /go-server-20.8.0/wrapper/wrapper.jar /go-server/wrapper/ && \
    chown -R ${UID}:0 /go-server && chmod -R g=u /go-server
```
Описание метаданных
```
LABEL gocd.version="20.8.0" \
  description="GoCD server based on alpine version 3.11" \
  maintainer="ThoughtWorks, Inc. <support@thoughtworks.com>" \
  url="https://www.gocd.org" \
  gocd.full.version="20.8.0-12213" \
  gocd.git.sha="1e23a06e496205ced5f1a8e83d9b209fc0a290cb"
```
Открытие 8153 порта
```
EXPOSE 8153
```
Добавление файлов в контейнер 
```
ADD https://github.com/krallin/tini/releases/download/v0.18.0/tini-static-amd64 /usr/local/sbin/tini 
```
Установка кодировок и домашнего пути Java
```
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8
ENV GO_JAVA_HOME="/gocd-jre"
```
Далее выполняются следующие действия: 
Добавление режима и разрешения для файлов, которые были добавлены выше
```
RUN \
  chmod 0755 /usr/local/sbin/tini && \
  chown root:root /usr/local/sbin/tini && \
``` 

Сначала происходит добавление нашего пользователя и группу, чтобы убедиться, что их идентификаторы назначаются последовательно,независимо от того, какие зависимости добавляются, пользователь добавляется в корневую группу, чтобы gocd работал с openshift.
```
  adduser -D -u ${UID} -s /bin/bash -G root go && \                                                                       apk add --no-cache cyrus-sasl cyrus-sasl-plain && \
  apk --no-cache upgrade && \
  apk add --no-cache nss git mercurial subversion openssh-client bash curl procps && \
```
 Установка зависимостей и создание точки вхождения для Docker.
  ```
   apk add --no-cache --virtual .build-deps binutils && \
    GLIBC_VER="2.29-r0" && \
    ALPINE_GLIBC_REPO="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    GCC_LIBS_URL="https://archive.archlinux.org/packages/g/gcc-libs/gcc-libs-9.1.0-2-x86_64.pkg.tar.xz" && \
    GCC_LIBS_SHA256=91dba90f3c20d32fcf7f1dbe91523653018aa0b8d2230b00f822f6722804cf08 && \
    ZLIB_URL="https://archive.archlinux.org/packages/z/zlib/zlib-1%3A1.2.11-3-x86_64.pkg.tar.xz" && \
    ZLIB_SHA256=17aede0b9f8baa789c5aa3f358fbf8c68a5f1228c5e6cba1a5dd34102ef4d4e5 && \
    curl -LfsS https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub && \
    SGERRAND_RSA_SHA256="823b54589c93b02497f1ba4dc622eaef9c813e6b0f0ebbb2f771e32adf9f4ef2" && \
    echo "${SGERRAND_RSA_SHA256} */etc/apk/keys/sgerrand.rsa.pub" | sha256sum -c - && \
    curl -LfsS ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-${GLIBC_VER}.apk > /tmp/glibc-${GLIBC_VER}.apk && \
    apk add /tmp/glibc-${GLIBC_VER}.apk && \
    curl -LfsS ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-bin-${GLIBC_VER}.apk > /tmp/glibc-bin-${GLIBC_VER}.apk && \
    apk add /tmp/glibc-bin-${GLIBC_VER}.apk && \
    curl -Ls ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-i18n-${GLIBC_VER}.apk > /tmp/glibc-i18n-${GLIBC_VER}.apk && \
    apk add /tmp/glibc-i18n-${GLIBC_VER}.apk && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true && \
    echo "export LANG=$LANG" > /etc/profile.d/locale.sh && \
    curl -LfsS ${GCC_LIBS_URL} -o /tmp/gcc-libs.tar.xz && \
    echo "${GCC_LIBS_SHA256} */tmp/gcc-libs.tar.xz" | sha256sum -c - && \
    mkdir /tmp/gcc && \                                                                                                     tar -xf /tmp/gcc-libs.tar.xz -C /tmp/gcc && \
    mv /tmp/gcc/usr/lib/libgcc* /tmp/gcc/usr/lib/libstdc++* /usr/glibc-compat/lib && \
    strip /usr/glibc-compat/lib/libgcc_s.so.* /usr/glibc-compat/lib/libstdc++.so* && \
    curl -LfsS ${ZLIB_URL} -o /tmp/libz.tar.xz && \
    echo "${ZLIB_SHA256} */tmp/libz.tar.xz" | sha256sum -c - && \                                                           mkdir /tmp/libz && \
    tar -xf /tmp/libz.tar.xz -C /tmp/libz && \
    mv /tmp/libz/usr/lib/libz.so* /usr/glibc-compat/lib && \
    apk del --purge .build-deps glibc-i18n && \
    rm -rf /tmp/*.apk /tmp/gcc /tmp/gcc-libs.tar.xz /tmp/libz /tmp/libz.tar.xz /var/cache/apk/* && \
   curl --fail --location --silent --show-error 'https://github.com/AdoptOpenJDK/openjdk14-binaries/releases/download/jd$  mkdir -p /gocd-jre && \
   tar -xf /tmp/jre.tar.gz -C /gocd-jre --strip 1 && \
   rm -rf /tmp/jre.tar.gz && \
   mkdir -p /go-server /docker-entrypoint.d /go-working-dir /godata
```
Добавление точки вхождения в контейнер
```
ADD docker-entrypoint.sh /
```
Копирование файлов в контейнер
```
COPY --from=gocd-server-unzip /go-server /go-server
```
Проверка log-файлов на вывод на консоль
```
COPY --chown=go:root logback-include.xml /go-server/config/logback-include.xml
COPY --chown=go:root install-gocd-plugins git-clone-config /usr/local/sbin/
```
Предоставление доступа для go-пользователя
```
RUN chown -R go:root /docker-entrypoint.d /go-working-dir /godata /docker-entrypoint.sh \
    && chmod -R g=u /docker-entrypoint.d /go-working-dir /godata /docker-entrypoint.sh                                  
```
Указание точки вхождения
```
ENTRYPOINT ["/docker-entrypoint.sh"]
```
Выполнение действий от имени пользователя go
```
USER go
```
# Описание Dockerfile для GoCD-agent:
Скачивание архива с агентом и перемещение распакованных файлов в рабочий каталог
```
RUN \
  apk --no-cache upgrade && \
  apk add --no-cache curl && \
  curl --fail --location --silent --show-error "https://download.gocd.org/binaries/20.8.0-12213/generic/go-agent-20.8.0$
RUN unzip /tmp/go-agent-20.8.0-12213.zip -d /
RUN mv /go-agent-20.8.0 /go-agent && chown -R ${UID}:0 /go-agent && chmod -R g=u /go-agent
```
Описание метаданных
```
LABEL gocd.version="20.8.0" \
  description="GoCD agent based on debian version 9" \
  maintainer="ThoughtWorks, Inc. <support@thoughtworks.com>" \
  url="https://www.gocd.org" \
  gocd.full.version="20.8.0-12213" \
  gocd.git.sha="1e23a06e496205ced5f1a8e83d9b209fc0a290cb" 
```

Добавление файлов в контейнер 
```
ADD https://github.com/krallin/tini/releases/download/v0.18.0/tini-static-amd64 /usr/local/sbin/tini
```
Установка кодировок и домашнего пути Java
```
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8
ENV GO_JAVA_HOME="/gocd-jre"
```
Присвоение идентификаторов пользователя и групп в стандартных значениях
```
ARG UID=1000
ARG GID=1000
```
Добавление режима и разрешения для файлов, которые были добавлены выше
```
RUN \
  chmod 0755 /usr/local/sbin/tini && \
  chown root:root /usr/local/sbin/tini && \       
 ```
Сначала происходит добавление нашего пользователя и группу, чтобы убедиться, что их идентификаторы назначаются последовательно,независимо от того, какие зависимости добавляются, пользователь добавляется в корневую группу, чтобы gocd работал с openshift.
```
  useradd -u ${UID} -g root -d /home/go -m go && \
  apt-get update && \
  apt-get install -y git subversion mercurial openssh-client bash unzip curl locales procps sysvinit-utils coreutils &&$  apt-get autoclean && \
  echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen && /usr/sbin/locale-gen && \
  curl --fail --location --silent --show-error 'https://github.com/AdoptOpenJDK/openjdk14-binaries/releases/download/jd$  mkdir -p /gocd-jre && \
  tar -xf /tmp/jre.tar.gz -C /gocd-jre --strip 1 && \
  rm -rf /tmp/jre.tar.gz && \
  mkdir -p /go-agent /docker-entrypoint.d /go /godata
```
Добавление входной точки в контейнер
```
ADD docker-entrypoint.sh /
```
Копирование файлов в контейнер
```
COPY --from=gocd-agent-unzip /go-agent /go-agent
```
Проверка файлов на вывод в консоль
```
COPY --chown=go:root agent-bootstrapper-logback-include.xml agent-launcher-logback-include.xml agent-logback-include.xm$
```
Предоставление доступа для go-пользователя
```
RUN chown -R go:root /docker-entrypoint.d /go-working-dir /godata /docker-entrypoint.sh \
    && chmod -R g=u /docker-entrypoint.d /go-working-dir /godata /docker-entrypoint.sh                                  
```
Указание точки вхождения
```
ENTRYPOINT ["/docker-entrypoint.sh"]
```
Выполнение действий от имени пользователя go
```
USER go
```                                                           












