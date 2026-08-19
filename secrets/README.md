# Runtime secrets

Only `*.example` files belong in Git. On the server, create files without the
`.example` suffix, owned by root with mode `0600`, then point the local ignored
`compose/.env` file at them.

Do not reuse the example values. Do not send real values through chat, commit them,
or pass them on a command line. Rotation is performed by replacing the referenced
file through the authoritative secret workflow and recreating only its consumers.
