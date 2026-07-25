FROM alpine:3.18 AS builder

COPY ./src /app

RUN apk add --no-cache \
    build-base \
    cmake \
    git \
    make \
    ninja \
    openssl-dev \
    zlib-dev \ 
    mingw-w32-gcc


WORKDIR /app
RUN cmake -B build -G "Ninja Multi-Config" -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=./cmake/Toolchain-x86_64-w64-mingw32.cmake
RUN cmake --build build --config Release

FROM mcr.microsoft.com/windows/server:ltsc2025 AS server

COPY --from=builder /app/build/Release/Massgate.exe /app/Massgate.exe

CMD ["/app/Massgate.exe"]
