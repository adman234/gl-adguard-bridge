# GL-AdGuard-Bridge

HTTP proxy server to support Home Assistant integration with AdGuard Home behind GL.iNet routers requiring authentication.

> This is a fork of [shyndman/gl-adguard-bridge](https://github.com/shyndman/gl-adguard-bridge) that adds a GHCR image build, an Unraid Community Applications template, and a couple of fixes (see [CHANGES.md](#changes-in-this-fork) below).

## Security note

This proxy performs **no authentication of its own** — it exists purely to attach GL.iNet router credentials to outgoing requests. Anyone who can reach its port gets fully authenticated access to your AdGuard Home instance. Only expose it on a trusted LAN (e.g. reachable by Home Assistant), never on the WAN, and don't put it on a network segment shared with untrusted devices/guests.

## Purpose

This proxy server sits between Home Assistant and AdGuard Home when the AdGuard Home instance is behind a GL.iNet router that requires authentication. The proxy:

1. Receives requests intended for the AdGuard Home API
2. Authenticates with the GL.iNet router using its API
3. Forwards the requests to the real AdGuard Home with the necessary authentication cookies
4. Returns the responses to Home Assistant
5. Handles reauthentication if needed

## GL.iNet Router Compatibility

This proxy is specifically designed to work with GL.iNet routers using their authentication API as documented here:
https://web.archive.org/web/20240121142533/https://dev.gl-inet.com/router-4.x-api/

The proxy uses the GL.iNet authentication endpoints to obtain a session ID (sid) and adds it as an "Admin-Token" cookie for AdGuard Home requests. The authentication follows the standard GL.iNet API flow:

1. Get challenge parameters from the router
2. Calculate password hash using the provided salt
3. Login with the hash to obtain a session ID
4. Use the session ID as a cookie for subsequent requests

## Configuration

The server is configured using environment variables:

- `ROUTER_HOST`: Hostname or IP address of the GL.iNet router (e.g., 192.168.8.1)
- `ROUTER_USERNAME`: Username for GL.iNet router authentication (defaults to "root")
- `ROUTER_PASSWORD`: Password for GL.iNet router authentication
- `ROUTER_USE_HTTPS`: Whether to connect to the router's RPC endpoint over HTTPS (default: "true"). Set to "false" only if your router's admin API is plain HTTP.
- `ROUTER_SSL_VERIFY`: SSL certificate verification for the router connection, only relevant when `ROUTER_USE_HTTPS` is true. Set to "false" to skip verifying a self-signed certificate, "true" to use system CA certificates, or specify a path to a custom CA bundle file (default: "true")
- `ADGUARD_URL`: URL of the actual AdGuard Home instance
- `LOG_LEVEL`: Logging level (default: INFO)
- `HOST`: Host to bind the server to (default: 0.0.0.0)
- `PORT`: Port to run the server on (default: 8000)

`ROUTER_USE_HTTPS` and `ROUTER_SSL_VERIFY` are separate settings: the former picks the transport (HTTP vs HTTPS), the latter only controls certificate verification when HTTPS is used. Setting `ROUTER_SSL_VERIFY=false` skips cert checks but still uses TLS — it will not silently fall back to plaintext HTTP.

## Running with Docker

```bash
docker run -p 8000:8000 \
  -e ROUTER_HOST=192.168.8.1 \
  -e ROUTER_PASSWORD=password \
  -e ADGUARD_URL=http://adguard.local \
  -e ROUTER_SSL_VERIFY=false \  # Only if your router uses a self-signed certificate
  ghcr.io/adman234/gl-adguard-bridge:latest
```

A `GET /healthz` endpoint is available for container health checks; it only reports whether the bridge process is up and does not touch the router or AdGuard Home.

## Running on Unraid

Pre-built multi-arch images (amd64/arm64) are published automatically to `ghcr.io/adman234/gl-adguard-bridge` on every push to `main` via [GitHub Actions](.github/workflows/docker-publish.yml).

**Option A — manual container add:**

Docker tab → Add Container, then set:

- Repository: `ghcr.io/adman234/gl-adguard-bridge:latest`
- Port: `8000` → `8000`
- Add the environment variables listed above (`ROUTER_HOST`, `ROUTER_PASSWORD`, `ADGUARD_URL` are required)

**Option B — template repo (form-filled fields):**

1. Docker tab → Template Repositories → add `https://github.com/adman234/gl-adguard-bridge`
2. Add Container → the "gl-adguard-bridge" template will appear with all settings as form fields, `ROUTER_PASSWORD` masked

The template XML lives at [unraid-templates/gl-adguard-bridge.xml](unraid-templates/gl-adguard-bridge.xml).

To pick up new image versions, use Unraid's "Check for Updates" on the container (or the Community Applications auto-update feature) since this repo publishes to a `latest` tag on every push to `main`. For pinned/reproducible deploys, use a `vX.Y.Z` tag instead.

## Development

1. Clone the repository
2. Install dependencies with uv: `uv pip install -e ".[dev]"`
3. Run the server: `python -m gl_adguard_bridge`

## Changes in this fork

- Fixed a bug where `ROUTER_SSL_VERIFY=false` silently dropped the router connection to plaintext HTTP instead of skipping certificate verification over HTTPS. Scheme selection is now controlled independently via `ROUTER_USE_HTTPS`.
- Dockerfile now runs as a non-root user and includes a `HEALTHCHECK` against a new `/healthz` endpoint.
- Added a `LICENSE` file.
- Added a GitHub Actions workflow that builds and publishes multi-arch images to GHCR.
- Added an Unraid Community Applications template.

## License

MIT
