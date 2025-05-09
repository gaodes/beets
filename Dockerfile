FROM python:3.13-alpine AS builder

# Setup pip cache for faster builds
ENV PIP_CACHE_DIR=/var/cache/pip
RUN mkdir -p $PIP_CACHE_DIR

# Install build dependencies
RUN apk add --no-cache \
    build-base=0.5.3-r5 \
    libffi-dev=3.4.4-r2 \
    chromaprint-dev=1.5.1-r3 \
    imagemagick-dev=7.1.1.21-r0 \
    py3-pip=23.3.1-r0 \
    git=2.40.1-r0 \
    cmake=3.27.8-r0 \
    taglib-dev=1.13.1-r1 \
    boost-dev=1.82.0-r4 \
    fftw-dev=3.3.10-r2

# Install Python packages
# NOTE: The beets version line below is the source of truth and is updated by Renovate
RUN pip install --no-cache-dir --prefix=/install \
    beets==2.3.0 \
    # Core plugins
    pylast==5.5.0 \
    pyacoustid==1.3.0 \
    # Enhanced metadata
    discogs-client==2.7.0 \
    musicbrainzngs==0.7.1 \
    bandcamp-api==0.6.0 \
    # Audio analysis
    keyfinder-cli==1.2.2 \
    librosa==0.11.0 \
    # Integration
    flask==3.1.0 \
    plexapi==4.17.0 \
    # General dependencies
    requests==2.32.3 \
    mutagen==1.47.0 \
    beautifulsoup4==4.13.4 \
    confuse==2.0.1 \
    reflink==0.2.2 \
    mpd2==3.1.0 \
    rarfile==4.2 \
    jellyfish==1.2.0 \
    pillow==10.4.0 \
    pyxdg==0.28 \
    pyyaml==6.0.2 \
    typing-extensions==4.13.2 \
    responses==0.25.7 \
    xmltodict==0.14.2 \
    mediafile==0.13.0 \
    unidecode==1.4.0 \
    munkres==1.1.4 \
    # Additional plugin dependencies
    beets-bandcamp==0.1.4 \
    beets-beatport==0.1.1 \
    beets-extrafiles==0.0.7 \
    beets-alternatives==0.13.2 \
    beets-albumtypes==0.1.5 \
    beets-yearfixer==0.0.5 \
    beets-copyartifacts==0.1.3 \
    # Additional requested plugins
    beets-creditflags==0.0.1 \
    beets-keyfinder==0.4.0 \
    beets-metasync==0.1.0 \
    beets-playlistensure==0.1.0 \
    beets-rewritestyles==0.1.0 \
    beets-fetchattrs==0.1.1 \
    beets-describe==0.0.5 \
    beets-audiofeatures==0.3.1 \
    beets-djtools==0.1.1 \
    beets-xtractor==0.5.0 \
    # Recommended additional plugins
    beets-autofix==0.1.6 \
    beets-follow==0.1.2 \
    beets-originquery==0.1.1 \
    beets-check==0.15.0 \
    # Supporting libraries
    spotipy==2.25.1 \
    py-sonic==1.0.3 \
    essentia==2.1b6.dev1234

# Final image
FROM python:3.13-alpine

# Create user and group
RUN addgroup -g 100 -S appgroup && \
    adduser -u 99 -S appuser -G appgroup -s /bin/sh

# Set environment variables
ENV BEETSDIR="/config" \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PUID=99 \
    PGID=100 \
    TZ=UTC

# Install runtime dependencies with version pinning
RUN apk add --no-cache \
    ffmpeg=6.0.1-r2 \
    flac=1.4.3-r0 \
    lame=3.100-r5 \
    opus-tools=0.2.1-r1 \
    chromaprint=1.5.1-r3 \
    imagemagick=7.1.1.21-r0 \
    nano=7.2-r1 \
    sqlite=3.43.2-r0 \
    su-exec=0.2-r3 \
    shadow=4.13.2-r0 \
    tzdata=2023d-r0 \
    mpd=0.23.13-r3 \
    mpc=0.34-r1 \
    unrar=6.2.12-r0 \
    mp3gain=1.6.2-r2 \
    py3-pip=23.3.1-r0 \
    git=2.40.1-r0 \
    fftw=3.3.10-r2 \
    taglib=1.13.1-r1 \
    boost=1.82.0-r4 \
    sox=14.4.2-r10 \
    keyfinder=2.2.6-r2 \
    curl=8.4.0-r0 \
    jq=1.7.1-r0 \
    && pip install --no-cache-dir aubio==0.4.9 \
    # Clean up unnecessary files
    && find /usr/local \
        \( -type d -a -name test -o -name tests -o -name '__pycache__' \) \
        -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
        -exec rm -rf '{}' + || true

# Copy Python packages from builder stage
COPY --from=builder /install /usr/local

# Extract Beets version and set as build argument
ARG BEETS_VERSION
RUN BEETS_VERSION=$(pip show beets | grep "^Version:" | cut -d " " -f 2) && \
    echo "Beets version: ${BEETS_VERSION}" && \
    echo "${BEETS_VERSION}" > /tmp/beets_version

# Set labels for the image with improved metadata
LABEL maintainer="gaodes" \
      org.opencontainers.image.source="https://github.com/gaodes/beets" \
      org.opencontainers.image.description="Feature-rich Docker image for beets music organizer with comprehensive plugin support" \
      org.opencontainers.image.version="$(cat /tmp/beets_version)" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.created="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
      org.opencontainers.image.title="Beets Music Organizer" \
      org.opencontainers.image.vendor="gaodes" \
      org.opencontainers.image.base.name="python:3.13-alpine"

# Create only the base directories
RUN mkdir -p /config /data

# Set the working directory
WORKDIR /config

# Create integrated entrypoint script
RUN echo '#!/bin/sh\n\
set -e\n\
\n\
# Create user with specified PUID/PGID if needed\n\
if [ ! "$(id -u appuser 2>/dev/null || echo no)" = "$PUID" ]; then\n\
    # User appuser exists but with wrong PUID, modify it\n\
    if getent passwd appuser > /dev/null; then\n\
        usermod -o -u "$PUID" appuser\n\
    else\n\
        # Create the user if it does not exist\n\
        adduser -D -u "$PUID" -s /bin/sh appuser\n\
    fi\n\
    # Set PGID\n\
    if [ ! "$(id -g appuser)" -eq "$PGID" ]; then\n\
        groupmod -o -g "$PGID" appuser\n\
    fi\n\
fi\n\
\n\
# Make sure the user can access the config and data directories\n\
chown -R appuser:appgroup /config\n\
chown appuser:appgroup /data\n\
\n\
# Run the command as the appuser user\n\
exec su-exec appuser "$@"' > /entrypoint.sh && \
    chmod +x /entrypoint.sh

# Add healthcheck with improved parameters
HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
  CMD beet version || exit 1

# Expose the default beets web UI port
EXPOSE 8337

# Set entrypoint and default command
ENTRYPOINT ["/entrypoint.sh"]
CMD ["beet", "web"]

# Define volumes for persistent configuration and library data
VOLUME ["/config", "/data"]

# Run most operations as appuser instead of root
# USER appuser