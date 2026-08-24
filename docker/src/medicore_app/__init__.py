import os
from pathlib import Path

from flask import Flask, jsonify


app = Flask(__name__)


def secret_is_available() -> bool:
    """Check that the Docker/Kubernetes secret is mounted and non-empty."""
    secret_path = os.getenv(
        "MEDICORE_DB_PASSWORD_FILE",
        "/run/secrets/db_password",
    )

    try:
        secret_value = Path(secret_path).read_text(
            encoding="utf-8"
        ).strip()
    except (OSError, PermissionError):
        return False

    return bool(secret_value)


@app.get("/")
def index():
    """Return the assignment demonstration page."""
    return (
        """
        <!doctype html>
        <html lang="en">
        <head>
            <meta charset="utf-8">
            <title>MediCore Container Service</title>
        </head>
        <body>
            <h1>MediCore Health Systems</h1>
            <p>A4 Secure Containerised Application</p>
            <p>Status: healthy</p>
        </body>
        </html>
        """,
        200,
        {"Content-Type": "text/html; charset=utf-8"},
    )


@app.get("/health")
def health():
    """Health endpoint used by Docker and Kubernetes."""
    secret_ready = secret_is_available()

    response = {
        "application": "medicore-a4",
        "status": "healthy" if secret_ready else "degraded",
        "secretMounted": secret_ready,
    }

    return jsonify(response), 200 if secret_ready else 503