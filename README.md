# Pipe Devnet Kurulum Rehberi

Bu rehber, **Pipe Network** Devnet node'unuzu **tek komutla** (otomatik veya interaktif) kurmanızı sağlar. Ayrıca **isteğe bağlı otomatik güncelleme** özelliğini içerir.

---

## Özellikler

- **Tek Komutla Kurulum**: Sunucunuzda sistem güncellemelerini yapar, `pop` binary'sini indirir, systemd servisi yazar ve node'u başlatır.
- **Referral Kodu (Opsiyonel)**: İlk kurulumda referral kodunuzu otomatik ekleyebilirsiniz.
- **Otomatik Güncelleme (Opsiyonel)**: Her gün belirli bir saatte (06:00) otomatik olarak güncelleme kontrolü yapar ve gerekiyorsa yeni sürüme geçer.

---

## Adımlar

### 1. Depoyu Klonlayın veya Script'i RAW Formatında İndirin

En kolay yöntem, `pipe_install.sh` adlı script dosyanızı doğrudan indirmek ve çalıştırmaktır:

```bash
# Aşağıdaki link, scriptin RAW (ham) formatına işaret etmelidir.
wget https://raw.githubusercontent.com/halilunay/Pipe/refs/heads/main/pipe_install.sh

# Çalıştırma izni verelim
chmod +x pipe_install.sh

# Script'i çalıştır
./pipe_install.sh
```

Eğer "Permission denied" gibi bir hata alırsanız, `chmod +x pipe_install.sh` komutunu tekrar kontrol edin.

### 2. Script'in Sorduğu Soruları Cevaplayın

- **Cüzdan adresiniz (pubKey)**: Pipe tarafından size verilen veya kendi oluşturduğunuz public key.
- **RAM Miktarı (GB)**: Node'a ne kadar RAM ayırmak istiyorsanız (en az 4 GB).
- **Disk Miktarı (GB)**: Node'un kullanabileceği maksimum disk alanı (en az 100 GB).
- **Referral Kodu**: Varsayılan olarak `f8e32ffad3f0dcad` şeklinde ayarlanmıştır. Soru geldiğinde [E/h] yanıtı vererek bu kodu kullanabilir veya "Hayır" diyerek atlayabilirsiniz.
- **Pipe Binary (pop) Linki**: Pipe ekibinden e-posta vb. yoluyla size iletilen pop binary linki (mutlaka "https" ile başlamalı). Örnek: `https://dl.pipecdn.app/v0.2.5/pop`

### 3. Kurulum Otomatik Olarak İlerler

Script şunları yapar:

- **Sistem Güncellemeleri**: `sudo apt update && sudo apt upgrade -y`
- **Port İzni**: `sudo ufw allow 8003/tcp`
- **Dizinler Oluşturma**: `$HOME/pipe` ve `$HOME/pipe/download_cache`
- **Eski Servisleri Temizleme**: `popd` adlı bir servis çalışıyorsa durdurur, siler.
- **Binary İndirip Çalıştırma**:
  - İndirdiği dosyayı `pop` ismiyle kaydeder, `chmod +x` verir.
  - Referral kodu kullanmayı seçtiyseniz, script `--signup-by-referral-route` parametresiyle kaydı dener.
- **systemd Servisi Yazma ve Başlatma**: `popd.service` adıyla `/etc/systemd/system/` altında bir servis dosyası oluşturur, daemon'ı yeniler, servisi aktif eder.

### 4. Kurulum Sonrası Kontroller

- **Servis Durumu**:

```bash
sudo systemctl status popd
```

- **Logları Takip Etme**:

```bash
sudo journalctl -u popd -f
```

- **Pop Binary Ek Komutlar**:

```bash
cd $HOME/pipe
./pop --status
./pop --points-route
./pop --gen-referral-route
```

### 5. Otomatik Güncelleme Seçeneği

Script, kurulum bitince size "Otomatik güncelleme cron job'ı kurulsun mu?" diye sorar:

- **Evet** derseniz (E/e/Yes/y), her gün sabah 06:00'da `auto_update_pipe.sh` adında bir script çalışır.
  - Bu script `./pop --refresh` içerisinde "UPDATE AVAILABLE" ifadesini arar.
  - Yeni sürüm bulursa binary'yi indirir, servisi durdurur/günceller, tekrar başlatır.
  - Başarı veya hata mesajlarını `$HOME/pipe/auto_update.log` dosyasına yazar.
- **Hayır** derseniz (H/h/No/n), otomatik güncelleme eklenmez. Dilerseniz güncellemeleri manuel yapabilirsiniz. Örneğin:

```bash
sudo systemctl stop popd
cd $HOME/pipe
wget -O pop "https://dl.pipecdn.app/v0.2.5/pop"
chmod +x pop
sudo systemctl daemon-reload
sudo systemctl start popd
```

### 6. Sıkça Sorulan Sorular (FAQ)

- **Referral Kodunu Sonradan Ekleyebilir miyim?**
  - Ne yazık ki Pipe tarafında aynı IP/node ID için tekrar referral kaydı yapmak mümkün değil. Node ilk kayıtta referral girilmedi ise daha sonra 403 hatası alırsınız. Bu durum Pipe Network backend kısıtlamasından kaynaklanıyor.

- **Port 8003 Açık mı, Nasıl Emin Olurum?**
  - `sudo ufw status` komutu ile ufw açıksa kuralı görebilirsiniz.
  - Dışarıdan port checker (ör. portchecker.co) ile sunucunuzun IP ve 8003'ü sorgulayabilirsiniz.

- **Diğer VPS Güvenlik Duvarı Ayarları**
  - Bazı VPS sağlayıcıları (Hetzner, DigitalOcean vb.) kendi panelinde ek firewall kuralı gerektirir. Panelden 8003 TCP portunu açmanız gerekebilir.

- **Güncellemeler Neden Bu Kadar Sık Geliyor?**
  - Pipe Network Devnet hâlâ aktif geliştirme aşamasında olabilir. Bu nedenle sık güncellemeler doğal bir süreçtir. Otomatik güncelleme bu yükü hafifletir.

---

## Sonuç

Bu rehberdeki adımları izleyerek, Pipe Network Devnet node'unuzu tek komutla kurabilir, isteğe bağlı referral kodu kullanabilir ve otomatik güncellemelerle node'unuzu sürekli güncel tutabilirsiniz.

Sorularınız veya hatalarınız olduğunda:

- `journalctl -u popd -f` logları inceleyin,
- GitHub üzerinden Issue açın ya da topluluk/forum kanallarına göz atın.
