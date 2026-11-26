# Dersler, prensipler ve bakım kayıt şablonu

Güvenlik prensipleri, her bakım için kayıt şablonu ve agent talimatı.

Belge indeksi: [README.md](README.md) · Kaynak bölüm numaraları korunmuştur (bkz. indeksteki harita).

## 15. Çıkarılan dersler ve güvenlik prensipleri

1. Host üzerinde `LISTEN` veya Docker publish görünmesi, portun internetten erişilebilir olduğunu ispatlamaz. Upstream firewall ve harici istemci testi gerekir.
2. UFW inactive, hiçbir firewall olmadığı anlamına gelmez; Contabo firewall ayrı bir katmandır. Docker'ın UFW bypass davranışı ayrıca hesaba katılmalıdır.
3. SSH password auth ile sudo parolası ve private key passphrase farklıdır. Coolify root key erişimi gerekli; root SSH'yi körlemesine kapatma.
4. Ubuntu 24.04'te `ssh.service` disabled olabilir; `ssh.socket` enabled/active ise socket activation normaldir.
5. Firewall öncesinde düşürülen bağlantılar SSH loglarına düşmeyebilir. Sıfır log eşleşmesi sıfır saldırı denemesi demek değildir.
6. HTTP tarama imzaları false positive üretir. `/svgs/phpmyadmin.svg` örneğinde normal statik dosya isteği saldırı sanıldı. 2xx yanıtlarını bağlamla incele; 401/403/404 de tek başına tam güvenlik kanıtı değildir.
7. Cloudflare WAF edge'de çalışır; engellenen trafik VPS loglarında görünmeyebilir. Cloudflare Security Events ile origin logları birbirini tamamlar.
8. Tunnel, Access, WAF, DNSSEC ve TLS farklı problemleri çözer. Birinin aktif olması diğerinin sağlandığını göstermez.
9. DNS-01 ACME challenge, mevcut kapalı 80 portu ile uyumludur. HTTP-01 bilgisi eski yapılandırmaya aittir. Origin sertifikasını edge sertifikasıyla karıştırma.
10. Otomatik Ubuntu security upgrade kernel'i diske kurabilir ancak reboot olmadan yeni kernel çalışmaz. `uname -r` ve reboot-required ile karar ver.
11. APT mirror hash/size uyuşmazlığında tekrar dene; doğrulama mekanizmasını bypass etme. Phased update normal bir dağıtım mekanizmasıdır.
12. Restart policy, otomatik container açılışını sağlar; healthcheck, readiness ve uygulama davranışı yine test edilmelidir. Exited (0) migration normaldir.
13. IPv6 bağlantısı olmayan istemciden negatif port testi, IPv6 firewall doğrulaması değildir. TCP testi UDP'yi kapsamaz.
14. Free plan limitlerini verimli kullan: az ve hedefli WAF kuralı, gereksiz kalıcı IP ban yok, API'leri bozan global challenge yok.
15. Bakım sırasında sürüm yükseltmelerini birbirinden ayır: host paketleri, OS major upgrade, Docker image, Coolify ve DB migration aynı işlem değildir.
16. Güvenlik değişiklikleri küçük, ölçülebilir ve rollback edilebilir olsun. Çalışan sisteme sırf ekstra güvenlik olsun diye geniş kapsamlı ayar ekleme.
17. Sağlık kontrolü yedekleme değildir. Sağlıklı container ve normal HTTP kodları, verinin kurtarılabilir olduğunu kanıtlamaz.

## 16. Sonraki bakım için kayıt şablonu

Her bakımda aşağıdaki bölümü kopyalayıp tarihli bir kayıt ekle. Eski değerleri silmek yerine değişiklik geçmişi tut. Bu dosya tek kaynak olarak kullanılmalı, ancak canlı çıktıyla çelişirse canlı durum esas alınmalı.

```markdown
### Bakım — YYYY-MM-DD
- Bakım nedeni:
- Değişen servis/konfigürasyon var mı?:
- Önceki kernel / yeni kernel:
- Docker / cloudflared / Coolify sürümleri:
- APT simülasyonu (upgrade/new/remove/held):
- Uygulanan işlemler:
- Reboot gerekli miydi / yapıldı mı?:
- Failed unit sayısı:
- Container durumu (running/healthy/unhealthy/exited):
- Domain smoke test sonuçları:
- Şüpheli SSH / HTTP log özeti (zaman aralığı):
- Sertifika ve DNSSEC durumu (kontrol edildiyse):
- Yeni risk / açık konu:
- Yedek durumu / risk kabulü:
- Rollback gereksinimi:
- Sonuç: SUCCESS / PARTIAL / FAILED
```

### AI agent'a veya sonraki ChatGPT sohbetine verilecek kısa talimat

> Bu belge 26.11.2026 tarihli ZimaStack VPS güvenlik baseline'ıdır. Önce bölüm 10'daki rutin preflight ile mevcut durumu kontrol et. SSH, firewall, DNS, WAF, ACME ve restart policy ayarlarını yalnızca değişiklik veya sorun tespit edilirse tekrar denetle. Açık konuların durumu bölüm 14'te. Çalışan servisleri bozacak, ücret yaratacak, erişimi kilitleyecek veya veri silecek işlemleri otomatik yapma. Normal güncellemede APT simülasyonu → kontrollü upgrade → yalnızca gerekirse reboot → postflight ve uygulama smoke testi sırasını izle. Log ve API verilerinde gizli bilgileri paylaşma. Yapılan değişiklikleri tarihli kayıtla belgeye ekle. Yapılmayan veya doğrulanamayan işlemleri açıkça belirt.
