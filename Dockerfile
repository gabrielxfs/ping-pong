FROM alpine:3.18

WORKDIR /setup

COPY wait-for-it.sh /setup
COPY init.sh /usr/local/bin

RUN chmod +x /setup/wait-for-it.sh ; \
    chmod +x /usr/local/bin/init.sh ; \
    apk upgrade ; \
    apk add --no-cache net-tools bash bash-completion vim curl;

ENV TZ="America/Sao_Paulo" \
    NAME="ping" \
    OPTS="" \
    TARGET="pong"

EXPOSE 80

ENTRYPOINT ["init.sh"]
