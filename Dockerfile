FROM python:3.11-slim as whisper

RUN apt-get update && apt-get install -y \
    build-essential cmake curl git ffmpeg sox wget\
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN git clone --depth=1 https://github.com/ggerganov/whisper.cpp.git

WORKDIR /app/whisper.cpp
RUN make

WORKDIR /app
RUN mkdir -p models
RUN wget -O models/ggml-tiny.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin

COPY python/server.py /app/server.py

RUN pip3 install --no-cache-dir flask

EXPOSE 8080
WORKDIR /app
ENTRYPOINT ["python3", "server.py"]

##############################################################################################
FROM php:8.4-rc-cli-alpine3.20 AS local
ENV TZ=UTC
ARG COMPOSER_VERSION=2.8.8
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version=$COMPOSER_VERSION
RUN apk update && apk add git zip vim bash
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin
RUN set -eux; \
    install-php-extensions zip pcntl intl bcmath

ARG UID=1000
ARG USER=developer
RUN adduser -D -u ${UID} ${USER}
USER ${USER}
WORKDIR "/app"

##############################################################################################
FROM python:3.10-slim AS ollama

RUN apt-get update && apt-get install -y \
    bash \
    git \
    espeak \
    build-essential \
    libespeak-ng-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN git clone https://github.com/coqui-ai/TTS.git .
# Install Python + TTS as editable package
RUN pip install --upgrade pip && pip install Flask && pip install -e .

#    && tts --text "Hello" --model_name "tts_models/en/ljspeech/tacotron2-DDC" --out_path /tmp/test.wav

EXPOSE 5002
CMD ["python", "TTS/server/server.py"]

##############################################################################################
FROM python:3.11-slim as nothing

# Zależności systemowe
RUN apt-get update && apt-get install -y \
    build-essential cmake curl git ffmpeg sox \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Skopiuj whisper.cpp
RUN git clone https://github.com/ggerganov/whisper.cpp.git . \
    && make

# Pobierz model tiny
RUN mkdir -p models && \
    curl -L -o models/ggml-tiny.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin

# Flask + waitress
RUN pip install flask==2.2.5 waitress==2.1.2

# Serwer HTTP
RUN curl -L -o server.py https://raw.githubusercontent.com/aarnphm/whisper-cpp-http-server/main/server.py

EXPOSE 8080

CMD ["python", "server.py", "--model", "models/ggml-tiny.bin", "--host", "0.0.0.0", "--port", "8080"]


##############################################################################################
