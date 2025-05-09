FROM python:3.13-alpine AS builder

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
    fftw-dev \
    python3-dev \
    jpeg-dev \
    zlib-dev \
    libjpeg

# Install Python packages in smaller batches for better error handling
# Core packages
RUN pip install --no-cache-dir --prefix=/install \
    beets==2.3.0 \
    requests \
    pyyaml \
    mutagen \
    unidecode \
    munkres \
    mediafile==0.13.0 \
    reflink \
    jellyfish \
    confuse \
    typing-extensions

# Install metadata plugins
RUN pip install --no-cache-dir --prefix=/install \
    pylast \
    pyacoustid \
    discogs-client \
    musicbrainzngs \
    beautifulsoup4 \
    mpd2 \
    flask \
    plexapi \
    responses \
    xmltodict \
    pyxdg \
    rarfile \
    pillow

# Install Beets plugins
RUN pip install --no-cache-dir --prefix=/install \
    beets-bandcamp \
    beets-beatport \
    beets-extrafiles \
    beets-alternatives \
    beets-albumtypes \
    beets-yearfixer \
    beets-copyartifacts \
    beets-creditflags \
    beets-keyfinder \
    beets-metasync \
    beets-playlistensure \
    beets-rewritestyles \
    beets-fetchattrs \
    beets-describe \
    beets-originquery \
    beets-check

# Try to install more complex packages with potential dependencies
RUN pip install --no-cache-dir --prefix=/install spotipy py-sonic || echo "Warning: Some optional packages couldn't be installed"

# Try to install packages with complex build requirements
RUN pip install --no-cache-dir --prefix=/install bandcamp-api || echo "Warning: bandcamp-api couldn't be installed"
RUN pip install --no-cache-dir --prefix=/install keyfinder-cli || echo "Warning: keyfinder-cli couldn't be installed"
RUN pip install --no-cache-dir --prefix=/install librosa || echo "Warning: librosa couldn't be installed"
RUN pip install --no-cache-dir --prefix=/install beets-audiofeatures || echo "Warning: beets-audiofeatures couldn't be installed"
RUN pip install --no-cache-dir --prefix=/install beets-djtools || echo "Warning: beets-djtools couldn't be installed"
RUN pip install --no-cache-dir --prefix=/install beets-xtractor || echo "Warning: beets-xtractor couldn't be installed"
RUN pip install --no-cache-dir --prefix=/install beets-autofix || echo "Warning: beets-autofix couldn't be installed"
RUN pip install --no-cache-dir --prefix=/install beets-follow || echo "Warning: beets-follow couldn't be installed"

# Try to install essentia (this is a complex package with many dependencies)
RUN pip install --no-cache-dir --prefix=/install essentia || echo "Warning: essentia couldn't be installed - will have reduced functionality"

# Final image
FROM python:3.13-alpine

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

# Install runtime dependencies - basic package groups
RUN apk add --no-cache \
    ffmpeg \
    flac \
    lame \
    opus-tools \
    sqlite \
    su-exec \
    shadow \
    tzdata \
    nano \
    curl \
    jq

# Install audio-related packages
RUN apk add --no-cache \
    chromaprint \
    imagemagick \
    mpd \
    mpc \
    mp3gain \
    sox \
    || echo "Warning: Some audio packages couldn't be installed"

# Install development and library packages
RUN apk add --no-cache \
    py3-pip \
    git \
    fftw \
    taglib \
    boost \
    keyfinder \
    unrar \
    || echo "Warning: Some development packages couldn't be installed"

# Install Python audio package
RUN pip install --no-cache-dir aubio || echo "Warning: aubio couldn't be installed"

# Clean up unnecessary files
RUN find /usr/local \
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