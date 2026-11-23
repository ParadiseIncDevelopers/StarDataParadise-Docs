# db.py — uygulamaya ait yardımcı
import os
from stardataparadise_sdk import connect


def open_database(*, autocommit=False):
    return connect(
        host=os.environ.get("SDP_HOST", "127.0.0.1"),
        port=int(os.environ.get("SDP_PORT", "7443")),
        user=os.environ["SDP_USER"],
        password=os.environ["SDP_PASSWORD"],
        ca_file=os.environ["SDP_CA"],
        tls_name=os.environ.get("SDP_TLS_NAME", "localhost"),
        timeout=15,
        autocommit=autocommit,
    )
