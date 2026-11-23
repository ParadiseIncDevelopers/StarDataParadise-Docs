import { OutcomeUnknownError } from 'stardataparadise';
import { openDatabase } from './db.mjs';

export async function stokAyir(urunId, adet) {
  if (typeof urunId !== 'bigint' || urunId <= 0n) {
    throw new TypeError('urunId pozitif BigInt olmalı');
  }
  if (typeof adet !== 'bigint' || adet <= 0n) {
    throw new TypeError('adet pozitif BigInt olmalı');
  }

  const db = await openDatabase();
  try {
    const result = await db.execute(
      `UPDATE public.urunler SET stok = stok - :adet
       WHERE id = :id AND stok >= :adet`,
      { id: urunId, adet },
    );
    const affected = result.affectedRows;
    await result.close();
    if (affected !== 1) {
      await db.rollback();
      return { durum: 'reddedildi', neden: 'Ürün yok veya stok yetersiz' };
    }
    await db.commit();
    return { durum: 'tamamlandi', urunId: urunId.toString(), adet: adet.toString() };
  } catch (error) {
    if (error instanceof OutcomeUnknownError) {
      return {
        durum: 'sonuc_belirsiz',
        requestToken: error.requestToken ?? null,
      };
    }
    throw error;
  } finally {
    await db.close();
  }
}
