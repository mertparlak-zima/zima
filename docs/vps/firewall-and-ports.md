# Contabo firewall ve port güvenliği

Sağlayıcı firewall kuralları, port baseline, host firewall kararları ve harici port testi.

Belge indeksi: [README.md](README.md) · Kaynak bölüm numaraları korunmuştur (bkz. indeksteki harita).

## 4. Contabo Firewall ve port güvenliği

Panel → Firewall → Inbound Rules ekranında üç aktif kural vardı:

| Öncelik | Kural adı | Action | Protokol / port | Kaynak |
|---|---|---|---|---|
| 1 | HTTPS - Cloudflare | ACCEPT | TCP 443 | Tanımlanan Cloudflare CIDR'leri |
| 2 | SSH - EV | ACCEPT | TCP 22 | `46.1.14.14/32` |
| 3 | Block all traffic | DROP | Any / Any | Any |

Cloudflare CIDR listesinin tamamı ekranda açılmadığından tam liste bu belgede varsayılmadı. Gerekirse [Cloudflare IP ranges](https://www.cloudflare.com/ips/) ile karşılaştır. `Active VPS/VDS` sekmesindeki atanmış sunucu ve IPv4/IPv6 kapsamı yeni firewall değişikliği sırasında teyit edilmeli.

### 4.1 Port baseline

| Port | Hizmet | Host üzerinde | Ev internetinden IPv4 TCP |
|---|---|---|---|
| 22 | SSH | 0.0.0.0 / :: | True (izinli IP) |
| 23 | Telnet | Dinlenmiyor | False |
| 53 TCP/UDP | systemd-resolved | 127.0.0.53 ve 127.0.0.54 | Test edilmedi; localhost |
| 80 | Traefik HTTP | Publish edilmiş | False |
| 443 | Traefik HTTPS | Publish edilmiş | False (Cloudflare kaynakları hariç) |
| 443 UDP | HTTP/3 | Publish edilmiş | TCP testi kapsamında değil; DROP kuralına tabi olması beklenir |
| 3000 | API | Container ağı | False |
| 5432 | PostgreSQL | Container ağı | False |
| 5984 | CouchDB | Container ağı | False |
| 6001, 6002 | Coolify | Publish edilmiş | False |
| 6379 | Redis | Container ağı | False |
| 8000 | Coolify paneli → container 8080 | Publish edilmiş | False |
| 8080 | Traefik | Publish edilmiş | False |
| 8787 | API | Container ağı | False |
| 20241 | cloudflared | 127.0.0.1 | Test edilmedi; localhost |

cloudflared yüksek numaralı UDP socket'leri de görüldü; outbound tunnel bağlantılarıyla uyumlu. Bunlar tek başına açık bir inbound servis veya saldırı bulgusu değil.

### 4.2 Host firewall

- UFW: `inactive`.
- `iptables` ve `ip6tables`: INPUT ACCEPT, OUTPUT ACCEPT, FORWARD DROP. Docker yayınlanan portlar için kendi ACCEPT kurallarını oluşturuyor. DOCKER-USER üzerinde özel filtre yok.
- `nft list tables`: ip/ip6 nat, filter, raw tabloları görüldü; ayrı bir host firewall politika zinciri tespit edilmedi.
- Karar: Şimdilik Contabo firewall birincil inbound koruma. UFW ve Fail2Ban eklenmedi. Bu bir defense-in-depth eksikliğidir; sağlayıcı firewall yanlış yapılandırılırsa publish edilen yönetim portları açığa çıkabilir.
- Docker'ın publish ettiği portlar UFW INPUT kurallarını bypass edebilir. UFW'yi etkinleştirmeyi tek başına Docker koruması olarak kabul etme. Ek firewall planlanırsa Docker uyumlu filtreleme, IPv6 ve kalıcılık dahil ayrı değişiklik/test planı hazırla.

### 4.3 Ne zaman tekrar port testi yapılmalı?

Yeni port publish edildiğinde, firewall kuralları değiştiğinde, DNS proxy/tunnel mimarisi değiştiğinde, Docker networking değiştiğinde veya şüpheli olay olduğunda. Sıradan paket güncellemesinde tüm port listesini yeniden test etmek şart değil; kritik portlar için kısa smoke test yeterli olabilir.

**Windows PowerShell — SSH oturumu dışında, kendi bilgisayarından:**

```powershell
$ports = 22,23,80,443,3000,5432,5984,6001,6002,6379,8000,8080,8787
foreach ($port in $ports) {
    $result = Test-NetConnection -ComputerName 156.67.103.212 -Port $port -WarningAction SilentlyContinue
    Write-Host "$port : $($result.TcpTestSucceeded)"
}
```

Ev IP'sinden beklenen: 22 True, diğerleri False. Farklı bir internet bağlantısından 22 de False olmalı. Bu test yalnızca seçili IPv4 TCP portlarını kapsar; tüm portların, UDP'nin veya tüm kaynak IP'lerin engellendiğinin kanıtı değildir.

**IPv6 — tamamlanmamış:** Public IPv6 adresine 22,23,80,443,6001,6002,8000,8080 testlerinin hepsi False çıktı. Ancak `curl.exe -6 --max-time 10 https://api64.ipify.org` DNS çözümleme hatası verdi. Bu nedenle istemcinin IPv6 bağlantısı doğrulanamadı, negatif sonuç kesin kanıt değil.

IPv6 erişimi olan bir istemcide önce bağlantıyı doğrula, ardından aynı port döngüsünü `2a02:c207:2376:7355::1` adresine uygula. IPv6 kullanılmıyorsa bile mevcut firewall kapsamını teyit et. Sırf test hatası nedeniyle VPS'in IPv6 ağ ayarını değiştirme.

Nmap varsa aynı tarama harici istemciden yapılabilir; VPS'e Nmap kurmak ve kendi public IP'sini VPS içinden taramak dış erişimi doğrulamaz.
