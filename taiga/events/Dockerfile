FROM node:alpine

ENV RABBIT_HOST=rabbit \
	RABBIT_PORT=5672 \
	RABBIT_VHOST=taiga \
	RABBIT_USER=taiga \
	RABBIT_PASSWORD=password \
	TAIGA_SECRET=secret

WORKDIR /usr/src/

RUN apk add --no-cache --virtual .build-dependencies git perl \
	&& git clone https://github.com/taigaio/taiga-events.git taiga-events && cd taiga-events \
	&& perl -0777 -pe 's/"devDependencies": \{.*?\},//s' -i package.json \
	&& apk del .build-dependencies \
	&& yarn --production && yarn global add coffeescript

WORKDIR /usr/src/taiga-events

EXPOSE 8888

COPY config.json ./
COPY start.sh /

CMD ["/start.sh"]
