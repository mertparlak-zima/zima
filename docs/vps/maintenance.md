# Rutin bakım, otomatik güncellemeler ve takvim

Preflight, APT, reboot, postflight, arıza teşhisi, unattended-upgrades ve bakım takvimi. Ayrıca bkz. [security-commands.md](security-commands.md) ve [open-items.md](open-items.md).

Belge indeksi: [README.md](README.md) · Kaynak bölüm numaraları korunmuştur (bkz. indeksteki harita).

## 10. Rutin bakım — bir sonraki güncellemede bu bölümü kullan

**Hedef:** Normal bakımda SSH, tüm portlar, DNS, firewall ve WAF'ı sıfırdan denetleme. Önce değişiklik olup olmadığına bak; kısa bir preflight, güncelleme, gerekiyorsa reboot ve postflight uygula. Bir sorun bulunursa ilgili ayrıntılı teşhis bölümüne geç.

### 10.1 Bakım öncesi (VPS SSH terminali)

Bakım için kısa kesinti penceresi belirle. Contabo paneline/konsoluna erişimin olduğundan emin ol. Kullanıcının mevcut kararı gereği yedekleme denetimi ertelendi; bu riski kabul etmek ile yedeklerin var olduğunu varsaymak farklı şeylerdir. Özellikle major upgrade, volume işlemleri veya DB migration öncesinde güncel ve geri yüklenebilir yedek şartı tekrar değerlendirilmeli.

```bash
# PRE-FLIGHT: salt okunur hızlı durum özeti
printf '\n=== SYSTEM ===\n'
date -Is
uname -r
uptime
sudo systemctl --failed
printf '\n=== CORE SERVICES ===\n'
for service in docker containerd cloudflared ssh.socket; do
  printf '%s: ' "$service"; systemctl is-active "$service"
done
printf '\n=== CONTAINERS ===\n'
sudo docker ps -a --format 'table {{.Names}}\t{{.Status}}'
printf '\n=== RESOURCES ===\n'
df -h / /boot
free -h
printf '\n=== REBOOT ===\n'
if [ -f /var/run/reboot-required ]; then
  cat /var/run/reboot-required
  cat /var/run/reboot-required.pkgs 2>/dev/null
else
  echo 'Reboot gerekli degil'
fi
```

Beklenti: failed unit yok, dört temel servis active, çalışan uygulamalar Up/healthy. Migration Exited (0) normal. Son bilinen container sayısı 15 running; yeni deployment veya servis eklenmişse sayının değişmesi olağan. Bakım öncesi durumu sonrasıyla karşılaştır, eski sayıyı katı başarı şartı yapma.

### 10.2 Paket listesini güncelle ve simüle et

```bash
sudo apt-get -o APT::Update::Error-Mode=any update && sudo apt-get -s upgrade
```

- Hata varsa gerçek upgrade'e geçme.
- `File has unexpected size / Mirror sync in progress?` görülürse bir süre sonra aynı komutu yeniden dene. 26 Kasım'da bu şekilde düzeldi. APT hash/signature doğrulamasını kapatma; trusted=yes, unauthenticated veya doğrulama bypass seçenekleri kullanma.
- `deferred due to phasing` normal olabilir; zorla phased update açma.
- Silinecek paketler, beklenmeyen dependency değişiklikleri, major upgrade veya kritik servis değişiklikleri varsa dur ve incele.
- `apt update` sadece indeksleri günceller; `apt-get -s upgrade` sadece simülasyondur.

### 10.3 Normal paket güncellemesi

Preflight uygunsa ve kısa kesinti kabul edilebiliyorsa:

```bash
sudo apt upgrade
```

Onay ekranındaki planı incele, sonra devam et. Docker, cloudflared ve systemd gibi paketler servis restart'ına yol açabilir. `needrestart` çıktısını oku; otomatik veya deferred restart'ları değerlendir. `-y` ile her koşulda otomatik onay verme. SSH oturumu koparsa paket yöneticisini ikinci kez körlemesine başlatma; yeniden bağlanıp devam eden apt/dpkg işlemlerini kontrol et.

`do-release-upgrade`, toplu container image güncellemesi, `apt full-upgrade`, `apt autoremove` ve Docker prune rutin komut setine dahil değildir. Bunlar gerektiğinde ayrı risk değerlendirmesiyle yapılır.

### 10.4 Reboot kararı

```bash
if [ -f /var/run/reboot-required ]; then
  cat /var/run/reboot-required
  cat /var/run/reboot-required.pkgs 2>/dev/null
else
  echo 'Reboot gerekli degil'
fi
```

Yeni kernel veya reboot-required işareti varsa planlı reboot uygula. Her paket güncellemesinde reboot şart değil; `needrestart` tarafından ertelenen kritik servis yeniden başlatmalarını da değerlendir.

Reboot öncesinde servis başlangıç ayarları son kontrolden beri değişmediyse tüm restart policy'leri tekrar okumak gerekmez. Değişiklik varsa:

```bash
systemctl is-enabled docker containerd cloudflared ssh.socket
sudo docker inspect --format '{{.Name}} | {{.State.Status}} | {{.HostConfig.RestartPolicy.Name}}' $(sudo docker ps -aq)
```

Ardından:

```bash
sudo reboot
```

SSH kopacak. İlk bağlantı denemelerinde `Connection refused` görülebilir; 26 Kasım'da ilk iki deneme başarısız, sonraki deneme başarılı oldu. Açılış tamamlandıktan sonra ev IP'sinden bağlan:

```powershell
ssh mertpc@156.67.103.212
```

Uzun süre erişilemiyorsa önce Contabo panel/konsol durumu ve ev public IP allowlist'ini incele. Firewall'u tamamen açma, tekrar tekrar reboot etme.

### 10.5 Postflight (güncelleme/reboot sonrası)

```bash
printf '\n=== SYSTEM ===\n'
uname -r
uptime
sudo systemctl --failed
printf '\n=== CORE SERVICES ===\n'
for service in docker containerd cloudflared ssh.socket; do
  printf '%s: ' "$service"; systemctl is-active "$service"
done
printf '\n=== CONTAINERS ===\n'
sudo docker ps -a --format 'table {{.Names}}\t{{.Status}}'
printf '\n=== VERSION ===\n'
sudo docker version --format 'Docker server: {{.Server.Version}}'
cloudflared --version
printf '\n=== PENDING UPDATES ===\n'
apt list --upgradable 2>/dev/null
printf '\n=== REBOOT ===\n'
if [ -f /var/run/reboot-required ]; then
  cat /var/run/reboot-required
else
  echo 'Reboot gerekli degil'
fi
printf '\n=== HTTPS SMOKE TEST ===\n'
for sub in admin coinbot coin-tracker notes; do
  printf '%s.zimastack.com: ' "$sub"
  curl -sS --max-time 15 -o /dev/null -w '%{http_code}\n' "https://$sub.zimastack.com"
done
```

| Endpoint | Beklenen son bilinen kod | Anlamı |
|---|---:|---|
| admin.zimastack.com | 302 | Access yönlendirmesi |
| coinbot.zimastack.com | 200 | Normal public yanıt |
| coin-tracker.zimastack.com | 302 | Access yönlendirmesi |
| notes.zimastack.com | 401 | CouchDB kimlik doğrulama gerekli |

302/401 başarı sayılır ancak gerçek authenticated işlevler test edilmemiştir. Kullanıcı oturumu aç, gerekli API/worker işlemlerini ve Obsidian iki cihaz arasındaki sync'i test et. 302 yönlendirmesinin doğru Access hedefi olduğuna bak. 403/429/5xx, timeout, 000 veya alışılmadık response artışı varsa ilgili katmanı araştır. WAF testi için gizli dosya içeriğini görüntülemeye çalışma; sadece status ve Security Events eşleşmesini kontrol et.

### 10.6 Güncelleme sonrası arıza teşhisi (yalnızca gerekirse)

```bash
sudo systemctl --failed
sudo journalctl -b -p err --no-pager -n 80
sudo journalctl -u docker -u containerd -u cloudflared -b --no-pager -n 100
sudo docker ps -a --format 'table {{.Names}}\t{{.Status}}'
# Sorunlu container için gerçek adı kullan:
# sudo docker logs --since 30m --tail 100 CONTAINER_ADI
# sudo docker inspect --format '{{json .State.Health}}' CONTAINER_ADI
```

Logları paylaşmadan önce token, authorization header, kişisel veri ve bağlantı dizelerini maskele. Uygulama açılmıyorsa önce ilgili container, DB readiness, proxy ve tunnel durumuna bak. Tüm Docker'ı yeniden başlatma veya tüm kuralları silme. İlgili değişikliği geri almak mümkünse önce tek değişikliği rollback et.

### 10.7 26 Kasım güncellemesinde olanlar (referans)

- İlk APT indeks hatası `noble-updates/universe` mirror sync kaynaklı göründü. Yeniden çalıştırıldığında tamamen düzeldi.
- İlk simülasyon 27 upgrade ve 1 phased paket (`libsqlite3-0`) gösterdi; sonraki simülasyon 28 upgrade, 0 yeni paket, 0 silme, 0 bekletilen paket gösterdi.
- `unattended-upgrades` otomatik olarak `linux-image-6.8.0-151-generic` ve ilgili kernel paketlerini kurmuştu; çalışan kernel 149 olduğundan reboot gerekiyordu.
- `sudo apt upgrade` başarılı tamamlandı; `needrestart` bazı servisleri yeniden başlattı, bazılarını erteledi. Container restart gereksinimi bildirilmedi.
- `sudo reboot` ardından kernel 151 aktif oldu, tüm 15 running container geri geldi, dört domain beklenen HTTP kodlarını döndürdü, `/var/run/reboot-required` kalmadı ve `apt list --upgradable` boştu.

## 11. Otomatik güvenlik güncellemeleri

Mevcut yapılandırma `/etc/apt/apt.conf.d/20auto-upgrades`:

```text
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
```

`unattended-upgrades.service` enabled/active, `apt-daily.timer` ve `apt-daily-upgrade.timer` aktif. Son loglarda 24 Kasım libssh-4, python3-oauthlib, tzdata; 26 Kasım libheif ve kernel paketleri otomatik güncellendi, `All upgrades installed` görüldü. Bazı eski kernel paketleri otomatik temizlendi.

Allowed origins logunda Ubuntu noble/noble-security ve Ubuntu ESM security origin'leri var. ESM origins listede olsa da Ubuntu Pro/ESM Apps aktif olduğu anlamına gelmez; MOTD ESM Apps kapalı dedi. Docker ve Cloudflare üçüncü taraf depoları bu allowed origins listesinde görülmedi; manuel paket bakımı yapmaya devam et.

`apt-config dump | grep -i Automatic-Reboot` boş döndü. Otomatik reboot açıkça etkinleştirilmemiş; Ubuntu'nun normal varsayılanı kapalıdır. Bu ayarı şimdilik değiştirme. Otomatik restart/reboot politikası daha sonra değişirse ayrıca incele.

Aylık veya otomatik güncellemenin durduğundan şüphelenildiğinde:

```bash
systemctl is-enabled unattended-upgrades
systemctl is-active unattended-upgrades
cat /etc/apt/apt.conf.d/20auto-upgrades
systemctl list-timers --all | grep apt
sudo tail -n 30 /var/log/unattended-upgrades/unattended-upgrades.log
sudo apt-config dump | grep -i Automatic-Reboot
```

Her manuel bakımda bu altı komutu tekrar çalıştırmak gerekmez. Logda yakın zamanda başarılı işlem ve timer'ların çalışması yeterli bir periyodik doğrulama sağlar.

## 13. Bakım takvimi ve tekrar etmeme kuralları

Bu bir önerilen bakım planıdır; cron, systemd timer veya ChatGPT otomasyonu olarak kurulmadı.

| Sıklık / tetikleyici | Yapılacak işlem | Tekrar edilmeyecek gereksiz işlem |
|---|---|---|
| Haftalık | Bölüm 10 preflight + APT indeks/simülasyon; ihtiyaç varsa upgrade/reboot; SSH ve Cloudflare olaylarına kısa bakış | Tüm SSH config'i, port listesini, firewall zincirlerini ve DNS kayıtlarını baştan denetleme |
| Aylık | Disk/RAM eğilimi, unattended-upgrades logu, sertifika süreleri, Cloudflare koruma ve Access politika durumu | Her ay sırf bakım olsun diye firewall, WAF veya TLS kuralı değiştirme |
| Her reboot sonrası | Postflight, dört domain smoke test, kritik işlev testi | Gereksiz ikinci reboot veya tüm Docker restart |
| Yeni servis/deploy | İlgili routing, container health, auth ve WAF uyumu; host port publish değiştiyse dış test | Bütün uygulamalara global kural koyma |
| Firewall/DNS/SSH değişikliği | İlgili konfigürasyon + dışarıdan erişim testi, rollback erişimi | Sırf sorun gidermek için tüm firewall'u açma |
| Şüpheli olay / artan hata | SSH ve HTTP logları, Cloudflare Security Events, ilgili uygulama logları; gerekirse geniş denetim | Her 404'ü saldırı veya her 200'ü başarılı exploit kabul etme |
| Sertifika bitişi yaklaşırken | ACME DNS-01 ve yenileme sonucu | Sertifikayı silip yeniden üretme veya port 80'i gereksiz açma |
| Major OS/Coolify/DB upgrade | Ayrı bakım planı, uyumluluk, güncel yedek ve rollback | Normal `apt upgrade` ile aynı riskte kabul etme |
