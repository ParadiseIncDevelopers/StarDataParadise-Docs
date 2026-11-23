# ilk_sorgu.py
import os
from stardataparadise_sdk import connect

with connect(
    host="127.0.0.1",
    port=7443,
    user=os.environ["SDP_USER"],
    password=os.environ["SDP_PASSWORD"],
    ca_file=os.environ["SDP_CA"],
    tls_name="localhost",
    autocommit=True,
) as db:
    print("Server:", db.server_version)
    with db.cursor() as cursor:
        cursor.execute(
            "SELECT id, ad, stok FROM public.urunler WHERE id >= :ilk ORDER BY id",
            {"ilk": 101},
        )
        for urun_id, ad, stok in cursor:
            print(urun_id, ad, stok)
