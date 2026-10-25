# Fiziksel test telefonu — kablosuz ADB erişimi

[Workspace router](../AGENTS.md) · [Runners](runners.md) · Drive-trace lane ayrıntıları: [device-test-runbook](../projects/drive-trace/docs/device-test-runbook.md)

Zima workspace'inin paylaşılan Android test telefonuna standart erişim yolu. Bu sayfa
genel prosedürdür; repo-özgü lane kuralları (temizlik guard'ı, QA paketleri, evidence
formatı) ilgili repoya aittir ve oradan okunur. Bir cihaz işlemi yapmadan önce bu sayfa
okunur.

## Cihaz ve ortam (bilinen durum)

- Telefon: OPPO **CPH2095** (A72), Android **12 / API 31**, ColorOS; kullanıcının **günlük
  cihazı**. Wi-Fi üzerinde sabit görünen adres: `192.168.1.130`.
- Host tarafında adb: `D:\development\drive-trace\android-sdk\platform-tools\adb.exe`
  (PATH'te yok; tam yol kullanılır). Aynı makinede tek adb sunucusu paylaşılır.

## Bağlantı — kablosuz öncelik (kullanıcı kararları 2026-10-14 / 2026-10-16)

1. **Birincil — kalıcı kablosuz hata ayıklama (mDNS/TLS):** telefonda Geliştirici
   seçenekleri > *Kablosuz hata ayıklama* açık. Keşif:
   `adb mdns services` → `_adb-tls-connect._tcp` kaydından `ip:port` → `adb connect <ip>:<port>`.
   Bu kanal reboot'u atlatır; **port reboot sonrası değişebilir** — her bağlanmada mDNS ile
   güncel portu keşfet, sabit port varsayma. Daha önce USB'den yetkilendirilmiş host için
   ayrıca `adb pair` gerekmez.
2. **İkincil — legacy tcpip köprüsü:** `adb connect 192.168.1.130:5555`. Reboot ile ölür;
   yalnızca köprü kurulmuşsa çalışır (kurulup kurulmadığı `adb devices` ile görünür).
3. **Tırmanma kuralı (kullanıcı kararı 2026-10-16):** kablosuz bağlanma/kurtarma en fazla
   **3 deneme / ~5 dakika** denenir; başarısızsa agent durur ve kullanıcıdan **USB kablosu
   takmasını ister** (Telegram/bildirim ya da aktif konuşma üzerinden tek cümle). Kendi
   kendine sınırsız retry yapılmaz, kabloya dokunulmaz.

## Ekran disiplini (kullanıcı kararı 2026-10-20)

- Ekran **ihtiyaç yoksa KAPALI** tutulur (yanık endişesi). Senaryo gerekiyorsa aç:
  `input keyevent 224` (+ gerekirse `wm dismiss-keyguard`); iş bitince hemen kapat:
  `input keyevent KEYCODE_SLEEP` (KEYCODE_SLEEP = 223).
- UI gerektirmeyen koşular ekran kapalı denenir; bir koşu ekran kapalıyken takılırsa
  (ColorOS freezer) o koşu için ekran açık kalır ve kanıta not edilir.
- Ekran-açık senaryolarda parlaklık düşürülür (`settings put system screen_brightness`,
  ColorOS reddederse not edilir).

## Her repoda geçerli sınırlar

- Telefon kullanıcınsı günlük cihazıdır: **başka repoların uygulamalarına, verilerine veya
  ayarlarına dokunulmaz**; `pm clear`/uninstall yalnızca o görevin kendi test paketine
  uygulanır ve reponun kuralları öyle diyorsa.
- Cihazda **prob-dışı gerçek kullanıcı verisi** varsa önce repo-local kural uygulanır
  (ör. drive-trace saha verisi guard'ı); emin olunamıyorsa veri bozabilecek iş yapılmaz.
- Test kurulumları debug/QA paket kimliği kullanır (ör. `helium314.keyboard.debug`,
  `com.drivetrace.qa`); kullanıcınsı üretim paketi hedeflenmez.
- Kullanıcı içeriği/metihi log, issue veya CI artifact'ına girmez; kanıt sentetik veriyle
  üretilir. Güvenli kilit ekranı açılamıyorsa cihaz kilidi kullanıcıya açtırılır.
- Cihazda klavye/IME gibi sistem ayarı değiştiren deneyler görev kapsamında ve geri
  alınabilir olmalı; bittiğinde eski ayara dönülür.

[Workspace router](../AGENTS.md)
