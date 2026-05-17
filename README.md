# BLACKOUT

Godot 4 ile geliştirilen 2D top-down **survival-horror / stealth** prototipi. Karanlık bir araştırma tesisinde, sınırlı kaynaklarla hayatta kalıp çıkışa ulaşmayı hedeflersiniz.

## Proje Özeti
- **Motor:** Godot 4.x (proje ayarı: 4.6)
- **Perspektif:** 2D Top-Down
- **Tür:** Survival-Horror / Stealth
- **Kapsam:** Tek seviyeli oynanabilir prototip

## Oynanış Özellikleri
- **El feneri + pil sistemi:** Fener pil tüketir, düşük pilde titreme başlar.
- **Stealth & görünürlük:** Eğilme, koşma ve fener kullanımı algılanmayı etkiler.
- **Gürültü sistemi:** Koşma/ateş etme gibi eylemler düşmanları çeker.
- **Düşman AI:** Devriye, şüphelenme, araştırma, kovalamaca ve saldırı durumları.
- **Sınırlı kaynaklar:** Pil, mermi ve sağlık kitleriyle hayatta kalma baskısı.
- **Etkileşimler:** Saklanma noktaları, notlar ve çıkış kapısı (ID kart ister).

## Kontroller
- **W/A/S/D:** Hareket
- **Shift:** Koşma
- **Ctrl:** Eğilme
- **Space:** Dash
- **F:** El feneri aç/kapat
- **E:** Etkileşim (eşya toplama, saklanma, not okuma)
- **Sol Tık:** Ateş et
- **Esc:** Duraklat / menü

## Kurulum ve Çalıştırma
1. Godot 4.6 (veya 4.x) kurun.
2. Projeyi açın: `project.godot`
3. **Main Scene** olarak `res://scenes/main.tscn` çalıştırılır.

## Proje Yapısı (Özet)
```
assets/      # Sprites, sesler, fontlar ve placeholder içerikler
scenes/      # Godot sahneleri (level, UI, player, enemy, items)
scripts/     # Oyun mantığı (player, enemy AI, items, systems, UI)
```

## Asset ve Görsel Notları
- Placeholder görsellerin bazıları **procedural** olarak üretilir (`scripts/systems/prototype_art.gd`).
- Asset yerleşimi için: `assets/ASSET_REHBERI.md`
- Önizleme sanat kaynakları için: `assets/external/README_assets.md`

## Durum
Bu repo **Prototype I** kapsamındadır. Hedef, tek bir seviye üzerinde temel mekanikleri test etmek ve playtest geri bildirimi toplamaktır.
