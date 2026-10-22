# JNOVAMUSIC

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
   per hari untuk membantu melindungi kuota Gemini gratis. Gangguan sementara
   dari Gemini dicoba ulang otomatis; kuota gratis Google tetap dapat
   membatasi jumlah chat dan masa tunggunya.

Model server ditetapkan ke `gemini-3.8-flash`. Jika key Free tier, kuota model,
atau wilayah Google tidak tersedia, pemilik project perlu memeriksa kuota/
akses di Google AI Studio. Batas gratis dan ketersediaan model ditentukan
Google dan dapat berubah.
