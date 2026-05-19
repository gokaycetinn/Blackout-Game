# 🎮 Blackout — Bölüm 2: Yenilikçi Fikirler

> Mevcut oyun analizi üzerine inşa edilmiş, hikaye bütünlüğünü koruyan yaratıcı konseptler.

---

## 📋 Mevcut Oyun Özeti (Bölüm 1)

| Özellik | Detay |
|---|---|
| **Mekan** | Sublevel-7, yeraltı genetik araştırma tesisi |
| **Hikaye** | Project AETHER — gen düzenleme deneyleri, kaçış |
| **Düşmanlar** | Creature (patrolu, FOV, ranged+melee), Moth Creature (ışığa duyarlı) |
| **Mekanikler** | Fener, gizlenme, dash, silah, ID kart toplama, notlar |
| **Çıkış** | ID kart bul → çıkış kapısı |
| **Atmosfer** | Karanlık, sci-fi tesisi, kablolar, bilgisayarlar, kan lekeleri |

---

## 🏗️ Bölüm 2 Konsepti: **"SUBLEVEL-12: The Hive"**

> *"Sublevel-7'den kaçtın. Ama asansör bozuldu ve seni daha derine — Sublevel-12'ye — düşürdü. Burası yaratıkların kökeninin, projenin kalbinin bulunduğu yer. Ve burada, onlar ev sahibi."*

### Hikaye Bağlantısı
Bölüm 1'deki notlarda bahsedilen **Project AETHER** burada somutlaşıyor. Oyuncu asansör kazasıyla daha derin bir kata düşer. Amaç: ana jeneratörü yeniden çalıştırıp yüzey asansörüne ulaşmak.

---

## 💡 Ana Yenilikçi Fikirler

### 1. 🌊 **Su Basan Bölgeler — Dinamik Çevre Tehlikesi**

Sublevel-12 kısmen su basmış bir kat. Bu sadece görsel değil, **mekanik bir değişiklik**:

```
Mekanik Detaylar:
├── Suda yürüme → hız %40 düşer
├── Suda koşma → çok gürültü (splash sound, noise radius 2x)  
├── Suda eğilme → MÜMKÜN DEĞİL (su seviyesi göğüse kadar)
├── Elektrik panelleri + su = INSTANT DEATH bölgeleri
│   └── Oyuncu kablo/paneli kapatmak için bulmaca çözmeli
├── Bazı yaratıklar suda DAHA HIZLI hareket eder
└── Fener suya düşerse → 3 saniye çalışmaz (short circuit)
```

> [!TIP]
> Bu mekanik, Bölüm 1'deki "yavaş ve sessiz hareket et" felsefesini tamamen alt-üst eder. Oyuncu **su bölgelerinde mecburen gürültü yapar** — bu da yeni stratejiler gerektirir.

**Görsel:** Su, hafif yansımalı mavi-yeşil bir katman olarak render edilir. PointLight2D ile su yüzeyinde ışık kırılmaları.

---

### 2. 👂 **Yeni Düşman: "The Siren" — Ses Tabanlı Avcı**

Bölüm 1'deki düşmanlar **görsel algıya** dayanıyordu. Bölüm 2 tamamen yeni bir tehdit sunuyor:

```
THE SIREN — Ses Avcısı
├── KÖRDÜR — FOV coni yok, oyuncuyu göremez
├── Ses dalgalarıyla avlanır:
│   └── Yürüme → algılar (yavaş yaklaşır)
│   └── Koşma → kesin algılar (direkt chase)
│   └── Silah sesi → HARİTANIN HER YERİNDEN algılar
│   └── Durma → TAMAMEN GÖRÜNMEZSİN
├── Kendisi ultrasonik ses çıkarır (görsel ripple efekti)
│   └── Echolocation — duvarlardan yansıyan dalgalarla "görür"
├── Fener açma → sessiz → Siren'i etkilemez
│   (Moth'un tam tersi — stratejik zıtlık!)
├── Öldürülemez — sadece kaçılabilir veya dikkat dağıtılabilir
│   └── "Noise Maker" item: atılabilir ses kaynağı
│   └── Çevreden düşen objeler ses çıkarır
└── Görsel: Solgun, uzun, insansı siluet. Başı olmayan bir gövde.
    Titreşen hava dalgaları (shader efekti)
```

> [!IMPORTANT]
> Siren, oyuncuyu **DURMAYI** öğrenmeye zorlar. Bölüm 1'de hep hareket ettin. Bölüm 2'de bazen **tamamen hareketsiz kalmak** hayat kurtarır.

**Dikkat Dağıtma Mekaniği:**
- Yeni item: **"Ses Tuzağı" (Noise Decoy)** — atılabilir, 5 saniye boyunca ses çıkarır
- Çevredeki nesnelere ateş ederek dikkat çekilebilir (ama silah sesi de Siren'i çeker!)
- Su bölgelerinde taş atma mekaniği (sağ tık)

---

### 3. 🔄 **Karanlık/Aydınlık Döngüsü — Jeneratör Mekaniği**

Bölüm 2'nin çekirdek bulmacası:

```
ANA MEKANIK: Güç Döngüsü
├── Harita başlangıçta TAMAMEN karanlık (Bölüm 1'den daha karanlık)
├── 3 alt-jeneratör bulunur haritada
│   └── Her biri aktive edilince bir BÖLGE aydınlanır
│   └── Ama aydınlık bölgeler Moth'ları ÇILDIRIR
│   └── Ve aydınlık bölgelerde Creature'lar daha iyi görür
├── Jeneratörler arası kablolama bulmacası:
│   └── Doğru kabloları bağla → jeneratör çalışır
│   └── Yanlış bağlantı → kısa devre → tüm ışıklar söner + alarm
├── Ana jeneratör (çıkış) 3 alt-jeneratörü gerektirir
└── TRADE-OFF: Aydınlık = güvenli yol ama düşmanları güçlendiriyor
            Karanlık = gizli ama navigasyon zor
```

> [!WARNING]
> Bu mekanik, oyuncuyu **zorlu bir seçimle** karşı karşıya bırakır. Işık açmak mı yoksa karanlıkta kalmak mı? Her ikisinin de bedeli var.

**Mini-Bulmaca Sistemi:**
Jeneratörlerde basit bir kablo-bağlama puzzle'ı. 4 kablonun doğru terminallere bağlanması gerekir. Yanlış bağlantı → alarm + tüm düşmanlar oyuncunun konumuna koşar.

---

### 4. 🧬 **Yeni Yaratık: "The Mimic" — Aldatıcı Düşman**

En yaratıcı ve **korkutucu** fikir:

```
THE MIMIC
├── Normal bir ITEM gibi görünür (batarya, mermi, medkit)
├── Oyuncu yaklaştığında → CANLANIR ve saldırır
├── Nasıl ayırt edilir?
│   └── Fenerle aydınlatınca hafif TİTREŞİR
│   └── Gerçek itemlerin aksine hafif bir "nefes alıp verme" animasyonu var
│   └── Farkına varmak DİKKAT gerektirir
├── Saldırı: Hızlı atılma + zehir hasarı (2 saniye boyunca yavaşlama)
├── Hasar alınca → gerçek formuna dönüşür (örümceksi, iğrenç)
├── 1 HP — kolay öldürülür ama panik yarattığında tehlikeli
└── Sadece belirli odalarda bulunur (her item Mimic değil!)
```

> [!CAUTION]
> Bu mekanik, oyuncunun **her iteme güvenmesini** ortadan kaldırır. Paranoya yaratır — tam bir korku oyunu elementi.

---

### 5. 🗺️ **Çevresel Bulmacalar ve Keşif Sistemi**

Bölüm 1'de çıkış basitti: ID kart bul → kapı aç. Bölüm 2 daha katmanlı:

```
İlerleme Sistemi:
├── AŞAMA 1: Haritayı keşfet, 3 alt-jeneratörü bul
├── AŞAMA 2: Her jeneratöre ulaşmak için engelleri aş
│   ├── Jeneratör A: Su basan koridordan geç (elektrik tehlikesi)
│   ├── Jeneratör B: Siren'in dolaştığı sessiz bölgeden geç
│   └── Jeneratör C: Moth yuvasının içinden geç (tamamen karanlıkta)
├── AŞAMA 3: Ana jeneratörü çalıştır (tüm 3 alt-jeneratör gerekli)
│   └── Bu tüm ışıkları açar — ALARM tetiklenir
│   └── "ESCAPE SEQUENCE" başlar
└── AŞAMA 4: 60 saniyelik kaçış sekansı
    └── Tüm düşmanlar agresif
    └── Harita boyunca koşarak asansöre ulaş
    └── Kapılar otomatik açılır ama arkadan düşmanlar gelir
```

**Yeni Etkileşimler:**
- **Havalandırma Kanalları**: Küçük boşluklardan sürünerek geçiş (gizlenme + kısayol)
- **Kilitli Kapılar**: Farklı renk kodlu kartlarla açılır (Kırmızı, Mavi, Sarı)
- **Bilgisayar Terminalleri**: Harita bilgisi / düşman patrolu gösterir (kısa süreli)
- **Kimyasal Tanklar**: Ateş edilince patlıyor (çevre hasarı + alan kontrolü)

---

### 6. 🐛 **Boss Encounter: "The Queen" — Son Karşılaşma**

Ana jeneratör çalıştırıldığında ortaya çıkan dev yaratık:

```
THE QUEEN — Final Boss
├── Kaçış sekansı sırasında karşılaşılır (tam savaş değil)
├── Dev boyutlu (ekranın 1/4'ü kadar)
├── Öldürülemez — sadece yavaşlatılabilir
│   └── Çevredeki patlayıcı varillere ateş et → Queen sendeliyor
│   └── Işık kaynakları Queen'i kısa süre durdurur
├── Queen koridorlarda oyuncuyu kovalıyor
│   └── Duvarları YIKIYOR (yol açıyor ama tehlikeli)
│   └── Düşmanları eziyor (dolaylı yardım)
├── Asansöre ulaştığında → kapılar kapanır → Queen dışarıda kalır
└── Final cutscene: Asansör yukarı çıkarken Queen'in çığlığı
```

---

## 🎨 Atmosfer ve Görsel Farklılıklar

| Bölüm 1 | Bölüm 2 |
|---|---|
| Sci-fi tesisi, temiz ama terk edilmiş | Organik + mekanik, biyolojik büyümeler |
| Mavi/beyaz ışıklar | Yeşil/amber acil durum ışıkları |
| Bilgisayar ekranları | Kırık ekranlar, organik dokular |
| Düz koridorlar | Sular, yıkılmış duvarlar, doğal mağara |
| Notlar masa üstünde | Notlar duvara kan ile yazılmış |
| Sakin ambiyans | Damlayan su, uzak çığlıklar, mekanik inleme |

**Yeni Müzik:** Daha derin, basınçlı, sualtı hissi veren ambiyans. Su damlama SFX.

---

## 🎯 Harita Düzeni Önerisi

```
+==========================================+
|  [A] GİRİŞ        |    [D] MOTH YUVASI  |
|  (Asansör kazası)  |    (Jeneratör C)    |
|  Başlangıç noktası |    Tamamen karanlık  |
|----+      +--------+----+      +---------|
|    |      |   SU BASAN   |      |        |
| [B]| KOR. | KORİDOR      | KOR. |  [E]   |
|HAV.|      | (Elektrik    |      | SIREN  |
|KAN.|      |  tehlikesi)  |      | BÖLGESİ|
|LARI|      |              |      |(Jen.B) |
|----+      +----+    +----+      +---------|
|                |    |                     |
|  [C] LABORATUVAR   |  [F] ANA JENERATÖR  |
|  (Mimic'ler)        |  + QUEEN ARENA      |
|  (Jeneratör A)      |  + ASANSÖR (ÇIKIŞ)  |
+==========================================+
```

---

## 🔧 Teknik Uygulama Notları

### Yeniden Kullanılabilir Mevcut Sistemler:
- ✅ `creature.gd` — Patrol/Chase mantığı aynen kullanılabilir
- ✅ `moth_creature.gd` — Bölüm 2'de de var, yuva olarak yoğun
- ✅ `note.gd` — Hikaye devamı için
- ✅ `hiding_spot.gd`, `door.gd`, `door_exit.gd`
- ✅ `game_manager.gd` — `request_level_complete()` zaten var

### Yeni Yazılması Gereken:
- 📝 `siren.gd` — Ses tabanlı algılama, echolocation
- 📝 `mimic.gd` — Item taklit eden düşman
- 📝 `queen.gd` — Boss, pathfinding, duvar yıkma
- 📝 `generator.gd` — Jeneratör bulmaca sistemi
- 📝 `water_zone.gd` — Su bölgesi fizik/ses modifiyesi
- 📝 `noise_decoy.gd` — Atılabilir ses tuzağı
- 📝 `vent.gd` — Havalandırma kanalı geçişi
- 📝 `explosive_barrel.gd` — Patlayıcı varil
- 📝 `level_02.gd` — Ana seviye scripti

### GameManager Güncellemeleri:
- `current_level: int` değişkeni eklenmeli
- `start_game()` → seviye seçimi desteği
- `signal escape_sequence_started` eklenmeli
- `signal generator_activated(index: int)` eklenmeli

---

## 🗳️ Hangisini Tercih Edersin?

Yukarıdaki fikirlerin hepsini yapmak büyük bir iş. Sana önerim:

1. **Minimum Viable Bölüm 2:** Yeni harita + Siren düşmanı + Jeneratör mekaniği
2. **Orta Kapsamlı:** + Su bölgeleri + Mimic düşmanı + Kaçış sekansı  
3. **Tam Paket:** Yukarıdakilerin hepsi + Queen boss + Havalandırma kanalları

> **Hangisini yapmak istersin? Ya da bu fikirlerden hangilerini beğendin/değiştirmek istersin?**
