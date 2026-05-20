# 🌑 BLACKOUT

<div align="center">
  <img src="assets/external/kamisama/header.png" alt="Blackout Header Banner" width="100%">
  <p><i>Karanlıkta fısıldayan gölgeler, sönmek üzere olan bir fener ve derinlerden gelen ayak sesleri...</i></p>
  
  <p>
    <img src="https://img.shields.io/badge/Engine-Godot%204.x-blue?style=for-the-badge&logo=godotengine&logoColor=white" alt="Godot Engine">
    <img src="https://img.shields.io/badge/Genre-Survival%20Horror%20%2F%20Stealth-red?style=for-the-badge" alt="Genre">
    <img src="https://img.shields.io/badge/Platform-PC-orange?style=for-the-badge" alt="Platform">
  </p>
</div>

---

**BLACKOUT**, Godot 4 motoru ile geliştirilen, yüksek gerilimli bir **2D Top-Down Survival-Horror / Stealth** oyunudur. Oyuncu olarak, terk edilmiş, karanlık bir askeri araştırma tesisinde uyanan bir deneği canlandırıyorsunuz. Sınırlı kaynaklarınızla tesisin derinliklerindeki tehditlerden kaçınmalı, sistemleri yeniden aktif hale getirmeli ve tesisin en alt katında sizi bekleyen korkunç sırla (Kraliçe Örümcek) yüzleşmelisiniz.

---

## 🎮 Oynanış Videosu (Gameplay Demo)

Aşağıdaki alanda oyunumuzun atmosferik oynanış dinamiklerini, fener pil mekaniklerini ve boss savaşını gösteren **Blackout.mp4** demosunu izleyebilirsiniz:

<div align="center">
  <video src="Blackout.mp4" width="100%" controls alt="Blackout Gameplay Demo"></video>
  <p><i>(Demo videosu klasöre yüklendiğinde yukarıdaki oynatıcı üzerinden doğrudan izlenebilir olacaktır.)</i></p>
</div>

---

## 🌟 Önemli Mekanikler & Özellikler

### 🔦 Gelişmiş Aydınlatma ve Pil Yönetimi
Tesis tamamen karanlığa gömülmüştür. Tek güvenceniz olan el feneriniz sınırlı pil kapasitesine sahiptir. Pil düzeyi azaldıkça feneriniz titremeye ve kararmaya başlar. Çevreyi çok iyi araştırarak pilleri toplamanız gerekir.

### 🤫 Stealth (Gizlilik) ve Ses Algılama AI
Düşmanlar sadece sizi görmekle kalmaz, çıkardığınız sesleri de dinler:
- **Eğilerek Yürüme (Ctrl):** Ses çıkarmaz ancak hareketinizi yavaşlatır.
- **Koşma (Shift):** Hızlı hareket etmenizi sağlar fakat çok ses çıkarır ve düşmanların sizi hızla fark etmesine yol açar.
- **Ateş Etme / Çatışma:** Çevredeki tüm yaratıkları anında üzerinize çeker.

### 🔋 Güç Jeneratörleri ve İlerleme
Tesisten kaçabilmek için ana kapıları açan güç konsollarını devreye sokmalısınız. Jeneratörleri aktif etmek gürültülü bir süreçtir ve yaratıkların dikkatini çeker.

---

## 👥 Karakterler ve Düşmanlar

### 🧑‍🚀 Ana Karakter (The Inmate / Kid)
<table align="center">
  <tr>
    <td width="30%" align="center">
      <img src="assets/sci-fi-facility-asset-pack/the_kid_spritesheet.png" width="120px" alt="The Inmate"><br>
      <code>the_kid_spritesheet.png</code>
    </td>
    <td width="70%">
      <strong>Denek #404 (Oyuncu)</strong><br><br>
      Tesisin alt katlarındaki hücreden kaçmayı başaran genç bir denek. Fiziksel olarak savunmasızdır ancak hızlı refleksleri ve çevikliği sayesinde düşmanlardan sıyrılabilir.
      <ul>
        <li><strong>Yetenekler:</strong> Dash (Space) ile engellerden kaçma, sessiz yürüme, el feneri kullanma.</li>
        <li><strong>Ekipman:</strong> Flashlight, SMG (hafif makineli tüfek - sınırlı mermi), Sağlık Kiti.</li>
      </ul>
    </td>
  </tr>
</table>

### 🚨 Tesis Muhafızları (Corrupted Guards)
<table align="center">
  <tr>
    <td width="30%" align="center">
      <img src="assets/sci-fi-facility-asset-pack/guard_orange_spritesheet.png" width="120px" alt="Orange Guard"><br>
      <code>guard_orange_spritesheet.png</code>
    </td>
    <td width="70%">
      <strong>Mutasyona Uğramış Koruyucular</strong><br><br>
      Tesisin eski güvenlik personeli. Parazit bulaşması sebebiyle akıllarını yitirmiş ve sadece ses ile harekete duyarlı vahşi yaratıklara dönüşmüşlerdir.
      <ul>
        <li><strong>Davranışlar:</strong> Devriye gezerler, ses duyduklarında şüphelenip araştırma durumuna geçerler ve oyuncuyu gördüklerinde koşarak saldırırlar.</li>
      </ul>
    </td>
  </tr>
</table>

### 🕷️ Dev Örümcek Boss (The Queen)
<table align="center">
  <tr>
    <td width="35%" align="center">
      <img src="assets/sprites/spider boss/Spider Actions/walk/actions0001.png" width="220px" alt="Spider Boss (Queen)"><br>
      <code>Spider Boss (Queen) Frame 1</code>
    </td>
    <td width="65%">
      <strong>The Queen (Kraliçe Yaratık)</strong><br><br>
      Tesisin en alt katında (Level 2) yuvalanmış, mutasyonun kaynağı olan devasa örümcek kraliçe. Üst seviye yapay zekaya ve ölümcül saldırı setlerine sahiptir.
      <ul>
        <li><strong>Fazlar & Saldırılar:</strong> Idle, Walk, Low/High Damage tepkileri ve 3 farklı özel yakın/uzak dövüş saldırısı.</li>
        <li><strong>Arayüz:</strong> Ekranda beliren özel Boss Lifebar (Sağlık Barı) ile canı anlık olarak takip edilebilir.</li>
      </ul>
    </td>
  </tr>
</table>

---

## 📸 Ekran Görüntüleri

<div align="center">
  <table>
    <tr>
      <td align="center"><b>Ana Menü Tasarımı</b></td>
      <td align="center"><b>Tesis Atmosferi & Oynanış</b></td>
    </tr>
    <tr>
      <td><img src="assets/external/kamisama/og_image.png" width="100%" alt="Main Menu Screen"></td>
      <td><img src="assets/external/kamisama/screenshot_1.png" width="100%" alt="Gameplay Screen 1"></td>
    </tr>
    <tr>
      <td align="center"><b>Karanlık ve Keşif</b></td>
      <td align="center"><b>Tehlikeli Karşılaşmalar</b></td>
    </tr>
    <tr>
      <td><img src="assets/external/kamisama/screenshot_2.png" width="100%" alt="Gameplay Screen 2"></td>
      <td><img src="assets/external/marceles/screen_lab.png" width="100%" alt="Laboratory Screen"></td>
    </tr>
  </table>
</div>

---

## ⌨️ Kontroller

| Tuş | Eylem | Açıklama |
| :--- | :--- | :--- |
| **W / A / S / D** | Hareket | Karakteri 8 yönlü hareket ettirir. |
| **Shift** | Koşma | Hareketi hızlandırır ancak ses çıkarır (AI çeker). |
| **Ctrl** | Eğilme | Tamamen sessiz hareket sağlar, tespit edilmeyi zorlaştırır. |
| **Space** | Dash (Atılma) | Tehlikeli anlarda hızlıca yön değiştirip kaçmanızı sağlar. |
| **F** | El Feneri | Feneri açar/kapatır (Açıkken AI'ın sizi görmesi kolaylaşır). |
| **E** | Etkileşim | Eşya toplar, saklanma dolaplarına girer veya jeneratörleri başlatır. |
| **Sol Tık** | Ateş Et | SMG ile hafif makineli tüfekle ateş eder. Çok fazla gürültü yayar! |
| **Esc** | Duraklat | Oyunu durdurur ve duraklatma menüsünü açar. |

---

## 🔧 Kurulum ve Çalıştırma

1. **Godot Engine** sürümünün kurulu olduğundan emin olun (Godot 4.x önerilir).
2. Projeyi bilgisayarınıza klonlayın:
   ```bash
   git clone https://github.com/gokaycetinn/Blackout.git
   ```
3. Godot Project Manager üzerinden projeyi içe aktarın (`project.godot` dosyasını seçin).
4. Oyunu başlatmak için ana sahne olan `scenes/main.tscn` veya `scenes/ui/main_menu.tscn` sahnesini çalıştırın.

---

<div align="center">
  <p><b>BLACKOUT</b> bir CENG361 Final Projesidir.</p>
  <p>© 2026. Tüm hakları saklıdır.</p>
</div>
