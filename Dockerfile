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
# 构建 frontend
##############################

FROM ghcr.io/guoyk93/acicn/node:builder-16-debian-11 AS builder-frontend

WORKDIR /workspace

# 取消使用国内 registry，因为我要白嫖 Github Workflows
RUN npm config delete registry && rm -rf /root/.pip

ADD src src

RUN cd src/frontend && \
    npm install && \
    npm run build:stage


##############################
# 构建 mobile
##############################

FROM ghcr.io/guoyk93/acicn/node:builder-16-debian-11 AS builder-mobile

WORKDIR /workspace

# 取消使用国内 registry，因为我要白嫖 Github Workflows
RUN npm config delete registry && rm -rf /root/.pip

ADD src src

RUN cd src/mobile && \
    npm install && \
    npm run build:stage

##############################
# 组装最终镜像
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

# 构建产物
COPY --from=builder-background /workspace/src/backend/target/backend-${DATAEASE_VERSION}.jar /opt/dataease/dataease.jar
COPY --from=builder-frontend   /workspace/src/frontend/dist                                  /opt/dataease/frontend/dist
COPY --from=builder-mobile     /workspace/src/mobile/dist                                    /opt/dataease/mobile/dist
RUN mv /opt/dataease/mobile/dist/index.html /opt/dataease/mobile/dist/app.html

# nginx 配置 和 minit 启动单元
ADD etc /etc