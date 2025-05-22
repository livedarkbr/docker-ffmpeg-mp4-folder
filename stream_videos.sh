#!/bin/bash

# Caminho fixo da pasta onde está seu vídeo no repositório
VIDEO_DIR="/app/videos"

# Stream videos to multiple platforms using ffmpeg and the tee muxer
stream_videos() {
    echo "Starting the streaming process..."

    # Use variáveis de ambiente para as chaves
    local TWITCH_STREAM_KEY="${TWITCH_STREAM_KEY}"
    local YOUTUBE_API_KEY="${YOUTUBE_API_KEY}"
    local KICK_STREAM_URL="${KICK_STREAM_URL}"  # Kick stream URL
    local KICK_STREAM_KEY="${KICK_STREAM_KEY}"  # Kick stream key

    echo "Video directory: ${VIDEO_DIR}"
    echo "Twitch Stream Key: ${TWITCH_STREAM_KEY}"
    echo "YouTube API Key: ${YOUTUBE_API_KEY}"
    echo "Kick Stream URL: ${KICK_STREAM_URL}"
    echo "Kick Stream Key: ${KICK_STREAM_KEY}"

    # Loop through all MP4/MKV files in the video directory
    find "${VIDEO_DIR}" -type f \( -name '*.mp4' -or -name '*.mkv' \) | while read -r file; do
        echo "Preparing to stream file: $file"

        # Comando base do ffmpeg
        local FFMPEG_CMD="ffmpeg -re -nostdin -i \"$file\" -map 0 -flags +global_header -c:v libx264 -c:a aac -preset ultrafast -minrate 3000k -maxrate 3000k -bufsize 3000k -g 30 -b:a 128k -ar 44100 -vf \"scale=1920:1080\" -r 30"

        # Inicializa comando tee e lista de destinos
        local TEE_CMD="-f tee"
        local STREAMS=()

        # Twitch
        if [ -n "${TWITCH_STREAM_KEY}" ]; then
            echo "Configurando transmissão para Twitch"
            STREAMS+=("[f=flv:onfail=ignore]rtmp://live-lax.twitch.tv/app/${TWITCH_STREAM_KEY}")
        fi

        # YouTube
        if [ -n "${YOUTUBE_API_KEY}" ]; then
            echo "Configurando transmissão para YouTube"
            STREAMS+=("[f=flv:onfail=ignore]rtmp://a.rtmp.youtube.com/live2/${YOUTUBE_API_KEY}")
        fi

        # Kick
        if [ -n "${KICK_STREAM_URL}" ] && [ -n "${KICK_STREAM_KEY}" ]; then
            echo "Configurando transmissão para Kick"
            STREAMS+=("[f=flv:onfail=ignore]${KICK_STREAM_URL}:443/app/${KICK_STREAM_KEY}")
        fi

        # Junta todos os destinos
        local TEE_TARGETS=$(IFS='|'; echo "${STREAMS[*]}")

        # Monta o comando final
        if [ -n "${TEE_TARGETS}" ]; then
            FFMPEG_CMD+=" ${TEE_CMD} \"${TEE_TARGETS}\""
            echo "Comando final do ffmpeg: ${FFMPEG_CMD}"
            echo "Iniciando transmissão do vídeo $file..."
            eval "${FFMPEG_CMD} &"
        else
            echo "Nenhum destino configurado. Pulando $file."
        fi

        # Espera terminar para continuar
        wait
    done
}

# Verifica se existem vídeos antes de rodar
if find "${VIDEO_DIR}" -type f \( -name '*.mp4' -or -name '*.mkv' \) -print -quit | grep -q .; then
    echo "Vídeos encontrados. Iniciando streaming..."
    LOOP_INDEFINITELY="${LOOP_INDEFINITELY:-false}"

    if [ "${LOOP_INDEFINITELY}" = "true" ]; then
        while true; do
            stream_videos
            echo "Reiniciando o processo de streaming..."
        done
    else
        stream_videos
    fi
else
    echo "Nenhum vídeo encontrado em ${VIDEO_DIR}. Encerrando..."
    exit 1
fi
