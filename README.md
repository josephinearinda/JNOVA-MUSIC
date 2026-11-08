# JNOVAMUSIC

## Katalog produk aplikasi

Katalog utama dibaca dari `Katalog/Katalog_AlatMusik.csv` saat aplikasi
dimulai. Foto produk dicocokkan dengan nama produk di folder
`GAMBAR KATALOG/<kategori>/`. CSV memakai pemisah titik koma dan kolom
`kategori`, `merk`, `nama`, `jenis`, `deskripsi`, dan `harga`. Stok aplikasi
sementara menggunakan nilai default 5 karena CSV belum memuat kolom stok.
Rating dan jumlah ulasan tidak ditampilkan sebagai nilai buatan karena CSV
belum memuat informasi tersebut.
Saat pembaruan aplikasi pertama kali dibuka, cache katalog lama diperbarui
dari CSV; item keranjang/favorit yang cocok berdasarkan merek dan nama tetap
dipertahankan.

## Menyiapkan Jnova AI tanpa API key di aplikasi

Jnova AI mengirim permintaan Gemini melalui Supabase Edge Function. Pengguna
tidak perlu memasukkan atau memiliki Gemini API key. Jangan masukkan
`GEMINI_API_KEY` ke `.env` Flutter, source code, atau build aplikasi.

### Konfigurasi satu kali oleh pemilik project

1. Buat/pilih project Supabase dan isi `SUPABASE_URL` serta
   `SUPABASE_ANON_KEY` di file `.env` lokal aplikasi. Kedua nilai tersebut
   tersedia di Supabase Project Settings → API.
2. Buat Gemini API key pada [Google AI Studio](https://aistudio.google.com/apikey).
   Pilih project/key bertanda **Free tier** jika tersedia; penggunaan tetap
   tunduk pada kuota gratis Google.
3. Simpan key di Supabase Dashboard → Project Settings → Edge Functions →
   Secrets dengan nama `GEMINI_API_KEY`. Jangan commit atau membagikan secret.
4. Pasang Supabase CLI, login, lalu dari folder project jalankan:

   ```powershell
   supabase link --project-ref <PROJECT_REF>
   supabase db push
   supabase functions deploy gemini-chat
   ```

   `PROJECT_REF` dapat dilihat pada URL project Supabase.
5. Edge Function dapat dipakai pengguna aplikasi tanpa login Supabase Auth.
   Fungsi membatasi 20 permintaan per alamat IP per jam dan 500 permintaan total
   per hari untuk membantu melindungi kuota Gemini gratis. Setiap pesan hanya
   membuat satu permintaan ke Gemini dan tidak dicoba ulang otomatis, agar
   gangguan jaringan tidak menggandakan pemakaian kuota. Fungsi membatasi
   waktu menunggu Gemini hingga 25 detik; aplikasi menunggu hingga 45 detik
   sebelum menampilkan pesan timeout. Kuota gratis Google tetap dapat
   membatasi jumlah chat.

Model server ditetapkan ke Gemini 3.5 Flash-Lite (`gemini-3.5-flash-lite`),
model berbiaya rendah dan berlatensi rendah. Riwayat yang dikirim dibatasi
hingga empat giliran terakhir. Jika key, kuota model, atau wilayah Google tidak
tersedia, pemilik project perlu memeriksa kuota/akses di Google AI Studio.
Batas dan ketersediaan model ditentukan Google dan dapat berubah.
