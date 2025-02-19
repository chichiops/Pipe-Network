# Pipe-Network

## Instal Dependensi yang Diperlukan
```
apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang aria2 bsdmainutils ncdu unzip libleveldb-dev -y
```
## Unduh Skrip dan Beri Izin Eksekusi

```
wget -O https://raw.githubusercontent.com/chichiops/Pipe-Network/refs/heads/main/pipe.sh
```
```
chmod +x pop.sh
```
##  Jalankan Skrip
```
./pipe.sh #
```
## Ikuti Instruksi di Menu Skrip
Setelah skrip berjalan, Anda akan melihat menu seperti ini:
1. Deploy pipe pop node
2. Cek reputasi
3. Backup info
4. Buat undangan pop
5. Upgrade versi
6. Keluar

Masukkan angka yang sesuai untuk memilih opsi yang diinginkan. Untuk menginstal node Pipe POP, pilih 1 dan ikuti instruksi selanjutnya.

## Mengecek Status Node 
Setelah instalasi selesai, Anda bisa mengecek status node dengan perintah:
```
sudo systemctl status pipe-pop.service
```
Jika node berjalan dengan benar, akan terlihat status active (running). Untuk melihat log node secara real-time:
```
journalctl -u pipe-pop -f
```
## Menghentikan atau Memulai Ulang Node
```
sudo systemctl stop pipe-pop.service
```
Untuk memulai ulang node:
```
sudo systemctl restart pipe-pop.service
```
