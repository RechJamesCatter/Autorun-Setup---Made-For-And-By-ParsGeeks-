#!/bin/bash

echo "USB autorun setup başlıyor!"

# Zenity ile detayları sor
VENDOR=$(zenity --entry --title="Vendor ID" --text="lsusb'den Vendor ID gir (örnek: 0781)" --entry-text="XXXX")
[ $? -ne 0 ] && exit 1

PRODUCT=$(zenity --entry --title="Product ID" --text="Product ID gir (örnek: 5581)" --entry-text="YYYY")
[ $? -ne 0 ] && exit 1

SERIAL=$(zenity --entry --title="Serial (YOK ise YOK yaz)" --text="Serial numarası ne? (YOK yazabilirsin)" --entry-text="YOK")
[ $? -ne 0 ] && exit 1

USB_ADI=$(zenity --entry --title="USB Adı" --text="Bu USB'ye ne isim verelim? (log için)" --entry-text="Reşit Parsgeeks USB")
[ $? -ne 0 ] && exit 1

# Dosya adlarını temizle
RULE_NAME=$(echo "$USB_ADI" | tr '[:upper:]' '[:lower:]' | tr -s ' ' '-' | sed 's/[^a-z0-9-]//g')
RULE_FILE="/etc/udev/rules.d/99-${RULE_NAME}-parsgeeks.rules"
LOG_FILE="/tmp/${RULE_NAME}-parsgeeks-log.txt"

zenity --question --title="Onayla" --text="Vendor: $VENDOR\nProduct: $PRODUCT\nSerial: $SERIAL\nUSB Adı: $USB_ADI\nDevam mı?"
[ $? -ne 0 ] && exit 1

# Udev kuralı oluştur (USB block cihazı takıldığında tetikle)
cat > "$RULE_FILE" << EOF
ACTION=="add", SUBSYSTEM=="block", SUBSYSTEMS=="usb", \
    ATTR{idVendor}=="$VENDOR", ATTR{idProduct}=="$PRODUCT", \
EOF

if [ "$SERIAL" != "YOK" ]; then
    echo "    ATTRS{serial}==\"$SERIAL\", \\" >> "$RULE_FILE"
fi

cat >> "$RULE_FILE" << EOF
    RUN+="/bin/bash -c 'echo \"\$USB_ADI takıldı, autorun çalıştırılıyor - \$(date)\" >> $LOG_FILE; parsgeeks -k off >> $LOG_FILE 2>&1 || echo \"Hata: parsgeeks çalışmadı\" >> $LOG_FILE'"
EOF

# Kuralları yükle
udevadm control --reload-rules
udevadm trigger

zenity --info --title="Kurulum Bitti!" --text="Hazır!\nSadece bu USB takılınca 'parsgeeks -k off' otomatik çalışacak.\nLog dosyası: $LOG_FILE\nUSB'yi çıkar-tak dene, loga bak!"

echo "Kurulum tamamlandı! Logu izle: tail -f $LOG_FILE"
