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

COPY python/whisper/server.py /app/server.py

RUN pip3 install --no-cache-dir flask

EXPOSE 8080
WORKDIR /app
ENTRYPOINT ["python3", "server.py"]

##############################################################################################
FROM python:3.11-slim AS coqui

RUN apt-get update && apt-get install -y \
    git ffmpeg espeak-ng libespeak-ng1 libsndfile1  gcc g++ make python3-dev libsndfile1-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN git clone https://github.com/coqui-ai/TTS.git /app/TTS && \
    pip install --upgrade pip && \
    pip install --no-cache-dir -r /app/TTS/requirements.txt && \
    pip install --no-cache-dir /app/TTS

COPY python/coqui/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY python/coqui/server.py .

CMD ["python", "server.py"]

##############################################################################################
# FROM python:3.10-slim AS ollama

# RUN apt-get update && apt-get install -y \
#     bash \
#     git \
#     espeak \
#     build-essential \
#     libespeak-ng-dev \
#  && rm -rf /var/lib/apt/lists/*

# WORKDIR /app
# RUN git clone https://github.com/coqui-ai/TTS.git .
# # Install Python + TTS as editable package
# RUN pip install --upgrade pip && pip install Flask && pip install -e .

# #    && tts --text "Hello" --model_name "tts_models/en/ljspeech/tacotron2-DDC" --out_path /tmp/test.wav

# EXPOSE 5002
# CMD ["python", "TTS/server/server.py"]


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
