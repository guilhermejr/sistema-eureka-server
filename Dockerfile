FROM amazoncorretto:21
LABEL maintainer="Guilherme Jr. <falecom@guilhermejr.net>"
ENV TZ=America/Bahia
ARG VAULT_HOST
ARG VAULT_TOKEN
ENV VAULT_HOST=${VAULT_HOST}
ENV VAULT_TOKEN=${VAULT_TOKEN}
COPY sistema-eureka-server.jar sistema-eureka-server.jar
HEALTHCHECK --interval=30s --timeout=5s --start-period=90s --retries=3 \
  CMD curl -fsS http://localhost:8761/actuator/health | grep -q '"status":"UP"' || exit 1

ENTRYPOINT ["java","-Dspring.profiles.active=prod","-jar","/sistema-eureka-server.jar"]
EXPOSE 8761