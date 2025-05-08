FROM python:3.11-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    libffi-dev \
    chromaprint-dev \
    imagemagick-dev \
    py3-pip \
    git \
    cmake \
    taglib-dev \
    boost-dev \
    fftw-dev

# Install Python packages
RUN pip install --no-cache-dir --prefix=/install \
    beets==2.3.0 \
    # Core plugins
    pylast==5.5.0 \
    pyacoustid==1.3.0 \
    python-acoustid==1.3.0 \
    # Enhanced metadata
    discogs-client==2.7.0 \
    musicbrainzngs==0.7.1 \
    bandcamp-api==0.6.0 \
    # Audio analysis
    keyfinder-cli==1.2.2 \
    librosa==0.10.1 \
    # Integration
    flask==3.1.0 \
    plexapi==4.15.4 \
    plex-api==4.2.0 \
    # General dependencies
    requests==2.32.3 \
    mutagen==1.47.0 \
    beautifulsoup4==4.12.3 \
    confuse==2.0.1 \
    reflink==0.2.1 \
    mpd2==3.1.0 \
    rarfile==4.1 \
    jellyfish==1.0.1 \
    pillow==10.2.0 \
    pyxdg==0.28 \
    pyyaml==6.0.1 \
    typing-extensions==4.8.0 \
    responses==0.24.1 \
    xmltodict==0.13.0 \
    mediafile==0.12.0 \
    unidecode==1.3.7 \
    munkres==1.1.4 \
    # Additional plugin dependencies
    beets-bandcamp==0.1.4 \
    beets-beatport==0.1.1 \
    beets-extrafiles==0.0.7 \
    beets-alternatives==0.10.1 \
    beets-smartplaylist==0.2.0 \
    beets-albumtypes==0.1.5 \
    beets-yearfixer==0.0.5 \
    beets-copyartifacts==0.1.3

# Final image
FROM python:3.11-alpine

# Set labels for the image
LABEL maintainer="gaodes"
LABEL org.opencontainers.image.source="https://github.com/gaodes/beets"
LABEL org.opencontainers.image.description="Lightweight Docker image for beets music organizer"

# Set environment variables
ENV BEETSDIR="/config" \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PUID=99 \
    PGID=100 \
    TZ=UTC

# Install runtime dependencies
RUN apk add --no-cache \
    ffmpeg \
    flac \
    lame \
    opus-tools \
    chromaprint \
    imagemagick \
    nano \
    sqlite \
    su-exec \
    shadow \
    tzdata \
    mpd \
    mpc \
    unrar \
    mp3gain \
    py3-pip \
    git \
    fftw \
    taglib \
    boost \
    sox \
    keyfinder \
    curl \
    jq \
    && pip install --no-cache-dir aubio

# Copy Python packages from builder stage
COPY --from=builder /install /usr/local

# Create only the base directories
RUN mkdir -p /config /data

# Set the working directory
WORKDIR /config

# Create integrated entrypoint script
RUN echo '#!/bin/sh\n\
set -e\n\
\n\
# Create user with specified PUID/PGID if needed\n\
if [ ! "$(id -u nobody 2>/dev/null || echo no)" = "$PUID" ]; then\n\
    # User nobody exists but with wrong PUID, modify it\n\
    if getent passwd nobody > /dev/null; then\n\
        usermod -o -u "$PUID" nobody\n\
    else\n\
        # Create the user if it does not exist\n\
        adduser -D -u "$PUID" -s /bin/sh nobody\n\
    fi\n\
    # Set PGID\n\
    if [ ! "$(id -g nobody)" -eq "$PGID" ]; then\n\
        groupmod -o -g "$PGID" nobody\n\
    fi\n\
fi\n\
\n\
# Make sure the user can access the config and data directories\n\
chown -R nobody:nobody /config\n\
chown nobody:nobody /data\n\
\n\
# Run the command as the nobody user\n\
exec su-exec nobody "$@"' > /entrypoint.sh && \
    chmod +x /entrypoint.sh

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD beet version || exit 1

# Expose the default beets web UI port
EXPOSE 8337

# Set entrypoint and default command
ENTRYPOINT ["/entrypoint.sh"]
CMD ["beet", "version"]

# Define volumes for persistent configuration and library data
VOLUME ["/config", "/data"]