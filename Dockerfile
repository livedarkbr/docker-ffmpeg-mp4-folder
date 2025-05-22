FROM ubuntu:latest

# Labels
LABEL org.opencontainers.image.description="Streaming 432Hz loop video to YouTube"
LABEL org.opencontainers.image.authors="Thiago (livedarkbr)"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt install -y ffmpeg && \
    apt clean

COPY stream_videos.sh /usr/local/bin/stream_videos.sh
RUN chmod +x /usr/local/bin/stream_videos.sh

COPY videos /videos

ENV VIDEO_DIR=/videos

ENTRYPOINT ["/usr/local/bin/stream_videos.sh"]