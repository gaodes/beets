FROM python:3.12-alpine AS builder

# Setup pip cache for faster builds
ENV PIP_CACHE_DIR=/var/cache/pip
RUN mkdir -p $PIP_CACHE_DIR

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
# NOTE: The beets version line below is the source of truth and is updated by Renovate
RUN pip install --no-cache-dir --prefix=/install \
    beets==2.3.0 \
    # Core plugins
    pylast \
    pyacoustid \
    # Enhanced metadata
    discogs-client \
    musicbrainzngs \
    bandcamp-api \
    # Audio analysis
    keyfinder-cli \
    librosa \
    # Integration
    flask \
    plexapi \
    # General dependencies
    requests \
    mutagen \
    beautifulsoup4 \
    confuse \
    reflink \
    mpd2 \
    rarfile \
    jellyfish \
    pillow \
    pyxdg \
    pyyaml \
    typing-extensions \
    responses \
    xmltodict \
    mediafile \
    unidecode \
    munkres \
    # Additional plugin dependencies
    beets-bandcamp \
    beets-beatport \
    beets-extrafiles \
    beets-alternatives \
    beets-albumtypes \
    beets-yearfixer \
    beets-copyartifacts \
    # Additional requested plugins
    beets-creditflags \
    beets-keyfinder \
    beets-metasync \
    beets-playlistensure \
    beets-rewritestyles \
    beets-fetchattrs \
    beets-describe \
    beets-audiofeatures \
    beets-djtools \
    beets-xtractor \
    # Recommended additional plugins
    beets-autofix \
    beets-follow \
    beets-originquery \
    beets-check \
    # Supporting libraries
    spotipy \
    py-sonic \
    essentia

# Final image
FROM python:3.12-alpine

# Create user and group - using dynamic IDs to avoid conflicts
RUN addgroup -S appgroup && \
    adduser -S appuser -G appgroup -s /bin/sh

# Set environment variables
ENV BEETSDIR="/config" \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PUID=99 \
    PGID=100 \
    TZ=UTC

# Install runtime dependencies with version pinning
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
    && pip install --no-cache-dir aubio \
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
      org.opencontainers.image.base.name="python:3.12-alpine"

# Create only the base directories
RUN mkdir -p /config /data

# Set the working directory
WORKDIR /config

# Create integrated entrypoint script
RUN echo '#!/bin/sh\n\
set -e\n\
\n\
# Get the current IDs for appuser\n\
CURRENT_UID=$(id -u appuser)\n\
CURRENT_GID=$(id -g appuser)\n\
\n\
# Update user/group IDs if needed\n\
if [ ! "$CURRENT_UID" = "$PUID" ]; then\n\
    usermod -o -u "$PUID" appuser\n\
fi\n\
\n\
if [ ! "$CURRENT_GID" = "$PGID" ]; then\n\
    groupmod -o -g "$PGID" appgroup\n\
fi\n\
\n\
# Make sure the user can access the directories\n\
chown -R appuser:appgroup /config\n\
chown appuser:appgroup /data\n\
\n\
# Run the command as the appuser\n\
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