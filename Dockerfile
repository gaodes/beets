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

# Install essential build dependencies, beets dependencies, and common tools
# You can customize this list based on the plugins you intend to use
RUN apk add --no-cache \
    build-base \
    # For beets core & general plugins
    ffmpeg=4.4.2-r0 \
    flac=1.4.2-r0 \
    lame=3.100-r0 \
    libffi-dev=3.4.4-r0 \
    # For chromaprint/acousticid
    chromaprint=1.5.1-r0 \
    chromaprint-dev=1.5.1-r0 \
    # For image manipulation (e.g., embedart plugin)
    imagemagick=7.1.0-r5 \
    imagemagick-dev=7.1.0-r5 \
    # Common tools
    nano=5.9-r0 \
    sqlite=3.40.1-r0 \
    su-exec=0.2-r1 \
    shadow=4.13-r0 \
    # Add other specific dependencies for your chosen plugins here
    && pip install --no-cache-dir \
    beets==2.3.0 \
    # Add your desired beets plugins here with pinned versions
    pylast==5.5.0 \
    pyacoustid==1.3.0 \
    requests==2.32.3 \
    # For playlist management
    beets-smartplaylist==0.2.0 \
    # For web interface
    flask==3.1.0 \
    # Additional plugins from config files - update versions as needed
    discogs-client==2.7.0 \
    musicbrainzngs==0.7.1 \
    mutagen==1.47.0 \
    beautifulsoup4==4.12.3 \
    && apk del build-base \
    && rm -rf /var/cache/apk/*

# Create necessary directories
RUN mkdir -p /config /data/music/albums /data/music/playlists /data/downloads

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

# Expose the default beets web UI port
EXPOSE 8337

# Set entrypoint and default command
ENTRYPOINT ["/entrypoint.sh"]
CMD ["beet", "version"]

# Define volumes for persistent configuration and library data
VOLUME ["/config", "/data"]