FROM mongo:3.2.10

COPY init-mongo-rs.sh /init-mongo-rs.sh
RUN chmod +x /init-mongo-rs.sh
ENTRYPOINT ["/init-mongo-rs.sh"]