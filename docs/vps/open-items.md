# Açık konular ve bilinçli ertelemeler

Doğrulanmamış veya ertelenmiş işler; yedekleme kapsamı dahil.

Belge indeksi: [README.md](README.md) · Kaynak bölüm numaraları korunmuştur (bkz. indeksteki harita).

## 14. Açık konular / bilinçli ertelemeler

- [ ] **DNSSEC:** Cloudflare panelinde Pending → Active ve doğrulama zinciri. Bir kez başarılı olduğu görülünce her bakımda yeniden kurma.
- [ ] **IPv6 firewall:** IPv6 erişimi doğrulanmış farklı istemciden test veya sağlayıcı panelinden kapsam teyidi. Ev istemcisindeki DNS hatası nedeniyle önceki negatif test kesin sonuç değil.
- [ ] **SSH farklı IP testi:** Mobil hotspot veya başka yetkisiz kaynak üzerinden 22'nin reddedildiğini doğrula. Test sırasında izinli erişim yöntemini koru.
- [ ] **WAF kural envanteri:** Gerçek expression, rule ID, action, enabled, hostname scope, kullanılan toplam kural sayısı. Agent raporunda eksik; aynı kuralı yeniden oluşturma.
- [ ] **Cloudflare Access:** İzin verilen kimlikler ve MFA politikasının doğrulanması. Mevcut Access akışını değiştirme.
- [ ] **Free Managed Ruleset/DDoS:** Ayrı ayar sonucu alınmadı. Free plan varsayılan korumasını kapatma; gerekirse salt okunur teyit.
- [ ] **ACME renewal:** İlk başarılı otomatik yenileme tarihini kaydet. Mevcut DNS-01 konfigürasyonu ve geçerli sertifikalar doğrulandı; renewal'ın kendisi henüz görülmedi.
- [ ] **Authenticated uygulama testi:** Coolify login, CoinBot/Coin Tracker gerçek işlemleri ve Obsidian LiveSync senkronizasyonu. HTTP smoke testler başarılı, veri bütünlüğü testi yerine geçmiyor.
- [ ] **Yedekleme ve restore:** Kullanıcı şimdilik yapılmasını istemedi; ertelendi. Yedek olmadığı kesin değil, ancak yedeklerin başarı, konum, retention ve restore durumu doğrulanmadı. Veri kaybı riski sürüyor.
- [ ] **Rate Limiting:** Login endpoint bilgisi yok, şimdilik kurulmayacak. Somut brute-force ihtiyacı ortaya çıkarsa tekrar değerlendir.
- [ ] **Host firewall / Fail2Ban:** Bilinçli olarak kurulmadı veya açılmadı; ek savunma katmanı olarak ancak ihtiyaç ve güvenli Docker uyumluluğu planı varsa değerlendir.
- [ ] **HSTS / Bot Fight Mode:** Bilinçli olarak kapalı; mevcut uygulamalar için gerekçesiz değişiklik yapma.

Bu listenin tamamı bir sonraki normal paket güncellemesinin ön koşulu değildir. Yedekleme ve kritik erişim riskleri hariç, ilgili tetikleyici geldiğinde veya kullanıcı istediğinde ele al. Yeni güvenlik bulgusu varsa öncelik yeniden belirlenir.

### Ertelenen yedekleme kapsamı (ileride)

CoinBot PostgreSQL, Coin Tracker PostgreSQL, Coolify PostgreSQL, Obsidian CouchDB, Coolify konfigürasyonu, gerekli şifreleme anahtarları, Traefik ACME storage ve gerekli tunnel/servis yapılandırmaları. Sunucu dışında şifreli kopya, retention, erişim kontrolü ve izole ortamda restore testi planlanmalı. Backup servisi var diye otomatik olarak sağlıklı backup varsayma. Gizli anahtarları açık metin yedek/raporlara koyma.
