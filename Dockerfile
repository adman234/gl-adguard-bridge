FROM python:3.13-slim-bookworm
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Copy the project into the image
ADD . /app

# Sync the project into a new environment, using the frozen lockfile
WORKDIR /app
RUN uv sync --frozen

# Run as a non-root user
RUN groupadd --system app \
    && useradd --system --gid app --no-create-home --home-dir /app app \
    && chown -R app:app /app
USER app

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD python -c "import os,urllib.request as u; u.urlopen('http://127.0.0.1:' + os.environ.get('PORT','8000') + '/healthz', timeout=2)" || exit 1

CMD ["uv", "run", "-m", "gl_adguard_bridge"]
