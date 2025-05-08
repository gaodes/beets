# Beets Docker Setup

A lightweight Docker container setup for [Beets](https://beets.io/), the music library manager and tagger.

## Features

- Multi-stage Docker build for smaller image size
- Automatic version detection and tagging
- Comprehensive configuration with common plugins
- Resource-limited containers to prevent overuse
- Health checks for better container management
- Support for PUID/PGID for proper file permissions (NAS/Unraid friendly)

## Quick Start

### Run with Docker Compose

```bash
# Start the container
docker-compose up -d

# Check the logs
docker-compose logs -f
```

### Configuration

Edit the configuration files in the `config/` directory:

- `config.yaml`: Main beets configuration
- `albums.yaml`: Album-specific configurations (optional)
- `playlists.yaml`: Playlist definitions (optional)

## Directory Structure

- `/config`: Configuration files and database
- `/data/media/music/albums`: Your music library
- `/data/media/music/playlists`: Generated playlists
- `/data/downloads`: Place new music here for importing
  - `/data/downloads/tidal`: Music downloaded from Tidal
  - `/data/downloads/deezer`: Music downloaded from Deezer
  - `/data/downloads/youtube`: Music downloaded from YouTube
  - `/data/downloads/spotify`: Music downloaded from Spotify

## Common Commands

```bash
# Import music from all download sources
docker-compose exec beets beet import /data/downloads

# Import music from a specific source
docker-compose exec beets beet import /data/downloads/tidal
docker-compose exec beets beet import /data/downloads/deezer
docker-compose exec beets beet import /data/downloads/youtube
docker-compose exec beets beet import /data/downloads/spotify

# Update music library metadata
docker-compose exec beets beet update

# List all albums
docker-compose exec beets beet ls -a

# Generate smart playlists
docker-compose exec beets beet splupdate

# Start web interface (if not already running)
docker-compose exec beets beet web
```

## Upgrading

When a new Beets version is released:

1. Update the version in the Dockerfile
2. Rebuild the image

```bash
docker-compose build --no-cache
docker-compose up -d
```

## Advanced Usage

### Custom Plugins

To add custom plugins:

1. Create a plugins directory: `mkdir -p config/plugins`
2. Add your plugin files to this directory
3. Update `config.yaml` to include the plugin name

### Extending the Image

You can create a custom Dockerfile based on this image:

```dockerfile
FROM ghcr.io/gaodes/beets:latest

# Add custom dependencies
RUN apk add --no-cache \
    additional-package

# Install additional Python packages
RUN pip install --no-cache-dir \
    additional-package
```

## Resources

- [Beets Documentation](https://beets.readthedocs.io/)
- [Docker Hub Repository](https://hub.docker.com/r/gaodes/beets)
- [GitHub Repository](https://github.com/gaodes/beets)