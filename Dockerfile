##############################
# 构建 backend
##############################

FROM ghcr.io/guoyk93/acicn/jdk:builder-8-maven-3.8-debian-11 AS builder-background

WORKDIR /workspace

# install http://syslog4j.org/downloads/syslog4j-0.9.46-bin.jar
RUN curl -sSL -o syslog4j.jar 'http://syslog4j.org/downloads/syslog4j-0.9.46-bin.jar' && \
    mvn install:install-file -Dfile=./syslog4j.jar -DgroupId=org.syslog4j -DartifactId=syslog4j -Dpackaging=jar -Dversion=0.9.46 && \
    rm -f syslog4j.jar

ADD src src

RUN cd src && \
    cd backend && \
    mvn -Pstage -B clean package

##############################
# 构建 backend
##############################

FROM ghcr.io/guoyk93/acicn/jdk:8

ENV DATAEASE_VERSION 1.16.0

RUN apt-get update && \
    apt-get install -y nginx-full && \
    rm -rf /var/lib/apt/lists/*

# 资源文件
ADD src/mapFiles/full   /opt/dataease/data/feature/full
ADD src/drivers         /opt/dataease/drivers

WORKDIR /opt/dataease

COPY --from=builder-background /workspace/src/backend/target/backend-${DATAEASE_VERSION}.jar dataease.jar