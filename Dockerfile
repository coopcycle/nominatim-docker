FROM mdillon/postgis:9.4-alpine

WORKDIR /app

RUN set -ex \
    # && apk update && apk upgrade \
    && apk add --no-cache --virtual .fetch-deps \
        git \
    && apk add --no-cache --virtual .build-deps \
        cmake \
        boost-dev \
        bzip2-dev \
        expat-dev \
        g++ \
        libxml2-dev \
        make \
        # openssl \
        sparsehash \
        zlib-dev \
    # Add libcrypto from (edge:main) for gdal-2.3.0
    && apk add --no-cache --virtual .crypto-rundeps \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
        libressl2.7-libcrypto \
    && apk add --no-cache --virtual .build-deps-testing \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
        gdal-dev \
        geos-dev \
        proj4-dev
        # protobuf-c-dev

# Compile Protozero
RUN git clone https://github.com/mapbox/protozero.git && \
    cd protozero && mkdir build && cd build && \
    cmake .. && make

# Compile LibOsmium
RUN cd /app
RUN git clone https://github.com/osmcode/libosmium.git && \
    cd libosmium && mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DBUILD_EXAMPLES=OFF .. && make

RUN cd /app
ARG NOMINATIM_VERSION=v3.1.0
RUN git clone --recursive https://github.com/openstreetmap/Nominatim ./src
RUN cd ./src && git checkout tags/$NOMINATIM_VERSION && git submodule update --recursive --init && \
    mkdir build && cd build && \
    cmake .. && make

RUN apk del .fetch-deps .build-deps .build-deps-testing
