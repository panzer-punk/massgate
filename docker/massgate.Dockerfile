FROM debian:bookworm-slim AS linux-builder

ARG MYSQL_CONNECTOR_URL=https://cdn.mysql.com/archives/mysql-connector-c/mysql-connector-c-6.1.11-win32.zip
ARG MYSQL_HOME=/opt/mysql

RUN dpkg --add-architecture i386 \
   && apt-get update && apt-get install -y --no-install-recommends \
      git \
      cmake \
      ninja-build \
      wine \
      wine64 \
      wine32:i386 \
      python3 \
      msitools \
      ca-certificates \
      winbind \
      procps \
      unzip \
      curl \
   # Windows MySQL Connector/C (libmysql) for MSVC cross-link.
   # Massgate uses MSVC __asm (x86-only), so target Win32 / connector win32.
   && curl -fsSL -o /tmp/mysql-connector.zip "${MYSQL_CONNECTOR_URL}" \
   && unzip -q /tmp/mysql-connector.zip -d /opt \
   && mv /opt/mysql-connector-c-*-win32 "${MYSQL_HOME}" \
   && rm /tmp/mysql-connector.zip \
   # Initialize the wine prefix before installing/using MSVC wrappers.
   && wine wineboot --init \
   && git clone --depth 1 https://github.com/mstorsjo/msvc-wine.git /opt/msvc-wine \
   && cd /opt/msvc-wine \
   && ./vsdownload.py \
      --accept-license \
      --architecture x86 \
      --skip-recommended \
      --dest /opt/msvc \
   && ./install.sh /opt/msvc \
   && apt-get clean  \
   && rm -rf /var/lib/apt/lists/* \
   && rm -rf /tmp/* \
   && rm -rf /opt/msvc-wine

COPY ./3rdparty /app/3rdparty
COPY ./cmake /app/cmake
COPY ./CMakeLists.txt /app/CMakeLists.txt
COPY ./src /app/src

WORKDIR /app

# x86: project uses inline __asm in MC_Math.h (unsupported on x64 MSVC).
# Embedded debug info avoids mspdbsrv.exe, which hangs CMake under Wine (/Zi + /FS).
RUN wineserver -p \
   && wine wineboot \
   && mkdir -p build && cd build \
   && export PATH=/opt/msvc/bin/x86:$PATH \
   && export WINEDEBUG=-all \
   && CC=cl CXX=cl cmake .. -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_SYSTEM_NAME=Windows \
      -DCMAKE_SYSTEM_PROCESSOR=x86 \
      -DCMAKE_POLICY_DEFAULT_CMP0141=NEW \
      -DCMAKE_MSVC_DEBUG_INFORMATION_FORMAT=Embedded \
      -DCMAKE_EXE_LINKER_FLAGS=/MANIFEST:NO \
      -DCMAKE_SHARED_LINKER_FLAGS=/MANIFEST:NO \
      -DMYSQL_INCLUDE_DIR=/opt/mysql/include \
      -DMYSQL_LIBRARY=/opt/mysql/lib/libmysql.lib \
   && cmake --build .

FROM debian:bookworm-slim AS linux-runner

ENV WINEPREFIX=/app/.wine \
    WINEARCH=win32 \
    WINEDEBUG=-all

RUN dpkg --add-architecture i386 \
   && apt-get update && apt-get install -y --no-install-recommends \
      wine32:i386 \
      gettext-base \
   && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*

COPY --from=linux-builder /opt/mysql/lib/libmysql.dll /app/libmysql.dll
COPY --chmod=755 ./docker/massgate/run.sh /app/run.sh
COPY --from=linux-builder /app/build/bin/MMassgateServers.exe /app/Massgate.exe
COPY --chmod=644 ./docker/massgate/config.ini.template /app/config.ini.template

WORKDIR /app

CMD ["/app/run.sh"]
