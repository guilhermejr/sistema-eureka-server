FROM openjdk:11
LABEL maintainer="Guilherme Jr. <falecom@guilhermejr.net>"
ENV TZ=America/Bahia
ARG VAULT_HOST
ARG VAULT_TOKEN
ARG JAR
ENV VAULT_HOST=${VAULT_HOST}
ENV VAULT_TOKEN=${VAULT_TOKEN}
COPY ${JAR} sistema-eureka-server.jar
ENTRYPOINT ["java","-jar","/sistema-eureka-server.jar"]