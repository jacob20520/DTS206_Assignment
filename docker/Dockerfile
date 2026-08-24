# ============================================================
# Stage 1 - Builder
#
# Dependencies and the MediCore application are built into
# Python wheel packages.
# ============================================================

FROM python:3.11-slim AS builder

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /build

COPY pyproject.toml ./
COPY src ./src

# Build the MediCore application and all runtime dependencies
# into wheels. The production stage therefore receives only
# built package artefacts rather than application source.
RUN python -m pip install \
        --no-cache-dir \
        --upgrade \
        pip \
        setuptools \
        wheel \
    && python -m pip wheel \
        --no-cache-dir \
        --wheel-dir /wheels \
        .


# ============================================================
# Stage 2 - Production
#
# Assignment requirement:
# - python:3.11-slim
# - non-root appuser
# - UID 1001
# - built output only from Stage 1
# ============================================================

FROM python:3.11-slim AS production

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    MEDICORE_DB_PASSWORD_FILE=/run/secrets/db_password

# Create the assessed non-root account.
RUN groupadd \
        --gid 1001 \
        appuser \
    && useradd \
        --uid 1001 \
        --gid 1001 \
        --no-create-home \
        --shell /usr/sbin/nologin \
        appuser

# Only built wheel artefacts cross the build-stage boundary.
COPY --from=builder /wheels /wheels

# Install entirely from builder-generated wheels.
# No application source tree is copied into this image.
RUN python -m pip install \
        --no-cache-dir \
        --no-index \
        --find-links=/wheels \
        medicore-a4-app==1.0.0 \
    && rm -rf /wheels

WORKDIR /app

# Assignment requirement: run as non-root UID 1001.
USER appuser

EXPOSE 8080

# Uses Python's standard library so curl/wget do not need to
# be installed in the production image.
HEALTHCHECK \
    --interval=30s \
    --timeout=3s \
    --start-period=10s \
    --retries=3 \
    CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/health', timeout=2).read()"]

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "--threads", "2", "--timeout", "30", "--worker-tmp-dir", "/tmp", "medicore_app:app"]