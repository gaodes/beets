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
- **originquery**: Augment MusicBrainz queries with locally-sourced data
- **metasync**: Fetch metadata from local or remote sources

### Audio Analysis
- **keyfinder**: Detect musical key of tracks
- **acoustid**: Audio fingerprinting using the Acoustid service
- **bpm**: Tempo (beats per minute) detection
- **replaygain**: Calculate and store ReplayGain values
- **audiofeatures**: Extract audio features for analysis

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
- **describe**: Detailed reporting on library attributes
- **follow**: Check for new albums from favorite artists
- **check**: Verify file integrity

### Integration
- **web**: Web interface for your library
- **plexupdate**: Update Plex libraries when changes occur
- **alternatives**: Manage multiple formats of the same music
- **smartplaylist**: Generate playlists based on queries
- **playlist**: Maintain playlists based on queries
- **hook**: Run commands when events occur
- **playlistensure**: Ensure playlists are properly maintained
- **rewritestyles**: Rewrite style tags

### Conversion and Processing
- **convert**: Convert audio files to other formats
- **inline**: Extract embedded information from filenames
- **fetchattrs**: Fetch additional attributes for tracks
- **xtractor**: Extract musical features from audio
- **autofix**: Automatically fix common issues in your library
- **djtools**: Tools for DJs to organize their music libraries

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

- Monitor for new versions of Beets, Python packages, and Alpine packages
- Create pull requests for dependency updates
- Automatically merge non-breaking updates
- Tag new versions based on dependency changes

The Renovate configuration in `.github/renovate.json5` includes:

- Package rules for Docker, PyPI, and Alpine packages
- Special handling for custom plugins and packages not in PyPI
- Automatic detection of package versions in the Dockerfile
- Semantic commit messages for dependency updates

If you see warnings about package lookup failures for custom plugins (like `beets-*` packages), these are expected as many of these plugins are custom or not available in public repositories.

## Upgrading

Renovate will automatically create pull requests when new versions of dependencies are available. The configuration is set to:

- Update the Python base image (currently `python:3.13-alpine`)
- Update all Alpine packages with their specific versions
- Update PyPI packages that are available in the public repository

When a new version is released:

1. The GitHub Actions workflow will automatically build and push the new image when changes are merged
2. Pull the latest image and restart your container:

```bash
docker-compose pull
docker-compose up -d
```

### Manual Upgrade

If you need to manually upgrade:

```bash
# Rebuild the image
docker-compose build --no-cache

# Restart the container with the new image
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

## Dependency Management

### Package Versioning

All dependencies in the Dockerfile are version-pinned for better stability and reproducibility:

- **Python Base Image**: Currently using `python:3.13-alpine`
- **Alpine Packages**: All Alpine packages are pinned with specific versions (e.g., `ffmpeg=6.0.1-r2`)
- **Python Packages**: All Python packages are pinned with specific versions (e.g., `beets==2.3.0`)

### Custom and Third-Party Plugins

Some plugins used in this image are not available on PyPI, including:
- `keyfinder-cli`: A CLI wrapper for libkeyfinder
- `mpd2`: A Python client for the Music Player Daemon
- Various `beets-*` plugins that are community-maintained

These packages are excluded from Renovate's automatic updates but are still installed from their respective sources.

### Renovate Configuration

Our Renovate setup is configured to:
1. Detect and update Python and Alpine packages in the Dockerfile
2. Ignore packages that aren't available on PyPI
3. Apply specific package rules for different datasources
4. Use regex patterns to identify package versions in various formats

The configuration is in `.github/renovate.json5` and includes detailed package rules and regex managers.

## Resources

- [Beets Documentation](https://beets.readthedocs.io/)
- [Beets GitHub Repository](https://github.com/beetbox/beets)
- [Docker Hub Repository](https://hub.docker.com/r/gaodes/beets)
- [GitHub Container Registry](https://github.com/gaodes/beets/pkgs/container/beets)
- [Renovate Documentation](https://docs.renovatebot.com/)
- [Custom Beets Plugins List](https://beets.readthedocs.io/en/stable/plugins/index.html#other-plugins)

## Contributing

Contributions are welcome! Feel free to open issues or pull requests on GitHub.