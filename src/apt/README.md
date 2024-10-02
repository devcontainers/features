# Aptfile Dependencies (apt)

Install apt dependencies defined in an `Aptfile.dev` file. This feature is inspired by the approach found in [heroku-buildpack-apt](https://github.com/heroku/heroku-buildpack-apt) and [Aptfile Buildpack on App Platform](https://docs.digitalocean.com/products/app-platform/reference/buildpacks/aptfile/). It simplifies the process of managing and installing apt packages required for a development environment by specifying them in one file.

## Example Usage

```json
"features": {
  "ghcr.io/viktorianer/features/apt:1": {
    "devFile": "../Aptfile.dev"
  }
}
```

## Options

| Options Id | Description | Type   | Default Value |
|------------|-------------|--------|---------------|
| devFile    | Path to the Aptfile.dev file. This is where the list of apt packages is defined. | string | `../Aptfile.dev` |

## How It Works

- The feature reads the list of packages from the `Aptfile.dev` file and installs them during the container setup.
- The default path is `Aptfile.dev`, but this can be customized using the `devFile` option.
- It removes any commented or empty lines before installing the packages with `apt-get install`.

Example `Aptfile.dev`:

```bash
# Video thumbnails
ffmpeg
libvips

# PDF thumbnails
poppler-utils
# mupdf
# mupdf-tools

# PostgreSQL
libpq-dev
postgresql-client
```
