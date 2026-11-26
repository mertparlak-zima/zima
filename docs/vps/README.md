# ZimaStack — VPS Güvenlik, Altyapı ve Bakım Runbook'u

ZimaStack VPS'inin (Contabo, Ubuntu 24.04, Docker, Coolify, Traefik, Cloudflare) güvenlik, altyapı ve bakım dokümantasyonu. Üye repoların (CoinBot, Coin Tracker, Obsidian LiveSync vb.) servis edildiği sunucuyu agent'ların anlaması için kök `zimastack-vps-guvenlik-ve-bakim-runbook.md` dosyasından bölünerek taşındı (içerik değişmeden; bölüm numaraları korunur). Web servisi yayınlama akışı için [../web-services.md](../web-services.md), Cloudflare MCP erişimi için [../cloudflare.md](../cloudflare.md).

> **Son denetim:** 26 Kasım 2026 · **Sürüm:** 1.0  
> **Amaç:** Sunucunun bilinen yapılandırmasını, güvenlik kararlarını, denetim sonuçlarını ve bir sonraki bakım prosedürünü tek yerde tutmak. Her bakımda sıfırdan kurulum veya aynı uzun kontrolleri yapmamak.  
> **Kapsam:** Contabo VPS, Ubuntu, SSH, Docker, Coolify, Traefik, Cloudflare DNS/WAF/Access/Tunnel, sertifikalar, güncellemeler ve olay analizi.  
> **Gizlilik:** İç kullanım dokümanı. Gerçek IP adresleri, sunucu adı ve SSH public-key fingerprint'leri içerir. Parola, private key, API token veya tunnel token içermez. Public repository'ye koyma.

> **Agent kuralı:** Bu klasörde gerçek IP/hostname/fingerprint var; repo yalnızca private kalmalı. Gizli bilgi (token, private key, parola, `acme.json` içeriği) asla eklenmez. Canlı çıktı ile çelişirse canlı durum esastır.

## Bölüm haritası

| Bölüm | Dosya |
|---|---|
| 1. Yönetici özeti | bu dosya |
| 2-3. Envanter, mimari, DNS | [inventory-and-architecture.md](inventory-and-architecture.md) |
| 4. Contabo firewall ve portlar | [firewall-and-ports.md](firewall-and-ports.md) |
| 5. SSH baseline | [ssh.md](ssh.md) |
| 6. Cloudflare güvenlik | [cloudflare-security.md](cloudflare-security.md) |
| 7. TLS / ACME | [tls-certificates.md](tls-certificates.md) |
| 8. Docker ve Coolify | [docker-coolify.md](docker-coolify.md) |
| 9. Saldırı denetimi 26.11.2026 | [security-audit-2026-11-26.md](security-audit-2026-11-26.md) |
| 10, 11, 13. Rutin bakım, otomatik güncelleme, takvim | [maintenance.md](maintenance.md) |
| 12. Kontrol komutları / log scripti | [security-commands.md](security-commands.md) |
| 14. Açık konular, yedekleme kapsamı | [open-items.md](open-items.md) |
| 15-16. Dersler, kayıt şablonu, agent talimatı | [lessons-and-templates.md](lessons-and-templates.md) |
| 17. Kaynaklar | [sources.md](sources.md) |

Metin içindeki "bölüm N" atıfları bu haritaya göre çözülür.

## Agent hızlı talimatı

Normal bakımda önce [maintenance.md](maintenance.md) bölüm 10 preflight. SSH, firewall, DNS, WAF, ACME ve restart policy'yi yalnızca değişiklik/sorun varsa yeniden denetle. Hizmeti bozacak, ücret yaratacak, erişimi kilitleyecek veya veri silecek işlemleri otomatik yapma. Sıra: APT simülasyonu → kontrollü upgrade → gerekirse reboot → postflight + smoke test. Yapılanları [lessons-and-templates.md](lessons-and-templates.md) şablonuyla tarihli kaydet.

## 1. Yönetici özeti

26 Kasım denetiminde şifreli SSH girişinin kapalı olduğu, ED25519 anahtarlarının doğru olduğu, Contabo firewall kurallarının beklenen IPv4 TCP portlarını engellediği ve tüm çalışan Docker container'larının reboot sonrasında tekrar ayağa kalktığı doğrulandı. Ubuntu, Docker ve cloudflared güncellendi; yeni kernel devreye alındı. Cloudflare tarafında WAF tarama engeli, TLS 1.2 minimum sürümü ve HTTPS yönlendirmesi mevcut; DNSSEC başlatıldı.

- **SSH:** İncelenen 7 günlük kayıtlarda 108 başarılı public-key bağlantısı; tamamı tanımlı kişisel anahtar veya Coolify anahtarıyla uyumlu. Şüpheli SSH imza eşleşmesi: 0.
- **HTTP:** 32.197 istekten 947'si ilk taramada şüpheli; 4'ü normal Coolify SVG isteği olduğundan yanlış pozitif. Kalan 943 potansiyel zararlı istek 401/403/404 aldı. İncelenen imzalarda başarılı saldırı bulgusu yok.
- **Sistem:** Güncelleme sonrasında 15 çalışan container, 12/12 healthy, 3 healthcheck tanımsız çalışan container, 1 başarılı şekilde sonlanmış migration; failed systemd unit sayısı 0; bekleyen APT güncellemesi 0.
- **Açık kalanlar:** DNSSEC Active durumunun teyidi, IPv6 firewall doğrulaması, farklı kaynak IP'den SSH reddinin doğrulanması, WAF kuralının gerçek expression/ID kaydı, gerçek ACME yenilemesinin ileride gözlemlenmesi. Yedekleme denetimi kullanıcı kararıyla ertelendi.

**Karar:** Acil güvenlik müdahalesi gerektiren bir bulgu yok. Yeni güvenlik yazılımları veya agresif global kurallar kurmak yerine mevcut katmanları koru. Bu, sunucunun kesinlikle ele geçirilmediği anlamına gelmez; denetimin kapsamı loglar, konfigürasyon ve temel erişim testleriyle sınırlıdır.

### Durumların anlamı

| Durum | Anlamı |
|---|---|
| Doğrulandı | Kullanıcının komut çıktısı veya ekran görüntüsüyle desteklendi |
| Agent raporu | Cloudflare MCP agent'ı uyguladığını ve API'den doğruladığını bildirdi; bu doküman API'yi bağımsız sorgulamadı |
| Yapılandırıldı | Ayar mevcut, ancak gerçek olay/yenileme/geri yükleme testi tamamlanmadı |
| Bekliyor | Eksik doğrulama var |
| Ertelendi | Bilinçli olarak yapılmadı |


## Related
- [../README.md](../README.md) - [../../AGENTS.md](../../AGENTS.md) - [../web-services.md](../web-services.md) - [../cloudflare.md](../cloudflare.md)
