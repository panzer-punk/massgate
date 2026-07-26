FROM ubuntu:24.04 AS linux-builder

# Do not use --no-install-recommends for wine: the wine64 package alone
# does not ship /usr/bin/wine64 (it comes from the recommended wine package).
RUN apt-get update && apt-get install -y \
      git \
      cmake \
      ninja-build \
      wine64 \
      python3 \
      msitools \
      ca-certificates \
      winbind \
      procps \
      unzip \
      curl \
   && rm -rf /var/lib/apt/lists/*

# Windows MySQL Connector/C (libmysql) for MSVC cross-link.
# Massgate uses MSVC __asm (x86-only), so target Win32 / connector win32.
ARG MYSQL_CONNECTOR_URL=https://cdn.mysql.com/archives/mysql-connector-c/mysql-connector-c-6.1.11-win32.zip
RUN curl -fsSL -o /tmp/mysql-connector.zip "${MYSQL_CONNECTOR_URL}" \
 && unzip -q /tmp/mysql-connector.zip -d /opt \
 && mv /opt/mysql-connector-c-*-win32 /opt/mysql \
 && rm /tmp/mysql-connector.zip
ENV MYSQL_HOME=/opt/mysql

# Initialize the wine prefix before installing/using MSVC wrappers.
RUN wine wineboot --init \
 && while pgrep wineserver > /dev/null; do sleep 1; done

RUN git clone --depth 1 https://github.com/mstorsjo/msvc-wine.git /opt/msvc-wine \
 && cd /opt/msvc-wine \
 && ./vsdownload.py --accept-license --dest /opt/msvc \
 && ./install.sh /opt/msvc

COPY ./3rdparty /app/3rdparty
COPY ./cmake /app/cmake
COPY ./CMakeLists.txt /app/CMakeLists.txt
COPY ./src /app/src

WORKDIR /app

# x86: project uses inline __asm in MC_Math.h (unsupported on x64 MSVC).
RUN wineserver -p \
 && wine wineboot \
 && mkdir -p build && cd build \
 && export PATH=/opt/msvc/bin/x86:$PATH \
 && CC=cl CXX=cl cmake .. -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_SYSTEM_NAME=Windows \
      -DCMAKE_SYSTEM_PROCESSOR=x86 \
      -DMYSQL_INCLUDE_DIR=/opt/mysql/include \
      -DMYSQL_LIBRARY=/opt/mysql/lib/libmysql.lib \
 && cmake --build .

FROM ubuntu:24.04 AS linux-runner

RUN dpkg --add-architecture i386 \
   && apt-get update && apt-get install -y \
      wine32:i386 \
   && wine wineboot --init \
   && while pgrep wineserver > /dev/null; do sleep 1; done

COPY --from=linux-builder /app/build/bin/MMassgateServers.exe /app/Massgate.exe
COPY --from=linux-builder /opt/mysql/lib/libmysql.dll /app/libmysql.dll
COPY ./config.ini /app/config.ini

WORKDIR /app

CMD ["wine", "/app/Massgate.exe", "live", "-noboom", "-all", "-dbname", "live", "-massgateport", "3001", "-logsql"]
