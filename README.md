# openssl-gui

## OpenSSL'i Windows'ta cmd'den kullanilabilir yapmak

1. `install-openssl.bat` ve `install-openssl.ps1` dosyalarini ayni klasore indirin.
2. `install-openssl.bat` dosyasina cift tiklayin, yonetici izni sorulunca **Evet** deyin.
3. Betik sunlari yapar:
   - `winget` ile OpenSSL'i (Win64 Light) indirip kurar (zaten kuruluysa atlar),
   - `...\OpenSSL-Win64\bin` klasorunu sistem `PATH`'ine ekler,
   - `OPENSSL_CONF` ortam degiskenini ayarlar.
4. **Yeni** bir cmd penceresi acin ve deneyin:

   ```cmd
   openssl version
   ```

`winget` yoksa Microsoft Store'dan "App Installer" uygulamasini kurun ya da OpenSSL'i
https://slproweb.com/products/Win32OpenSSL.html adresinden elle kurup betigi tekrar calistirin
(betik kurulu OpenSSL'i bulup yalnizca PATH ayarini yapar).
