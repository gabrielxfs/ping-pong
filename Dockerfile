FROM node:20-alpine

WORKDIR /app

COPY wait-for-it.sh /app
COPY init.sh /usr/local/bin
COPY server.js /app
COPY package.json /app

RUN chmod +x /app/wait-for-it.sh ; \
    chmod +x /usr/local/bin/init.sh ; \
    apk upgrade ; \
    apk add --no-cache net-tools bash bash-completion vim curl; \
    npm install

ENV TZ="America/Sao_Paulo" \
    NAME="ping" \
    OPTS="" \
    IN="80" \
    OUT="80" \
    TARGET="pong"

EXPOSE 80

ENTRYPOINT ["init.sh"]
