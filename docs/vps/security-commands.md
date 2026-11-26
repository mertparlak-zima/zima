# Tekrar kullanılabilir güvenlik kontrol komutları

Haftalık SSH kontrolü, Cloudflare olay kontrolü, Traefik log analiz scripti ve tam port/firewall denetimi.

Belge indeksi: [README.md](README.md) · Kaynak bölüm numaraları korunmuştur (bkz. indeksteki harita).

## 12. Tekrar kullanılabilir güvenlik kontrol komutları

### 12.1 Haftalık kısa SSH kontrolü

```bash
# Şüpheli auth kayıtları (firewall öncesinde düşürülen paketleri göstermez)
sudo journalctl -u ssh --since '7 days ago' --no-pager \
  | grep -Ei 'preauth|failed|invalid user|authentication failure|unable to negotiate|maximum authentication' \
  | tail -50

# Başarılı bağlantıları kullanıcı, kaynak IP, auth türü ve fingerprint ile grupla
sudo journalctl -u ssh --since '7 days ago' --no-pager \
  | awk '/Accepted / {print $7, $9, $11, $NF}' \
  | sort | uniq -c | sort -nr
```

İkinci komut standart syslog satır biçimine bağlıdır; tarih biçimi değişirse ham kayıtları `grep 'Accepted '` ile incele. Kayıt yoksa journal retention ve ilgili zaman aralığının kapsandığını kontrol et. Root için bilinen Coolify fingerprint'i ve kişisel key dışındaki başarılı bağlantılar araştırılmalı.

### 12.2 Cloudflare haftalık olay kontrolü

Security Events'te son 7 gün veya panelin izin verdiği zaman aralığına bak: Block action, WAF rule ID, hostname, URI path, kaynak, zaman ve istek artışı. Free plan analitiği örneklemeli olabilir, toplamın kesin olduğunu varsayma. WAF'ın edge'de engellediği istekler Traefik loglarına ulaşmaz; bu yüzden Traefik'teki düşüş saldırı denemelerinin tamamen bittiğini göstermez.

### 12.3 Gerektiğinde Traefik log analizi (geliştirilmiş yerel script)

Bu script 26 Kasım'daki script'in yeniden kullanılabilir versiyonudur; varsayılan son 7 gün ve hem plain/gzip logları kapsar. `.env`, `.git`, PHP, WordPress, yönetim panelleri, path traversal, SQLi ve XSS gibi temel imzaları kontrol eder. Bilinen Coolify SVG isteğini sadece ilgili hostname, GET, 200 ve 862 byte ile eşleştiğinde false positive olarak ayırır; gelecekte dosya boyutu değişirse yeniden incelenebilir. Kalan eşleşmelerin status dağılımını tekil istek bazında verir. İstek body'lerini veya tüm exploit çeşitlerini kapsamaz. Şüpheli 2xx/3xx detaylarında query ve raw path yazdırmaz; dinamik URL içinde bile gizli veri olabileceğinden çıktı paylaşmadan önce incele. Bu geliştirilmiş script konuşmadaki önceki script'in aynısı değil; bu belge için hazırlandı, VPS üzerinde çalıştırılmadı.

```bash
sudo python3 - <<'PY'
import json, gzip, glob, re
from collections import Counter
from datetime import datetime, timezone, timedelta
from urllib.parse import unquote

DAYS = 7
cutoff = datetime.now(timezone.utc) - timedelta(days=DAYS)
patterns = {
    'ENV': r'/\.env',
    'Git': r'/\.git',
    'WordPress': r'wp-admin|wp-login|wp-content|wp-includes|xmlrpc\.php',
    'PHP': r'\.php(?:$|/|\?)',
    'Path traversal': r'\.\./',
    'SQL injection': r'union\s+select|sleep\s*\(|information_schema',
    'XSS': r'<script|javascript:|onerror\s*=',
    'Yonetim paneli': r'phpmyadmin|adminer|/actuator',
    'Hassas dosya': r'/etc/passwd|/\.ssh|/\.aws',
}
patterns = {k: re.compile(v, re.I) for k, v in patterns.items()}
statuses, hosts, hits, hit_status, ips = (Counter() for _ in range(5))
total = invalid = false_positive = suspicious = skipped_date = 0
interesting = []
first = last = None

for filename in sorted(glob.glob('/data/coolify/proxy/access.log*')):
    if not re.fullmatch(r'.*/access\.log(?:\.\d+)?(?:\.gz)?', filename):
        continue
    opener = gzip.open if filename.endswith('.gz') else open
    try:
        with opener(filename, 'rt', errors='replace') as f:
            for line in f:
                try:
                    d = json.loads(line)
                except ValueError:
                    invalid += 1
                    continue
                try:
                    ts = datetime.fromisoformat(d['StartUTC'].replace('Z', '+00:00'))
                    if ts.tzinfo is None:
                        raise ValueError('Missing timezone')
                except (ValueError, KeyError, TypeError, AttributeError):
                    skipped_date += 1
                    continue
                if ts < cutoff:
                    continue
                first = ts if first is None else min(first, ts)
                last = ts if last is None else max(last, ts)
                total += 1
                host = str(d.get('RequestHost', 'unknown'))
                status = d.get('DownstreamStatus', 0)
                path = unquote(unquote(str(d.get('RequestPath', ''))))
                method = d.get('RequestMethod')
                statuses[status] += 1
                hosts[host] += 1
                matches = [k for k, pattern in patterns.items() if pattern.search(path)]
                if not matches:
                    continue
                if (host == 'admin.zimastack.com' and path == '/svgs/phpmyadmin.svg'
                        and method == 'GET' and status == 200
                        and d.get('DownstreamContentSize') == 862):
                    false_positive += 1
                    continue
                suspicious += 1
                hit_status[status] += 1
                hits.update(matches)
                headers = {k.lower(): v for k, v in d.items()}
                ip = headers.get('request_cf-connecting-ip') or d.get('ClientHost', 'unknown')
                ips[str(ip)] += 1
                if isinstance(status, int) and 200 <= status < 400 and len(interesting) < 30:
                    interesting.append((ts.isoformat(), host, method, status,
                                        d.get('OriginStatus'), d.get('DownstreamContentSize'),
                                        ', '.join(matches)))
    except (OSError, EOFError) as exc:
        print('Log okuma hatasi:', filename, type(exc).__name__)

print('Aralik (UTC):', first, '-', last)
print('Toplam:', total, '| Supheli:', suspicious, '| False positive:', false_positive)
print('Bozuk JSON:', invalid, '| Tarihi okunamayan:', skipped_date)
print('Hostlar:', hosts.most_common())
print('HTTP status:', statuses.most_common())
print('Supheli kategoriler (coklu eslesme olabilir):', hits.most_common())
print('Supheli tekil istek HTTP status:', hit_status.most_common())
print('Supheli kaynaklar (header dogrulamasi gerekir):', ips.most_common(15))
print('Incelenecek 2xx/3xx ornekleri (max 30, path/query yok):')
for row in interesting:
    print(row)
PY
```

Bu script'in ürettiği sonuçları önceki 943 sayısı ile birebir karşılaştırma: tarih filtresi ve PHP/WordPress imzaları değişti, dolayısıyla metodoloji farkı var. Log rotation sırasında dosyanın değişmesi, eksik geçmiş kayıtlar veya gzip okuma hataları da sayıları etkileyebilir. Kritik 2xx yanıtını tek başına başarılı exploit olarak yorumlama; router, service, origin status, response türü, boyutu ve uygulama loglarıyla incele.

### 12.4 Tam port / SSH / firewall denetimi (sadece değişiklik veya olay durumunda)

```bash
sudo ss -tulnp
sudo ufw status verbose
sudo docker ps --format 'table {{.Names}}\t{{.Ports}}'
sudo iptables -S
sudo ip6tables -S
sudo nft list tables
```

Gerekirse `sudo nft list ruleset` ile tam kuralları incele; liste yalnızca tablo adlarını gösterir. SSH ayarları için bölüm 5, dış ağ testi için bölüm 4, sertifikalar için bölüm 7. Rutin bakımda hepsini tekrar tekrar çalıştırma.
