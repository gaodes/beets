# Beets Docker Setup

A feature-rich Docker container setup for [Beets](https://beets.io/), the music library manager and tagger, with comprehensive plugin support.

## Features

- Multi-stage Docker build for optimized image size
- Automatic version detection and tagging
- Comprehensive configuration with 40+ plugins
- Resource-limited containers to prevent overuse
- Health checks for better container management
- Support for PUID/PGID for proper file permissions (NAS/Unraid friendly)
- Automatic updates via Renovate integration
- Extensive plugin collection for advanced music library management
- Multi-source metadata lookup (MusicBrainz, Discogs, Bandcamp, etc.)
- Audio analysis tools (BPM detection, key finding, ReplayGain)
- Integration with Plex and other media servers

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

## Included Plugins

This Docker image includes a comprehensive set of Beets plugins:

### Core Organization
- **fetchart**: Download album art images and attach them to your albums
- **embedart**: Embed album art images into file metadata
- **lastgenre**: Fetch genres from Last.fm
- **chroma**: Audio fingerprinting for accurate identification
- **types**: Custom field types for your music library
- **importadded**: Preserve file modification times during import

### Enhanced Metadata
- **acousticbrainz**: Fetch acoustic information from AcousticBrainz
- **lyrics**: Automatically fetch song lyrics
- **discogs**: Use Discogs as a metadata source
- **albumtypes**: Consistent album type classification
- **bandcamp**: Use Bandcamp as a metadata source
- **beatport**: Use Beatport as a metadata source
- **creditflags**: Credit handling for performers

### Audio Analysis
- **keyfinder**: Detect musical key of tracks
- **acoustid**: Audio fingerprinting using the Acoustid service
- **bpm**: Tempo (beats per minute) detection
- **replaygain**: Calculate and store ReplayGain values

### Library Management
- **duplicates**: Find and manage duplicate tracks
- **missing**: List missing tracks from albums
- **zero**: Cleans fields from music files
- **edit**: Edit metadata from a text editor
- **info**: Show file metadata
- **scrub**: Clean extraneous metadata from files
- **fromfilename**: Generate metadata from filenames
- **filefilter**: Filter files during import
- **extrafiles**: Manage non-music files

### Integration
- **web**: Web interface for your library
- **plexupdate**: Update Plex libraries when changes occur
- **alternatives**: Manage multiple formats of the same music
- **smartplaylist**: Generate playlists based on queries
- **playlist**: Maintain playlists based on queries
- **hook**: Run commands when events occur

### Conversion and Processing
- **convert**: Convert audio files to other formats
- **inline**: Extract embedded information from filenames

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

## Plugin Configuration

Each plugin has been pre-configured in the `config.yaml` file with sensible defaults. Here are some key configurations you might want to customize:

### Discogs Authentication
```yaml
discogs:
  user_token: YOUR_DISCOGS_TOKEN
```

### Plex Integration
```yaml
plexupdate:
  library_name: Music
  server: http://plex:32400
  token: YOUR_PLEX_TOKEN
```

### Last.fm Genre Configuration
```yaml
lastgenre:
  whitelist: /config/genres.txt  # Create this file with your preferred genres
```

## Automatic Updates

This project uses Renovate for automatic dependency updates. The Renovate configuration will:

- Monitor for new versions of Beets and its dependencies
- Create pull requests for dependency updates
- Automatically merge non-breaking updates
- Tag new versions based on dependency changes

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

## Contributing

Contributions are welcome! Feel free to open issues or pull requests on GitHub.