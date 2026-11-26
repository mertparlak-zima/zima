# TLS, origin sertifikaları ve yenileme

Traefik ACME DNS-01, origin sertifika bitiş tarihleri, aylık kontrol ve arıza araştırması.

Belge indeksi: [README.md](README.md) · Kaynak bölüm numaraları korunmuştur (bkz. indeksteki harita).

## 7. TLS, origin sertifikaları ve yenileme

Cloudflare edge sertifikası ile Traefik'in origin sertifikası ayrı katmanlardır. Full (strict), doğrudan proxied origin HTTPS bağlantısında sertifika doğrulaması gerektirir. Tunnel servislerinde origin protokolü ve sertifika doğrulama seçenekleri ayrıca kontrol edilir; yalnızca zone SSL moduna bakarak tunnel'ın iç TLS ayarı çıkarılamaz.

Son Traefik komut çıktısı:

```text
--certificatesresolvers.letsencrypt.acme.dnschallenge.provider=cloudflare
--certificatesresolvers.letsencrypt.acme.storage=/traefik/acme.json
```

**Önemli:** Geçmiş kurulumda HTTP-01 kullanılmış olsa da güncel doğrulama DNS-01'dir. HTTP-01 için TCP 80 gerekli olabilirdi; şu an ACME DNS challenge kullandığımız için port 80'i açmaya gerek yok. Cloudflare DNS API yetkilerinin geçerliliği, DNS çözümleme ve ACME storage kalıcılığı yenileme için önemlidir.

| Origin hostname | Issuer | Başlangıç UTC | Bitiş UTC |
|---|---|---|---|
| admin.zimastack.com | Cloudflare Origin SSL CA | 18.11.2026 21:18 | 14.11.2041 21:18 |
| coinbot.zimastack.com | Let's Encrypt YR2 | 19.11.2026 15:13:52 | 17.02.2027 15:13:51 |
| coin-tracker.zimastack.com | Let's Encrypt YR1 | 23.11.2026 08:29:51 | 21.02.2027 08:29:50 |
| notes.zimastack.com | Let's Encrypt YR2 | 18.11.2026 21:11:08 | 16.02.2027 21:11:07 |

Bunlar `127.0.0.1:443` üzerinden SNI ile Traefik'ten okundu; Cloudflare edge sertifikalarının bitiş tarihi değildir. Cloudflare Origin CA sertifikası public browser trust store'unda doğrudan güvenilir olmak zorunda değildir. 2041 tarihli uzun ömürlü sertifika için Let's Encrypt otomatik renewal bekleme.

Son 168 saat proxy container loglarında `acme|renew|certificate|challenge` eşleşmesi çıkmadı. Bu, gözlenen loglarda sorun olmadığını gösterir; başarılı renewal kanıtı değildir. Let's Encrypt sertifikaları henüz ilk geçerlilik döneminde. Ocak sonu/Şubat başı 2027 bakımında yenileme olup olmadığını özellikle kontrol et; 30 gün altında kalan sertifikalarda dikkat, 14 gün altında acil inceleme. Traefik sürümünün renewal davranışı ve sertifika süresine göre kesin yenileme tarihini varsayma.

```bash
# DNS-01 ayarı sadece değişiklik/arıza halinde tekrar okunur.
sudo docker inspect coolify-proxy --format '{{range .Config.Cmd}}{{println .}}{{end}}' | grep -Ei 'acme.*(challenge|storage)'

# Aylık sertifika kontrolü; sadece public sertifika verisi.
for sub in admin coinbot coin-tracker notes; do
  echo "=== $sub.zimastack.com ==="
  timeout 10 openssl s_client -connect 127.0.0.1:443 \
    -servername "$sub.zimastack.com" </dev/null 2>/dev/null \
    | openssl x509 -noout -issuer -dates -ext subjectAltName
done

# Hata / renewal araştırması
sudo docker logs --since 168h coolify-proxy 2>&1 \
  | grep -Ei 'acme|renew|certificate|challenge' | tail -50
```

`acme.json` private key içerebilir; dosyanın ham içeriğini paylaşma. Yenileme arızasında önce API token'ın scope/geçerliliğini, DNS TXT challenge'ı, proxy loglarını ve storage erişimini incele. ACME storage'ı silmek, sertifikaları zorla tekrar üretmek veya firewall'da port açmak ilk çözüm değildir.
