#!/bin/bash
#
# Pipe Devnet Node Setup Script (systemd) + Otomatik Güncelleme Opsiyonu
# Referral Kodlu Kurulum
#

echo "-------------------------------------------------"
echo "  Pipe Devnet Node Kurulumu"
echo "  Bu script ile, referral kodunu kullanarak"
echo "  kaydolmak istiyorsanız sorulacak."
echo "  Ardından, otomatik güncelleme için cron job"
echo "  ekleme seçeneği sunulacak."
echo "-------------------------------------------------"
sleep 1

# 1. Giriş Değerlerini Alalım
echo -n "Cüzdan Adresiniz (pubKey): "
read -r PUBKEY

echo -n "Kaç GB RAM ayırmak istiyorsunuz? (en az 4): "
read -r RAM
if [ "$RAM" -lt 4 ]; then
  echo "Hata: RAM en az 4 GB olmalı!"
  exit 1
fi

echo -n "Maksimum disk alanı (GB olarak, en az 100): "
read -r DISK
if [ "$DISK" -lt 100 ]; then
  echo "Hata: Disk alanı en az 100 GB olmalı!"
  exit 1
fi

# Varsayılan referral kodunuzu buraya yazın
DEFAULT_REF="f8e32ffad3f0dcad"
echo -n "Referral kodu kullanmak ister misiniz? (default: $DEFAULT_REF) [E/h]: "
read -r REF_CHOICE
if [[ "$REF_CHOICE" =~ ^(H|h|Hayir|no|n)$ ]]; then
  REF_CODE=""
else
  REF_CODE="$DEFAULT_REF"
fi

echo "Lütfen, Pipe tarafından e-posta ile gönderilen v2 binary (pop) linkini girin (https ile başlamalı):"
read -r BINARY_URL
if [[ $BINARY_URL != https* ]]; then
    echo "Hata: Link 'https' ile başlamalı!"
    exit 1
fi

echo "------------------------------------"
echo "Kurulum başlıyor..."
sleep 1

# 2. Sistem Güncellemesi ve Port Açma
sudo apt update && sudo apt upgrade -y
sudo ufw allow 8003/tcp

# 3. Dizin Oluşturma
mkdir -p "$HOME/pipe"
mkdir -p "$HOME/pipe/download_cache"

# 4. Eski Servisleri Durdur ve Temizle (Varsa)
echo "Daha önce çalışan popd varsa durduruluyor..."
sudo systemctl stop popd 2>/dev/null
sudo systemctl disable popd 2>/dev/null

echo "8003 portunu kullanan süreçleri kapatıyoruz..."
PID=$(lsof -ti :8003)
if [ -n "$PID" ]; then
  kill -9 "$PID"
fi

# 5. Binary İndir
cd "$HOME/pipe" || exit
echo "POP binary indiriliyor..."
wget -q -O pop "$BINARY_URL"
chmod +x pop

# 6. Referral ile Kayıt Olma (isteğe bağlı)
#    Node zaten kayıtlı ise 403 hatası gelebilir.
if [ -n "$REF_CODE" ]; then
  echo "Referral kaydı deneniyor... Kod: $REF_CODE"
  OUT=$(./pop --signup-by-referral-route "$REF_CODE" 2>&1)
  echo "Çıktı: $OUT"
  if echo "$OUT" | grep -q "403 Forbidden"; then
    echo "Uyarı: Node zaten kayıt olmuş veya IP kullanılıyor. Referral kaydı başarısız oldu."
  else
    echo "Referral kaydı denemesi tamamlandı."
  fi
fi

# 7. systemd Service Dosyası
SERVICE_FILE="/etc/systemd/system/popd.service"
echo "systemd servis dosyası oluşturuluyor: $SERVICE_FILE"

sudo bash -c "cat <<EOF > $SERVICE_FILE
[Unit]
Description=Pipe POP Node Service
After=network.target
Wants=network-online.target

[Service]
User=$USER
ExecStart=$HOME/pipe/pop \\
    --ram=$RAM \\
    --pubKey=$PUBKEY \\
    --max-disk=$DISK \\
    --cache-dir=$HOME/pipe/download_cache
Restart=always
RestartSec=5
LimitNOFILE=65536
LimitNPROC=4096
StandardOutput=journal
StandardError=journal
SyslogIdentifier=dcdn-node
WorkingDirectory=$HOME/pipe

[Install]
WantedBy=multi-user.target
EOF"

# 8. Servisi Başlatma
sudo systemctl daemon-reload
sudo systemctl enable popd
sudo systemctl start popd

# 9. Kontrol
echo "------------------------------------"
echo "Kurulum tamamlandı! Servis çalışıyor."
echo "Durum görmek için:  sudo systemctl status popd"
echo "Logları izlemek için: sudo journalctl -u popd -f"
echo "------------------------------------"
echo "Ek komutlar (cd \$HOME/pipe):"
echo "  ./pop --status"
echo "  ./pop --points-route"
echo "  ./pop --gen-referral-route"
echo "------------------------------------"

# 10. Otomatik Güncelleme Opsiyonu
echo ""
echo "Sık güncellemeler geldiği için otomatik güncelleme ekleyebilirsiniz."
echo "Bu, her sabah 06:00'da script çalıştırıp güncelleme var mı diye bakacak."
echo -n "Otomatik güncelleme cron job'ı kurulsun mu? [E/h]: "
read -r AUTO_UPDATE_CHOICE

if [[ "$AUTO_UPDATE_CHOICE" =~ ^(E|e|Evet|evet|Yes|yes|Y|y)$ ]]; then
  
  # 10.a) auto_update_pipe.sh dosyasını oluştur
  cat << 'EOF' > "$HOME/pipe/auto_update_pipe.sh"
#!/bin/bash
#
# Pipe Node Auto Update Script
# Bu script, 'pop --refresh' çıktısında "UPDATE AVAILABLE" ifadesini yakalar.
# Varsa, yeni sürüm binary'sini indirip servisi günceller.

cd "$HOME/pipe" || exit 1
echo "Running auto-update check..."

REFRESH_OUTPUT=$(./pop --refresh 2>&1)

if echo "$REFRESH_OUTPUT" | grep -q "UPDATE AVAILABLE"; then
    echo "[INFO] Yeni sürüm bulundu. Sürüm bilgisini alıyor..."
    DOWNLOAD_URL=$(echo "$REFRESH_OUTPUT" | grep "Download URL:" | awk '{print $NF}')
    if [ -n "$DOWNLOAD_URL" ]; then
        echo "[INFO] Yeni sürüm indiriliyor: $DOWNLOAD_URL"
        sudo systemctl stop popd
        wget -q -O "$HOME/pipe/pop" "$DOWNLOAD_URL"
        chmod +x "$HOME/pipe/pop"
        ./pop --refresh || true
        sudo systemctl start popd
        echo "[INFO] Güncelleme tamamlandı. Logları izlemek için: sudo journalctl -u popd -f"
    else
        echo "[ERROR] 'UPDATE AVAILABLE' var ama indirme URL'si bulunamadı!"
    fi
else
    echo "[INFO] Güncelleme yok veya zaten güncelsiniz."
fi
EOF

  chmod +x "$HOME/pipe/auto_update_pipe.sh"

  # 10.b) Cron job ekleyelim (her gün sabah 06:00'da)
  (
    crontab -l 2>/dev/null
    echo "0 6 * * * /bin/bash $HOME/pipe/auto_update_pipe.sh >> $HOME/pipe/auto_update.log 2>&1"
  ) | crontab -

  echo "[OK] Otomatik güncelleme cron job'ı ayarlandı! Her sabah 06:00'da kontrol edecek."
  echo "Loglar için: $HOME/pipe/auto_update.log"
else
  echo "Otomatik güncelleme kurulmadı. Güncellemeleri manuel yapabilirsiniz."
fi

echo ""
echo "Kurulum (ve varsa otomatik güncelleme) tamamlandı!"
echo "---------------------------------------------------"
