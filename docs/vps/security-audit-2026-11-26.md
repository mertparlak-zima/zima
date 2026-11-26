# Saldırı denetimi - 26 Kasım 2026 sonuçları

SSH ve Traefik HTTP log denetimi sonuçları (tarihsel kayıt; güncel blocklist değildir).

Belge indeksi: [README.md](README.md) · Kaynak bölüm numaraları korunmuştur (bkz. indeksteki harita).

## 9. Saldırı denetimi — 26 Kasım 2026 sonuçları

### 9.1 SSH

Kapsam: `journalctl -u ssh --since "7 days ago"`. Başarılı bağlantı kayıtları, mevcut `authorized_keys` fingerprint'leri ve Docker IP'leriyle karşılaştırıldı.

| Kaynak | Kullanıcı | Başarılı public-key bağlantısı | Yorum |
|---|---|---:|---|
| 10.0.1.5 | root | 85 | Coolify mevcut IP, fingerprint eşleşiyor |
| 10.0.1.4 | root | 17 | Eski Docker iç IP, aynı Coolify key |
| 10.0.1.3 | root | 2 | Eski Docker iç IP, aynı Coolify key |
| 46.1.14.14 | mertpc | 4 | Kişisel anahtar ve ev IP eşleşiyor |
| Toplam | | 108 | Tümü publickey |

`preauth|failed|invalid user|authentication failure|unable to negotiate` sayısı: 0. Geniş aramadaki `Received disconnect` / `Disconnected from user root` kayıtları normal Coolify SSH oturum kapanışlarıydı. Bu, upstream firewall tarafından engellenen taramaların hiç gerçekleşmediğini kanıtlamaz. Başarılı public-key kaydı da yalnız başına anahtarın hiçbir zaman çalınmadığını kanıtlamaz; burada bilinen fingerprint ve bağlamla uyumluluk denetlendi.

### 9.2 Traefik HTTP logları

- `--accesslog=true`
- `--accesslog.filepath=/traefik/access.log`
- `--accesslog.format=json`
- Korunan request header'ları: Cf-Connecting-Ip, Cf-Ipcountry, Cf-Cache-Status, Cf-Verified-Bot, Cf-Ray, X-Forwarded-For, User-Agent, Referer.
- Host log konumu: `/data/coolify/proxy/access.log` (19.979.450 byte) ve `access.log.1.gz` (1.104.139 byte).
- Logrotate container'ı ve sıkıştırılmış dosya mevcut; rotation/retention ayrıntıları ayrıca okunmadı.
- Kapsam: `2026-11-18T21:38:42.809031328Z` – `2026-11-26T09:26:18.590292417Z` (yaklaşık 7,5 gün; UTC).

| Metrik | Sonuç |
|---|---:|
| Toplam HTTP isteği | 32.197 |
| İlk şüpheli eşleşme | 947 (~%2,94) |
| False positive | 4 |
| Kalan potansiyel zararlı istek | 943 (~%2,93) |
| Okunamayan JSON kaydı | 0 |
| Başarılı saldırı bulgusu | 0 (sadece incelenen imzalar kapsamında) |

#### İsteklerin hostname bazında dağılımı

| Host | İstek |
|---|---:|
| admin.zimastack.com | 13.272 |
| coin-tracker.zimastack.com | 8.777 |
| coinbot.zimastack.com | 8.044 |
| notes.zimastack.com | 1.899 |
| coinbot-test.zimastack.com (eski kayıt) | 205 |

#### HTTP status dağılımı

| Kod | Adet | Kod | Adet |
|---|---:|---|---:|
| 200 | 27.053 | 404 | 1.581 |
| 304 | 817 | 503 | 770 |
| 302 | 649 | 401 | 395 |
| 204 | 389 | 409 | 165 |
| 201 | 146 | 0 | 109 |
| 499 | 40 | 403 | 36 |
| 303 | 27 | 502 | 8 |
| 202 | 7 | 504 | 4 |
| 400 | 1 | | |

503/502/504 gibi 5xx kodları tek başına saldırı göstergesi değildir; deployment, upstream readiness, proxy/uygulama arızası gibi nedenler araştırılabilir. Sürekli veya ani artış varsa ayrıca incele. Status 0 ve 499 kesilmiş isteklerle ilişkili olabilir; bağlam olmadan kesin neden atanmadı.

#### Şüpheli tarama kategorileri

| Kategori | Eşleşme | 401 | 403 | 404 | 200 |
|---|---:|---:|---:|---:|---:|
| ENV dosyası | 561 | 23 | 0 | 538 | 0 |
| PHP | 265 | 13 | 2 | 250 | 0 |
| WordPress | 65 | 8 | 2 | 55 | 0 |
| Git | 53 | 6 | 0 | 47 | 0 |
| Yönetim paneli | 36 | 5 | 0 | 27 | 4 |
| Hassas sistem dosyası | 16 | 4 | 0 | 12 | 0 |

Bir HTTP isteği birden fazla kategoriye girebilir; satırları toplayarak toplam tekil saldırı sayısı çıkarma. Path traversal, SQL injection ve XSS için kullanılan sınırlı regex imzalarında eşleşme görülmedi. Request body veya tüm header tabanlı exploit'ler incelenmedi.

4 adet HTTP 200 kaydının tamamı `admin.zimastack.com/svgs/phpmyadmin.svg` için normal GET, 862 byte, kişisel IP, Chrome Windows ve `coolify@file` service/`coolify-https@file` router olarak doğrulandı. Bu dosya erişimi bir panel exploit'i değildir. Diğer 943 şüpheli eşleşme 401/403/404 aldı; bu olumlu sonuç, tüm veri sızıntısı veya uygulama içi yetkilendirme açıklarının olmadığını ispatlamaz.

#### En çok şüpheli eşleşme oluşturan IP'ler (tarihsel)

| IP | Adet | IP | Adet |
|---|---:|---|---:|
| 34.174.12.212 | 253 | 3.101.102.40 | 161 |
| 13.70.55.149 | 148 | 104.244.74.39 | 128 |
| 195.178.110.94 | 59 | 45.148.10.62 | 24 |
| 45.138.12.16 | 23 | 91.148.244.131 | 20 |
| 195.178.110.199 | 19 | 45.153.102.83 | 12 |
| 91.148.245.81 | 10 | 81.171.72.93 | 10 |
| 34.145.175.189 | 9 | 94.26.106.240 | 6 |
| 46.1.14.14 (false positive) | 4 | | |

`Cf-Connecting-Ip` değerleri proxy header'larından okunuyor; güvenilir proxy zinciri ve origin erişim kontrolü doğrulanmadan mutlak saldırgan kimliği sayma. Kötü niyetli kişi veya ülke ataması yapma. Geçmiş IP listesi güncel blocklist değildir.
