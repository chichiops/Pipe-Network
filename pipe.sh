#!/bin/bash

# Periksa apakah skrip dijalankan dengan hak akses root
if [ "$EUID" -ne 0 ]; then 
    echo "Harap jalankan skrip ini dengan hak akses root"
    exit 1
fi

# Lokasi penyimpanan skrip
SCRIPT_PATH="$HOME/pipe pop.sh"

# Fungsi menu utama
function main_menu() {
    while true; do
        clear
        echo "Skrip ini dibuat oleh komunitas Dadu, Twitter @ferdie_jhovie, open-source gratis, jangan percaya layanan berbayar."
        echo "Jika ada masalah, hubungi Twitter, hanya ada satu akun ini."
        echo "================================================================"
        echo "Untuk keluar dari skrip, tekan ctrl + C pada keyboard."
        echo "Silakan pilih operasi yang ingin dijalankan:"
        echo "1. Deploy node pipe pop"
        echo "2. Cek reputasi"
        echo "3. Backup info"
        echo "4. Buat undangan pop"
        echo "5. Upgrade versi (disarankan backup info sebelum upgrade)"
        echo "6. Keluar"

        read -p "Masukkan pilihan Anda: " choice

        case $choice in
            1)
                deploy_pipe_pop
                ;;
            2)
                check_status
                ;;
            3)
                backup_node_info
                ;;
            4)
                generate_referral
                ;;
            5)
                upgrade_version
                ;;
            6)
                echo "Keluar dari skrip."
                exit 0
                ;;
            *)
                echo "Pilihan tidak valid, silakan pilih lagi."
                read -p "Tekan tombol apa saja untuk melanjutkan..."
                ;;
        esac
    done
}

# Fungsi untuk deploy node pipe pop
function deploy_pipe_pop() {
    # Periksa apakah layanan node DevNet 1 sedang berjalan
    if systemctl is-active --quiet dcdnd.service; then
        echo "Layanan node DevNet 1 sedang berjalan, menghentikan dan menonaktifkannya..."
        sudo systemctl stop dcdnd.service
        sudo systemctl disable dcdnd.service
    else
        echo "Layanan node DevNet 1 tidak berjalan, tidak perlu tindakan."
    fi

    # Konfigurasi firewall, izinkan port TCP 8003
    echo "Mengonfigurasi firewall, mengizinkan port TCP 8003..."
    sudo ufw allow 8003/tcp
    sudo ufw reload
    echo "Firewall diperbarui, port TCP 8003 diizinkan."

    # Instalasi lingkungan
    echo "Menginstal lingkungan..."
    sudo apt-get update
    sudo apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang aria2 bsdmainutils ncdu unzip libleveldb-dev -y

    # Buat direktori cache unduhan
    mkdir -p /root/pipenetwork
    mkdir -p /root/pipenetwork/download_cache
    cd /root/pipenetwork

    # Tanya pengguna apakah ingin menggunakan whitelist
    echo "Pilih jenis tautan unduhan:"
    echo "1) Gunakan tautan unduhan whitelist"
    echo "2) Gunakan tautan unduhan default"
    read -p "Masukkan pilihan (1 atau 2): " USE_WHITELIST

    if [[ "$USE_WHITELIST" == "1" ]]; then
        # Minta pengguna mengisi URL whitelist
        read -p "Masukkan tautan unduhan whitelist: " DOWNLOAD_URL
        echo "Mengunduh file menggunakan tautan whitelist..."
        curl -L -o pop "$DOWNLOAD_URL"
    else
        # Gunakan tautan unduhan default dengan curl
        echo "Mencoba mengunduh file dengan curl..."
        if ! curl -L -o pop "https://dl.pipecdn.app/v0.2.6/pop"; then
            echo "Unduhan dengan curl gagal, mencoba menggunakan wget..."
            wget -O pop "https://dl.pipecdn.app/v0.2.6/pop"
        fi
    fi

    # Ubah izin file
    chmod +x pop
    
    echo "Unduhan selesai, nama file adalah 'pop', izin eksekusi diberikan, dan direktori 'download_cache' dibuat."

    # Minta pengguna memasukkan kode undangan, gunakan default jika tidak dimasukkan
    read -p "Masukkan kode undangan (default: b06fe87c32aa189): " REFERRAL_CODE
    REFERRAL_CODE=${REFERRAL_CODE:-b06fe87c32aa189}

    # Tampilkan kode undangan yang digunakan
    echo "Kode undangan yang digunakan: $REFERRAL_CODE"

    # Jalankan perintah ./pop dengan kode undangan
    ./pop --signup-by-referral-route $REFERRAL_CODE

    # Minta pengguna memasukkan ukuran RAM, disk, dan alamat Solana
    read -p "Masukkan ukuran RAM (default: 4 GB): " MEMORY_SIZE
    MEMORY_SIZE=${MEMORY_SIZE:-4}

    read -p "Masukkan ukuran disk (default: 100 GB): " DISK_SIZE
    DISK_SIZE=${DISK_SIZE:-100}

    read -p "Masukkan alamat Solana: " SOLANA_ADDRESS

    # Buat file layanan systemd
    SERVICE_FILE="/etc/systemd/system/pipe-pop.service"
    echo "[Unit]
Description=Pipe POP Node Service
After=network.target
Wants=network-online.target

[Service]
User=root
Group=root
ExecStart=/root/pipenetwork/pop --ram=$MEMORY_SIZE --pubKey $SOLANA_ADDRESS --max-disk $DISK_SIZE --cache-dir /var/cache/pop/download_cache
Restart=always
RestartSec=5
LimitNOFILE=65536
LimitNPROC=4096
StandardOutput=journal
StandardError=journal
SyslogIdentifier=dcdn-node
WorkingDirectory=/root/pipenetwork

[Install]
WantedBy=multi-user.target" | sudo tee $SERVICE_FILE > /dev/null

    # Reload konfigurasi systemd
    sudo systemctl daemon-reload

    # Jalankan layanan dan atur agar berjalan saat boot
    sudo systemctl start pipe-pop.service
    sudo systemctl enable pipe-pop.service

    echo "Layanan Pipe POP telah dimulai dan dikonfigurasi untuk berjalan saat boot."
    echo "Gunakan perintah berikut untuk memeriksa status layanan:"
    echo "  sudo systemctl status pipe-pop.service"
    echo "Gunakan perintah berikut untuk menghentikan layanan:"
    echo "  sudo systemctl stop pipe-pop.service"
    echo "Gunakan perintah berikut untuk me-restart layanan:"
    echo "  sudo systemctl restart pipe-pop.service"

    echo "Sekarang memeriksa status layanan. Tekan 'q' untuk keluar dari tampilan status."
    sudo systemctl status pipe-pop.service

    read -p "Tekan tombol apa saja untuk kembali ke menu utama..."
}

# Fungsi untuk memeriksa reputasi node
function check_status() {
    echo "Memeriksa status ./pop..."
    cd /root/pipenetwork
    ./pop --status
    read -p "Tekan tombol apa saja untuk kembali ke menu utama..."
}

# Fungsi untuk mencadangkan file node_info.json
function backup_node_info() {
    echo "Mencadangkan file node_info.json..."
    cd /root/pipenetwork
    cp ~/node_info.json ~/node_info.backup2-4-25
    echo "Pencadangan selesai, node_info.json telah dicadangkan ke ~/node_info.backup2-4-25."
    read -p "Tekan tombol apa saja untuk kembali ke menu utama..."
}

# Fungsi untuk membuat undangan pop
function generate_referral() {
    echo "Membuat kode undangan pop..."
    cd /root/pipenetwork
    ./pop --gen-referral-route
    read -p "Tekan tombol apa saja untuk kembali ke menu utama..."
}

# Fungsi untuk upgrade versi
function upgrade_version() {
    echo "Mengupgrade ke versi 2.0.6..."
    sudo systemctl stop pipe-pop
    sudo rm -f /root/pipenetwork/pop
    wget -O /root/pipenetwork/pop "https://dl.pipecdn.app/v0.2.6/pop"
    sudo chmod +x /root/pipenetwork/pop
    sudo systemctl daemon-reload
    sudo systemctl restart pipe-pop
    journalctl -u pipe-pop -f
    read -p "Tekan tombol apa saja untuk kembali ke menu utama..."
}

# Jalankan menu utama
main_menu
