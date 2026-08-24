# Local Docker Secrets

This directory is used for local runtime secrets.

Actual secret values must never be committed to Git.

The local file used by Docker Compose is:

`db_password.txt`

It is excluded through the repository `.gitignore`.

The container receives this secret as a mounted file under:

`/run/secrets/db_password`

The password itself is not supplied through an environment variable.