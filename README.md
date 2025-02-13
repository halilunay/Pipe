# Pipe Devnet Kurulum Rehberi

Bu rehber, **Pipe Network** Devnet node’unuzu **tek komutla** (otomatik veya interaktif) kurmanızı sağlar. Ayrıca **isteğe bağlı otomatik güncelleme** özelliğini içerir.

---

## Özellikler

- **Tek Komutla Kurulum**: Sunucunuzda sistem güncellemelerini yapar, `pop` binary’sini indirir, systemd servisi yazar ve node’u başlatır.  
- **Referral Kodu (Opsiyonel)**: İlk kurulumda referral kodunuzu otomatik ekleyebilirsiniz.  
- **Otomatik Güncelleme (Opsiyonel)**: Her gün belirli bir saatte (06:00) otomatik olarak güncelleme kontrolü yapar ve gerekiyorsa yeni sürüme geçer.

---

## Adımlar

### 1. Depoyu Klonlayın veya Script’i RAW Formatında İndirin

En kolay yöntem, `pipe_install.sh` adlı script dosyanızı doğrudan indirmek ve çalıştırmaktır:

```bash
# Aşağıdaki link, scriptin RAW (ham) formatına işaret etmelidir.
wget https://raw.githubusercontent.com/halilunay/Pipe/refs/heads/main/pipe_install.sh

# Çalıştırma izni verelim
chmod +x pipe_install.sh

# Script'i çalıştır
./pipe_install.sh
