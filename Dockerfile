FROM ghcr.io/guoyk93/acicn/jdk:builder-8-maven-3.8-debian-11 AS builder-background

WORKDIR /workspace

ADD src src

RUN cd src && \
    mvn clean package -Pstage -B

FROM ghcr.io/guoyk93/acicn/jdk:8

ENV DATAEASE_VERSION 1.16.1

RUN apt-get update && \
    apt-get install -y nginx-full && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/dataease

COPY --from=builder-background /workspace/src/target/backend-${DATAEASE_VERSION}}.jar dataease.jar