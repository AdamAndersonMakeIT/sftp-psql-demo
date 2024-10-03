
FROM postgres:16

COPY entrypoint.sh /entrypoint.sh

CMD [ "/entrypoint.sh" ]

ENV HEALTHCHECK_RUN_FILE=/tmp/running

HEALTHCHECK --interval=90s CMD '[' -f "$HEALTHCHECK_RUN_FILE" ] && rm "$HEALTHCHECK_RUN_FILE" || exit 1
