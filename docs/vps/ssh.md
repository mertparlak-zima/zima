# SSH güvenlik baseline

sshd ayarları, yetkili anahtarlar, ssh.socket ve yeniden doğrulama komutları.

Belge indeksi: [README.md](README.md) · Kaynak bölüm numaraları korunmuştur (bkz. indeksteki harita).

## 5. SSH güvenlik baseline

`sudo sshd -T` çıktısında doğrulanan ayarlar:

```text
maxauthtries 6
permitrootlogin without-password
pubkeyauthentication yes
passwordauthentication no
kbdinteractiveauthentication no
permitemptypasswords no
authenticationmethods any
```

`without-password`, `prohibit-password` ile eşdeğer tarihsel isimdir. Root için parola ile giriş kapalıdır, public-key girişi mümkün. `authenticationmethods any` tek başına key-only zorlaması değildir; yukarıdaki etkin auth seçenekleri ve gözlemlenen bağlantılar birlikte değerlendirilir. `Match` blokları veya auth yapılandırması değişirse ilgili kullanıcı/adres bağlamında `sshd -T -C ...` ile yeniden kontrol et.

### 5.1 Yetkili anahtarlar

| Kullanıcı | Anahtar etiketi | Fingerprint |
|---|---|---|
| `root` | `coolify` | `SHA256:MM31l5pDgK8RV2ltKJOPfnVhj/EcsR9bBrBaM/8xKzo` |
| `mertpc` | `mertp@Zima` | `SHA256:+Zq+mOSMJgvW4TIEMBii0PBgCLqdV3k56Q65df7mZ/4` |

- `root` SSH erişimini doğrudan kapatma: Coolify yönetim işlemleri bu anahtarı kullanıyor.
- Kişisel private key Windows tarafında `~/.ssh/id_ed25519`; reboot sonrası bağlantıda key passphrase istendi. Bu, sunucuda parola ile SSH girişi değildir.
- `sudo` parolası ayrı bir mekanizmadır.
- Ev IP'si değişirse Contabo panelindeki allowlist'i güncelle. SSH kuralını Any/0.0.0.0/0 yaparak geçici çözüm üretme.
- SSH değişikliği yapılacaksa mevcut oturumu kapatmadan config'i `sudo sshd -t` ile doğrula; ayrı bir oturumdan bağlantıyı test et. Contabo konsol/kurtarma erişimini hazır tut.

### 5.2 Ubuntu 24.04 socket activation

`ssh.service` disabled görünüyordu; buna karşılık `ssh.socket` enabled/active. Bu normaldir. Açılışta socket SSH'yi dinler; `ssh.service`'i gereksiz yere enable etme.

```bash
systemctl is-enabled ssh.socket
systemctl is-active ssh.socket
```

Beklenen: enabled / active. Docker, containerd, cloudflared da enabled ve reboot sonrası active olarak doğrulandı.

### 5.3 İhtiyaç halinde yeniden doğrulama

```bash
sudo sshd -T | grep -E 'passwordauthentication|pubkeyauthentication|permitrootlogin|kbdinteractiveauthentication|permitemptypasswords|maxauthtries|authenticationmethods'
sudo ssh-keygen -lf /root/.ssh/authorized_keys
ssh-keygen -lf ~/.ssh/authorized_keys
echo "$SSH_CONNECTION"
sudo docker inspect coolify --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
```

Son Coolify IP'si `10.0.1.5`. Docker iç IP'leri değişebilir; eski IP'yi tek başına allow/deny sebebi yapma, fingerprint'i de eşleştir.

Fail2Ban kurulu değil. Şifreli giriş kapalı ve SSH IP allowlist mevcut olduğundan düşük öncelik. SSH daha geniş kaynaklara açılırsa veya yeni bir tehdit oluşursa tekrar değerlendir.
