# stok_servisi.py
from stardataparadise_sdk import OutcomeUnknown
from db import open_database


def stok_ayir(urun_id: int, adet: int) -> dict:
    if type(urun_id) is not int or urun_id <= 0:
        raise ValueError("urun_id pozitif int olmalı")
    if type(adet) is not int or adet <= 0:
        raise ValueError("adet pozitif int olmalı")

    db = open_database()
    try:
        with db.cursor() as cursor:
            cursor.execute(
                """UPDATE public.urunler SET stok = stok - :adet
                   WHERE id = :id AND stok >= :adet""",
                {"id": urun_id, "adet": adet},
            )
            affected = cursor.rowcount
        if affected != 1:
            db.rollback()
            return {"durum": "reddedildi", "neden": "Ürün yok veya stok yetersiz"}
        db.commit()
        return {"durum": "tamamlandi", "urun_id": urun_id, "adet": adet}
    except OutcomeUnknown as error:
        return {
            "durum": "sonuc_belirsiz",
            "request_token": error.request_token,
        }
    finally:
        db.close()
