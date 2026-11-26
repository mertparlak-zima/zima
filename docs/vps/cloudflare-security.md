# Cloudflare güvenlik yapılandırması

Free plan ayarları, WAF scanner kuralı, Access/Tunnel/Obsidian istisnaları, DNSSEC ve rollback prensibi. MCP/OAuth erişimi için bkz. [../cloudflare.md](../cloudflare.md).

Belge indeksi: [README.md](README.md) · Kaynak bölüm numaraları korunmuştur (bkz. indeksteki harita).

## 6. Cloudflare güvenlik yapılandırması

### 6.1 Free plan ve ayarlar

| Özellik | Son bilinen durum | Kanıt / karar |
|---|---|---|
| Custom Rules | Başlangıç 0/5; sonrasında scanner WAF kuralı çalışıyor olarak raporlandı | Agent: `/.env` 403, son kural sayısı/ID/expression paylaşılmadı |
| Rate Limiting | Başlangıç 0/1; eklenmedi | Gerçek login endpoint'leri bilinmiyor |
| Managed Rules | Panelde Upgrade plan / No Managed rules created | Free Managed Ruleset'in kesin aktif durumu ayrıca raporlanmadı |
| Response Rules | Cloudflare default protection applied | Panelde doğrulandı |
| DDoS Protection | Varsayılan Cloudflare koruması bekleniyor | Ayrı etkin ayar/API sonucu paylaşılmadı |
| SSL/TLS mode | Full (strict) | Agent raporu; değişmedi |
| Minimum TLS | 1.0 → 1.2 | Agent raporu; TLS 1.1 reddedildi, 1.2 ve 1.3 çalıştı |
| TLS 1.3 | On | Agent raporu |
| Always Use HTTPS | Off → On | Agent raporu; 4 hostname HTTP → HTTPS 301 |
| Automatic HTTPS Rewrites | On | Agent raporu |
| Universal SSL | Aktif, apex ve wildcard | Agent raporu |
| URL Normalization | `cloudflare`, `incoming` | Agent raporu |
| Bot Fight Mode | Off | Bilinçli olarak kapalı |
| HSTS | Off | Bilinçli olarak kapalı |
| Cache / Config Ruleset | Yok | Agent raporu |
| DNSSEC | Pending | Cloudflare paneli; otomatik DS ekleme başlatıldı |
| Multi-signer DNSSEC | Off | Değiştirme |
| Multi-provider DNS | Off | Değiştirme |
| Email Security | Yapılandırılmadı | Bu bakımın kapsamı dışında |

Dashboard başlangıçta 5 custom rule, 1 rate limiting rule hakkı gösteriyordu. Temel WAF için konuşmada aylık istek kotası belirtilmedi; plan özellikleri gelecekte değişebilir. Bu nedenle yeni kural eklerken mevcut limitleri dashboard'dan veya resmi dokümantasyondan doğrula. Ücretli plana geçilmedi. Kullanılan mevcut özellikler için ilave abonelik hedefi 0 USD; fatura ayrıca incelenmedi.

Yönetim ekranları: Cloudflare Dashboard → `zimastack.com` → Security → Security rules / Analytics / Events; DNS → Records / Settings; SSL/TLS. Zero Trust → Access → Applications / Policies ve tunnel yönetimi ayrı alanlardır. Arayüz isimleri zamanla değişebilir.

### 6.2 WAF scanner kuralı

Amaç, loglarda gördüğümüz `.env`, `.git`, PHP, WordPress ve yönetim paneli taramalarını edge'de durdurmak. WAF SSH'yi korumaz; Contabo firewall'un yerine geçmez ve uygulama içi yetkilendirme/açık düzeltmelerinin alternatifi değildir.

Aşağıdaki expression agent'a önerilen şablondur; **Cloudflare'de gerçekten deploy edilen expression ile birebir aynı olduğu doğrulanmadı.** Mevcut rule'u yeniden oluşturma. Gerekirse MCP veya dashboard'dan mevcut rule ID, name, expression, action, enabled ve scope değerlerini alıp bu belgeye ekle.

- Önerilen ad: `Block Malicious Scanners`
- Action: `Block`
- Phase: `http_request_firewall_custom`

```text
(
  lower(http.request.uri.path) contains "/.env" or
  lower(http.request.uri.path) contains "/.git/" or
  lower(http.request.uri.path) eq "/.git" or
  lower(http.request.uri.path) contains "/.ssh" or
  lower(http.request.uri.path) contains "/.aws" or
  lower(http.request.uri.path) contains "/etc/passwd" or
  lower(http.request.uri.path) contains "/wp-admin" or
  lower(http.request.uri.path) contains "/wp-content" or
  lower(http.request.uri.path) contains "/wp-includes" or
  ends_with(lower(http.request.uri.path), ".php") or
  starts_with(lower(http.request.uri.path), "/phpmyadmin") or
  starts_with(lower(http.request.uri.path), "/adminer") or
  starts_with(lower(http.request.uri.path), "/actuator")
)
```

Bu şablon regex gerektirmez, ancak geniş `contains` koşulları meşru dinamik URL'leri (özellikle CouchDB document ID'lerini) yanlışlıkla eşleştirebilir. Gerçek PHP/WordPress/Actuator uygulaması eklenirse ilgili koşullar yeniden kapsamlandırılmalı. `/svgs/phpmyadmin.svg` normal bir Coolify statik dosyasıdır; önceki script'te false positive yarattı. Bu yolu engelleme. Genel `/api/*` veya `/svgs/*` için WAF bypass/Skip kuralı da oluşturma.

Agent'ın son testinde `/.env` 403 ve SVG yanıtı değişmedi. 403 tek başına WAF kuralının tetiklendiğini ispatlamaz; mümkün olduğunda Security Events ile rule ID/action eşleştir. Geçmiş saldırı IP'lerini kalıcı toplu engellemek yerine istek desenini hedefle. Paylaşımlı/cloud IP'ler değişebilir.

### 6.3 Access, Tunnel ve Obsidian istisnaları

- `admin.zimastack.com` ve `coin-tracker.zimastack.com` 302 ile Cloudflare Access'e yönlendiriyor (agent raporu). Access policy içeriği, yetkili kullanıcılar ve MFA şartları ayrıca doğrulanmadı; 302 yalnızca yönlendirme testidir.
- Admin için ekstra IP-only WAF kuralı otomatik eklenmedi. Ev IP'si değişebilir ve ev dışı erişim ihtiyacı olabilir. Mevcut Access politikalarını koru.
- `notes.zimastack.com` 401 ile CouchDB auth gerektiriyor. Browser Access login, JavaScript challenge, CAPTCHA, Managed Challenge, Under Attack Mode gibi mekanizmalar makine istemcilerini bozabilir.
- LiveSync için `_changes`, `_bulk_docs`, `_revs_diff`, `_bulk_get` vb. normal replication endpoint'lerini, PUT/POST/DELETE/HEAD/GET/OPTIONS ve auth header'larını engelleme.
- CouchDB yanıtlarını Cache Everything ile cache'leme; CORS ve auth header ayarlarını gerekçesiz değiştirme.
- Free Bot Fight Mode, normal WAF Skip ile istisna verilemeyebildiği için mevcut API/LiveSync yapısında kapalı bırakıldı.
- Rate limiting şu anda gerekli değil; tek kural hakkını ancak gerçek login endpoint'i, trafik profili ve mevcut Free plan filtre/threshold limitleri doğrulanınca kullan. Tüm `/api/*`, LiveSync veya bütün zone için global rate limit kurma. Uygulama içi brute-force korumasını ayrıca değerlendir.

### 6.4 DNSSEC

Cloudflare → DNS → Settings → DNSSEC → Enable DNSSEC işlemi yapıldı. Ekranda `DNSSEC is pending while we automatically add the DS record on your domain.` ve Cloudflare Registrar uyarıları görüldü. DS otomatik ekleniyor; manuel DS kaydı girmeye, nameserver değiştirmeye veya Cancel Setup'a basmaya gerek yok.

Son durum **Pending**. Bir sonraki kontrolde `Active` doğrula; [DNSViz](https://dnsviz.net/d/zimastack.com/dnssec/) ile DNSSEC zincirini kontrol edebilirsin. Pending uzun sürerse registrar/DS durumunu incele; rastgele DS değişikliği yapma. DNSSEC yanlış yapılandırılırsa validating resolver'larda SERVFAIL ve erişim kesintisi oluşabilir.

### 6.5 Cloudflare değişiklik ve rollback prensibi

1. Doğru account/zone ve planı kontrol et; mevcut rule/settings snapshot'ını gizli bilgi olmadan al.
2. Tek bir değişiklik uygula, API'den geri oku, normal endpoint'leri ve WAF eşleşmesini test et.
3. İlgili değişiklik sorun çıkarırsa yalnızca o değişikliği geri al. Ruleset'i bütünüyle overwrite etme; duplicate kural oluşturma.
4. DNS, firewall, tunnel, SSL mode, HSTS, Access ve cache ayarlarını geniş kapsamda otomatik değiştirme.
5. Aşağıdaki eski değerler rollback referansı: `min_tls_version=1.0`, `always_use_https=off`. Bunlar daha zayıf güvenlik seviyesine döner; yalnızca gerçek uyumluluk sorunu varsa geçici olarak ve gerekçeyle kullan. API: `PATCH /zones/{zone_id}/settings/{setting_id}` ve `{"value":"..."}`.
6. MCP agent'ına en az gerekli izinleri ver; erişim token'larını, private key'leri ve şifreleri prompt/rapora koyma.
