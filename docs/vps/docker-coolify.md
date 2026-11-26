# Docker ve Coolify işletim baseline

Container envanteri, restart policy, Docker disk baseline ve temizlik uyarıları.

Belge indeksi: [README.md](README.md) · Kaynak bölüm numaraları korunmuştur (bkz. indeksteki harita).

## 8. Docker ve Coolify işletim baseline

### 8.1 Container envanteri

Dinamik deployment suffix'leri yeni deploy ile değişebilir; bakım scriptlerinde stable prefix veya servis label'ı kullan.

| Servis / isim prefix'i | Adet | Restart policy | Son durum |
|---|---:|---|---|
| `worker-6xobfxi...` | 1 | unless-stopped | healthy |
| `api-6xobfxi...` | 1 | unless-stopped | healthy, internal 8787 |
| `postgres-6xobfxi...` | 1 | unless-stopped | healthy, internal 5432 |
| `redis-6xobfxi...` | 1 | unless-stopped | healthy, internal 6379 |
| `api-qtpavg...` | 1 | unless-stopped | healthy, internal 3000 |
| `migrate-qtpavg...` | 1 | no | Exited (0), beklenen |
| `backup-qtpavg...` | 1 | unless-stopped | running, healthcheck yok |
| `postgres-qtpavg...` | 1 | unless-stopped | healthy |
| `couchdb-yljsx...` | 1 | unless-stopped | healthy, internal 4369/5984/9100 |
| `coolify-proxy-error-pages` | 1 | unless-stopped | running, healthcheck yok |
| `coolify-proxy` | 1 | unless-stopped | healthy |
| `coolify-proxy-logrotate` | 1 | unless-stopped | running, healthcheck yok |
| `coolify` | 1 | always | healthy |
| `coolify-redis` | 1 | always | healthy |
| `coolify-db` | 1 | always | healthy |
| `coolify-sentinel` | 1 | unless-stopped | healthy |

Toplam 16 container: 12 unless-stopped, 3 always, 1 no. 15 running; 12 healthy ve 3 healthcheck tanımsız. Migration'ın durması normaldir, `docker start` ile gereksiz tekrar çalıştırma. Backup container'ının running olması, yedeklerin başarılı veya geri yüklenebilir olduğunun kanıtı değildir.

Reboot sırasında uygulamalar ve DB'ler otomatik açıldı. Restart policy, bağımlılıkların daima doğru sırada açılacağını garanti etmez; uygulamaların readiness ve retry davranışı önemlidir.

### 8.2 Docker disk baseline

| Tip | Toplam | Aktif | Boyut | Reclaimable |
|---|---:|---:|---:|---:|
| Images | 27 | 16 | 4.108 GB | 709.4 MB |
| Containers | 16 | 15 | 22.18 MB | 4.096 kB |
| Local volumes | 53 | 9 | 267.5 MB | 112.1 kB |
| Build cache | 0 | 0 | 0 | 0 |

Disk alanı bol. `docker system prune -a --volumes`, otomatik volume silme veya eski kernel temizliği gibi işlemleri sırf reclaimable alan görüldü diye çalıştırma. Bir volume'un inactive olması gereksiz olduğu anlamına gelmez.
