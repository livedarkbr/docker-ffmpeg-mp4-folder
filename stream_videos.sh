#!/bin/bash

echo "📺 Iniciando streaming do vídeo loop.mp4 para o YouTube..."

VIDEO="/videos/loop.mp4"

if [ ! -f "$VIDEO" ]; then
    echo "❌ Arquivo de vídeo não encontrado em $VIDEO"
    exit 1
fi

if [ -z "$YOUTUBE_STREAM_KEY" ]; then
    echo "❌ Variável YOUTUBE_STREAM_KEY não definida"
    exit 1
fi

while true; do
  ffmpeg -re -stream_loop -1 -i "$VIDEO" \
    -c:v libx264 -preset veryfast -tune zerolatency \
    -maxrate 3000k -bufsize 6000k -g 50 -r 30 \
    -c:a aac -b:a 128k -ar 44100 -ac 2 \
    -f flv "rtmp://a.rtmp.youtube.com/live2/$YOUTUBE_STREAM_KEY"

  echo "⚠️ ffmpeg finalizou. Reiniciando em 5 segundos..."
  sleep 5
done
