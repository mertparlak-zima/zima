# Kaynak ve doğrulama notları

Runbook konsolidasyonunun dayandığı kaynaklar ve resmi referanslar.

Belge indeksi: [README.md](README.md) · Kaynak bölüm numaraları korunmuştur (bkz. indeksteki harita).

## 17. Kaynak ve doğrulama notları

Bu belge, 26 Kasım 2026 tarihli güvenlik/bakım konuşmasının ve kullanıcının paylaştığı gerçek komut çıktılarının konsolidasyonudur. Yeni bir canlı VPS, Cloudflare API veya bağımsız dış ağ taraması yapılmadı. SSH bağlantı adetleri orijinal metin dosyasından tekrar sayıldı; HTTP host/status toplamları 32.197 ile tutarlı. WAF expression şablonu ile gerçekten deploy edilen kural ayrımı özellikle korunmuştur. Önerilen yeni bakım script'leri geçmiş işlemlerin birebir kopyası değildir.

İncelenen kaynaklar:

- `Yapıştırılan metin(2).txt`: başarılı SSH bağlantıları (108 kayıt).
- `Yapıştırılan metin(3).txt`: ilk APT update mirror hatası ve upgrade simülasyonu.
- `image(20261126-091933).png`: Contabo inbound firewall kuralları.
- `image(20261126-094749).png`: Cloudflare Security rules ve Free plan kural limitleri (ilk durum).
- `image(20261126-094811).png`: dört aktif proxied DNS kaydı.
- `image(20261126-101832).png`: DNSSEC Pending, otomatik DS kaydı ve nameserver'lar.
- Sohbetteki SSH/iptables/Docker/Traefik/log/port testleri, upgrade-reboot çıktıları ve Cloudflare MCP agent raporu.

Gelecekte özellik, plan veya API değişikliği gerektiğinde kontrol edilecek resmi referanslar (bu konsolidasyon sırasında yeniden web araştırması yapılmadı):

- [Cloudflare WAF](https://developers.cloudflare.com/waf/)
- [Cloudflare Custom Rules](https://developers.cloudflare.com/waf/custom-rules/)
- [Cloudflare Rate Limiting](https://developers.cloudflare.com/waf/rate-limiting-rules/)
- [Cloudflare DNSSEC](https://developers.cloudflare.com/dns/dnssec/)
- [Cloudflare IP ranges](https://www.cloudflare.com/ips/)
- [Cloudflare Access](https://developers.cloudflare.com/cloudflare-one/access-controls/)
- [Docker packet filtering and firewalls](https://docs.docker.com/engine/network/packet-filtering-firewalls/)
- [Traefik ACME](https://doc.traefik.io/traefik/https/acme/)
- [Let's Encrypt challenge types](https://letsencrypt.org/docs/challenge-types/)
- [Ubuntu automatic updates](https://documentation.ubuntu.com/server/how-to/software/automatic-updates/)

---
**Son durum:** 26 Kasım 2026 itibarıyla temel VPS güvenlik ve bakım denetimi tamamlandı; açık doğrulamalar ve bilinçli ertelemeler bölüm 14'te listelendi. Normal bakımda bölüm 10 ile ilerle.
