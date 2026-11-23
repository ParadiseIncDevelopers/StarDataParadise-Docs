using System.Data;
using StarDataParadise.SDK;

public static class SiparisServisi
{
    public static async Task<decimal> OlusturAsync(
        long siparisId, long musteriId, long urunId, long adet,
        CancellationToken ct = default)
    {
        if (adet <= 0) throw new ArgumentOutOfRangeException(nameof(adet));
        await using var db = new SdpConnection(SdpAyarlar.BaglantiMetni());
        await db.OpenAsync(ct);
        await using var tx = (SdpTransaction)await db.BeginTransactionAsync(
            IsolationLevel.Serializable, ct);
        try
        {
            decimal fiyat;
            await using (var sorgu = db.CreateCommand())
            {
                sorgu.Transaction = tx;
                sorgu.CommandText = "SELECT fiyat FROM urunler WHERE id = :id";
                sorgu.Parameters.Add(new SdpParameter("id", urunId));
                await using var rows = await sorgu.ExecuteReaderAsync(ct);
                if (!await rows.ReadAsync(ct))
                    throw new InvalidOperationException("Ürün bulunamadı");
                fiyat = rows.GetDecimal(0);
            }

            await YazAsync(db, tx,
                "UPDATE urunler SET stok = stok - :adet " +
                "WHERE id = :id AND stok >= :adet", ct,
                new SdpParameter("id", urunId),
                new SdpParameter("adet", adet));

            decimal toplam = checked(fiyat * adet);
            await YazAsync(db, tx,
                "INSERT INTO siparisler (id, musteri_id, durum, toplam) " +
                "VALUES (:id, :musteri, :durum, :toplam)", ct,
                new SdpParameter("id", siparisId),
                new SdpParameter("musteri", musteriId),
                new SdpParameter("durum", "hazirlaniyor"),
                new SdpParameter("toplam", toplam));

            await YazAsync(db, tx,
                "INSERT INTO siparis_kalemleri " +
                "(siparis_id, urun_id, adet, birim_fiyat) " +
                "VALUES (:siparis, :urun, :adet, :fiyat)", ct,
                new SdpParameter("siparis", siparisId),
                new SdpParameter("urun", urunId),
                new SdpParameter("adet", adet),
                new SdpParameter("fiyat", fiyat));

            await tx.CommitAsync(ct);
            return toplam;
        }
        catch (SdpException hata) when (hata.UnknownOutcome)
        {
            // Üst katman RequestToken ve sipariş ID'sini uzlaştırma için saklar.
            throw;
        }
        catch (Exception hata)
        {
            try { await tx.RollbackAsync(CancellationToken.None); }
            catch (Exception ek) { hata.Data["RollbackError"] = ek.Message; }
            throw;
        }
    }

    private static async Task YazAsync(
        SdpConnection db, SdpTransaction tx, string sql,
        CancellationToken ct, params SdpParameter[] parametreler)
    {
        await using var cmd = db.CreateCommand();
        cmd.Transaction = tx;
        cmd.CommandText = sql;
        foreach (var p in parametreler) cmd.Parameters.Add(p);
        if (await cmd.ExecuteNonQueryAsync(ct) != 1)
            throw new InvalidOperationException("Kayıt değişmedi; stok yetersiz olabilir");
    }
}
