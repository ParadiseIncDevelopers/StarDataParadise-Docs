import { connect } from 'stardataparadise';

const db = await connect({
  host: '127.0.0.1',
  port: 7443,
  tlsName: 'localhost',
  caFile: process.env.SDP_CA,
  user: process.env.SDP_USER,
  password: process.env.SDP_PASSWORD,
  autocommit: true,
});

try {
  console.log('Server:', db.serverVersion);
  const result = await db.execute(
    'SELECT id, ad, stok FROM public.urunler WHERE id >= :ilk ORDER BY id',
    { ilk: 1n },
  );
  try {
    for await (const [id, ad, stok] of result) {
      console.log(id.toString(), ad, stok.toString());
    }
  } finally {
    await result.close();
  }
} finally {
  await db.close();
}
