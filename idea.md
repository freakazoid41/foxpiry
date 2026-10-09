# Foxpiry — fikir + session memory (güncel)

Orijinal istek: profesyonel, net, uygulanabilir Flutter mobil uygulama.

## Karar: Uygulama adı = Foxpiry
- Anlam: fox + expiry. Tüketim ürünlerinin tarihini koklayıp validate eden akıllı tilki.
- Tagline (5 dil): TR "Tarihleri koklayan akıllı tilki" / EN "Smart fox sniffs expiry dates" / FR "Le renard qui flaire les dates" / RU "Умный лис чует сроки" / HI "समाप्ति सूंघने वाली स्मार्ट लोमड़ी"
- Neden Foxpiry: global, kısa, maskot hazır (büyüteçli tilki + yeşil check), Play Store/web çakışması yok (kontrol edildi).
- Reddedilenler: Expira (Play Store'da aynı işi yapan var + expira.dev/expiria), Vadelly (ara isimdi, Foxpiry'ye geçildi), Duevia/UseBy/ExpiresBy/Duebell/Keeply/Validfox/Vulpex/FoxLens (hepsi dolu), Daylid (boş ama Dayli/Dayly/Daylit ile karışıyor, riskli). Fox yedekleri: Sniffox, Foxproof, Reynard (hepsi boş, Foxpiry kazandı).

## Konsept (değişmedi)
Kullanıcı gıda, ilaç, kozmetik, elektronik, giyim vs. her türlü ürünün son kullanma / iade son / garanti bitiş tarihini fotoğraf çekerek veya elle girerek kaydeder. Akıllı hatırlatmalar + gıda için basit değerlendirme önerisi. Sosyal özellik YOK. Kişisel, hızlı, pratik, offline. Tasarım dili: "fox searching / sniffing" — iz sürme, koku, büyüteç, pati. Gelir: AdMob banner.

## Dil
TR, EN, FR, RU, HI (Hindi — "Hindu" değil). `lib/l10n/strings.dart` içinde özel map, `flutter_localizations` ile. 37 key, hepsi 5 dilli eksiksiz (2026-09-22 denetlendi).
- Aktif: appName, tagline, upcoming, all, expired, settings, add, productName, category, dateType, date, note, photo, camera, gallery, readDate, save, delete, foodTip, language, notifications, clearExpired, daysLeft, daysOver, today, sniffHint, onTrail, noTrail, foxDen, footer, scanTitle, scanHint, barcode, scanAction, codeFound, codeLearned, codeUnknown.
- Silinen ölü keyler: `search` (→sniffHint), `empty` (→noTrail), `theme*` (dark ile).
- Category(6) + DateType(3) label hepsi 5 dilli, tips + notify başlıkları 5 dilli.

## Tech stack (kurulu)
provider, shared_preferences, image_picker, path_provider, uuid, intl, flutter_local_notifications, timezone, google_mlkit_text_recognition, google_mobile_ads, mobile_scanner, http. Kanal: `foxpiry_reminders`. Hatırlatma: 30/7/3/1/0 gün kala 09:00.
- Reklam: AdMob banner home üstte (eski AppBar başlığı yerine, `lib/services/ads.dart` FoxAdBanner 320x50, offline'da otomatik gizlenir). minSdk 23 (admob şartı).
- TEST ID'ler devrede — release öncesi gerçek ID ile değişecek: App `ca-app-pub-3940256099942544~3347511713` (AndroidManifest), banner `.../6300978111`. Test reklam PixelPlay'de doğrulandı ("Nice job! Test Ad").

## Yapı (güncel)
- lib/main.dart → FoxpiryApp (ThemeMode.light sabit, FoxTheme.light) + MobileAds init, Root (Home + Settings, NavigationBar pets/settings)
- lib/core/theme.dart → FoxColors (foxOrange #F59E0B, foxDeep #EA580C, teal #0F766E, leaf #22C55E, cream #FFF7ED) + FoxTheme.light only + denGradient() (light). Dark TAMAMEN SİLİNDİ (kullanıcı isteği).
- lib/models/item.dart → Category(6), DateType(expiry/ret/warranty), TrackedItem + daysDiff + barcode (geriye uyumlu, eski kayıtta boş string)
- lib/data/store.dart → ChangeNotifier, keys `foxpiry_items_v1`, `foxpiry_lang`, `foxpiry_notif`, `foxpiry_barcodes_v1` (SharedPreferences cacheli). `foxpiry_theme` SİLİNDİ. Fotoğraf dosyaları remove/update/clearExpired'da silinir. rememberCode()/recallCode() → kod hafızası.
- lib/services/notify.dart, lib/services/ocr.dart (dd.mm.yyyy + yyyy-mm-dd parse, ölü dal temiz), lib/services/ads.dart (FoxAdBanner, test ID), lib/services/barcode.dart (OpenFoodFacts lookup, ilk seferde internet gerekir)
- lib/ui/scan_screen.dart → canlı barkod tarayıcı (mobile_scanner, offline tespit + fener). EditScreen barkod satırı (tara/hatırla) + save'de rememberCode, Detail barkod chip. TrackedItem.barcode (eski kayıtlarla uyumlu). Store codeMemory (`foxpiry_barcodes_v1`) — öğrenilen her kod offline doldurur. Stringler: scanTitle/scanHint/barcode/scanAction/codeFound/codeLearned/codeUnknown (5 dil). TELEFON DOĞRULANDI: Ekle → Barkod•Tara satırı render → ScanScreen (başlık/çerçeve/ipucu/fener) açılıyor. Fiziksel barkod taraması emülatörde yapılamaz (kamera sanal) — gerçek cihazda denenecek. Analyze clean + test passed.
- lib/core/tips.dart → gıda + iade/garanti önerisi, 5 dil
- lib/ui/home_screen.dart → AppBar BAŞLIKSIZ (toolbar 0, sadece TabBar 22px) + üstte AdMob; den banner slim (fox badge 60 + icon chipler); sniff search (suffix fox 38px); fancy kategori çipleri (fluid: 320ms fastOutSlowIn + scale nefes + paw pop); per-tab empty fox (calendar/scan/expired 170px); tile avatar 28r + ResizeImage(112) + pati dot
- lib/ui/settings_screen.dart → Fox Den card (fox_gear 88px), dil chips, bildirim switch, clearExpired. Tema seçici YOK.
- lib/ui/splash_screen.dart → beyaz zemin + koyu yazı, rozetsiz fox 280px, hafif üstte (native devam hissi), Stateful + 5 fox precache
- lib/ui/edit_screen.dart (controller dispose + OCR mounted guard), detail_screen.dart (sadece lang dinler)
- test/widget_test.dart → daysDiff + OCR parse testi
- Android: applicationId/namespace `com.foxpiry.app.foxpiry`, label `Foxpiry`, kamera/bildirim izinleri + AdMob APP_ID meta tamam. MainActivity `.../com/foxpiry/app/foxpiry/MainActivity.kt` (eski expira yolu silindi).
- pubspec: `assets/branding/` klasörü tamamı + google_mobile_ads + mobile_scanner + http.

## Marka + fox ailesi (güncel)
Ana: Tilki + büyüteç + yeşil check + MILK kartonu + ilaç şişeleri. Renkler: tilki turuncu #F59E0B, teal #0F766E, yeşil check #22C55E, krem #FFF7ED.
- `assets/branding/fox.png` (500px) → ana brand (search suffix, splash 280, den badge 60). Master transparent, görünür art (116,57,409,434).
- `assets/branding/fox_scan.png` (677x369) → Tümü empty. Telefonla tarayan tilki.
- `assets/branding/fox_calendar.png` (500x500) → Yaklaşan empty. October takvimli tilki.
- `assets/branding/fox_expired.png` (486x514) → Dolmuş empty. EXPIRED clipboard + kutulu tilki.
- `assets/branding/fox_gear.png` (500x500) → Ayarlar (AppBar 44px + den 88px). Dişlili tilki.
- Logo geçmişi: siyah zeminli → isnet → u2net krem kesim → MILK varyant master → #FFFFFF temizliği → çene halo temizliği (6.296 px).
- Kaynak root dosyalar (kopyalandı, silinebilir ama master yedeği): `Gemini_Generated_Image_8gxou...` (gear), `...a84wj...` (expired), `...ktcyeg...` (calendar), `...upzpah...` (scan).

## Durum
`flutter analyze`: clean. `flutter test`: passed. `flutter build apk --debug`: OK.
- FIX 2026-09-21: MainActivity package mismatch (expira→foxpiry) çözüldü.
- NEW 2026-09-21: Fox-hunt light-only tema, 4 fox, büyütmeler. Dark KULLANICI İSTEĞİYLE KALDIRILDI.
- NEW 2026-09-21: Den banner redesign (medallion + icon chipler) → slim (60px). Kategori çipleri fancy (gradient + glow). Splash beyaz + rozetsiz 280 + hafif üstte. Launcher + Play ikon beyaz + fox büyütüldü (tight-crop).
- NEW 2026-09-22: AdMob banner (AppBar başlığı yerine), test reklam doğrulandı. Chip feel: ripple/highlight kapalı (çift renk öldu), gradient-her-iki-halde tek morph → fluid final (320ms fastOutSlowIn + easeOutBack nefes 1.05 + paw pop + yazı geçişi). Gıda/İlaç/Kozmetik seçimleri telefonda doğrulandı.
- NEW 2026-09-22: Barkod avcısı tamam — mobile_scanner + OpenFoodFacts + öğrenilen kod hafızası (codeMemory) + 7 string (5 dil) + barcode alanı. Telefon doğrulaması bitti (Edit satırı + ScanScreen açılışı screenshots ile), analyze clean, test passed.
- PERF 2026-09-21: TabController/TextController dispose, OCR guard, prefs cache, foto temizliği, select-lang, precache, ResizeImage avatar, OCR ölü dal silindi.
- Hepsi PixelPlay'de (emulator-5554) screenshot ile doğrulandı.

## Logo + ikon + splash
- `assets/branding/play_icon_512.png` → Play Store 512 (beyaz zemin + büyük fox).
- Feature graphic 1024x500 (3 dil): `feature_en/tr/ru.png` — krem zemin, fox + Foxpiry + tagline.
- Android launcher: legacy mipmap-+round (mdpi→xxxhdpi, beyaz zemin) + adaptive `mipmap-anydpi-v26` (fg 0.64) + `values/colors.xml` (#FFFFFF).
- Native splash: beyaz #FFFFFF + splash_image (`flutter_native_splash:create` yenilendi).
- In-app splash: beyaz, fox 280, Root min 1.6sn.
- Üretim scripti: `tools/make_icons.py` (MASTER `assets/branding/fox.png`; tight-crop + contain-fit; play 0.92, legacy 0.90, fg 0.64, splash 0.55). TEAL + WHITE sabitleri durur.
- Temizlik adayları: `Gemini_Generated_Image_*`, `foxpiry_logo_*.png`, `zoom_*.png`, eski `foxpiry_logo_clean.png`.

## Test cihazı
- Red's Phone = PixelPlay, emulator-5554, Android 35 Play Store. Not: emülatör bazen ölür, `emulator -avd PixelPlay` + boot wait ile kaldır. Komutlar: `install -r build/app/outputs/flutter-apk/app-debug.apk`, `am start -n com.foxpiry.app.foxpiry/.MainActivity`, `pm clear` sıfırlama, `input tap x y` (reklam layout'u kaydırır — önce screenshot alıp koordinatı onayla).

## Bekleyen
- AdMob GERÇEK ID'leri (release öncesi): App ID + banner unit → `AndroidManifest.xml` + `lib/services/ads.dart`.
- Barkod gerçek cihazda uçtan uca denenecek (emülatör kamerası sanal).
- Çoktan çekilmiş usability fikirleri (onay bekliyor): undo-delete snackbar, swipe-to-delete, tappable den stats, boş-durum CTA butonu, hatırlatıcı gün/saat seçimi, sıralama, JSON backup, exact-alarm izin denetimi.
- iOS ikonları + Info.plist AdMob ID (istenirse).
- Root Gemini dosyalarını arşivle/sil kararı.

## Session 2026-09-23 — physical device + rich OFF (English log)
- Physical phone connected: Redmi M2006C3MG (Helio G35, 720x1600, density 320) as B6WK7DNZLFEQCUEU. Debug install worked, cold start ~12s on low battery, home rendered with test ad.
- Lag cause found: debug build (235MB) + blocked startup (MobileAds + timezone DB + rescheduleAll before runApp) + full Home rebuild per keystroke + banner WebView + full-res photo decode + MIUI ForceDark + 21% battery throttle.
- Release fix: created `android/app/proguard-rules.pro` (MLKit dontwarn + keep), enabled minify in `android/app/build.gradle.kts` (shrinkResources false). First release crashed on cold start: R8 stripped Gson generics → `Missing type parameter` in `flutter_local_notifications.cancelAll` via `store.dart rescheduleAll`. Fixed with keepattributes Signature + keep dexterous/gson. Release now 103MB (was 235MB), boots clean, no crash.
- Strings now 45 keys (was 37): added prodInfo, brand, quantity, nutri, nova, eco, ingredients, allergens — all 5-lang.
- Den banner fit fix for 720px wide: badge 60→52, padding 12→10, title single-line ellipsis 13.5, Wrap→horizontal SingleChildScrollView Row, chip 9/11.5→8/11. Verified single line.
- OFF rich upgrade: `lib/services/barcode.dart` now ProductInfo (name, genericName, brand, quantity, imageUrl, categories, categoriesTags, labels, nutritionGrade, novaGroup, ecoscore, ingredients, allergens, host, lang) + 4-host lookup (food, beauty, pet, products) + smart category guess + displayName Brand+Name+Qty + localized picker.
- Multi-lang OFF: `lookup(code, lang)` requests `product_name_LANG`, `generic_name_LANG`, `ingredients_text_LANG` with fallback. Verified Beypazari tr + Nutella pack language behavior.
- Model: `TrackedItem` + brand, quantity, offImageUrl, offCategories, offLabels, nutriGrade, novaGroup, ecoscore, ingredients, allergens, offLang + hasOffInfo + backward-compatible JSON.
- Memory: `Store.rememberCode` stores full extra map, `recallCode` returns name+category+extra. Old memories still load.
- Scan: `EditScreen` auto-fills displayName, smart category, all rich fields + offLang, saves on add/update, restores from memory offline.
- Details: `DetailScreen` Stateful with auto-backfill + re-fetch on offLang mismatch + white hero frame (contain 200px, no crop) + white product card (grade pills only for single-letter a-e, icon rows). Verified on device with 8691381000486: Beypazari 200ml, Nutri A, Nova 4, Vegan labels, TR ingredients, packshot loads after ~5s. Eco NOT-APPLICABLE hidden.
- Status: analyze clean, test passed, release installed on physical phone, screenshots verified (home single-line, detail full card).
- Pending: real AdMob IDs, iOS icons, usability backlog (undo-delete, swipe-delete, tappable stats, empty CTA, reminder picker, sort, JSON backup, exact-alarm), Gemini root cleanup, last rebuild was user-aborted — rebuild before next install.

## Session 2026-09-24 — perf pass, no logic change (English log)
- Non-blocking startup: runApp first, MobileAds + load + notify + reschedule after. Same order, splash covers load.
- Rebuild cuts: FoxpiryApp + Root + Settings use select (lang/loaded/notifOn) instead of watch-all. Home selects lang + items, sorts once, slices 3 views.
- Home list: 250ms search debounce, pre-sorted base (no re-sort), lowercase once, RepaintBoundary per tile, avatar ImageProvider cache (was fresh FileImage per build), TabBarView KeepAlive.
- Store: _save guarded, rescheduleAll fanned out with Future.wait (same IDs/times).
- Theme cached (static light + const gradient), splash precaches 2 foxes once (was 5 every deps change), ads fail path clears ref + white bed, OCR caps text at 4000 chars, ImagePicker shared static, Detail network image has loader + gapless.
- Verified: analyze clean, test passed, 103MB release on PixelPlay emulator boots clean, home single-line den + empty fox + test ad, no crash. Physical phone was unplugged overnight so phone shots pending; emulator proof done.

## Session 2026-10-09 — release blockers fixed (English log)
- Boot survival: new `BootReceiver.kt` (BOOT_COMPLETED, goAsync + background FlutterEngine + 25s latch) runs Dart `bootReschedule()` (`lib/boot.dart`, vm:entry-point, no UI) → Store.load + rescheduleAll. Receiver confirmed in merged manifest + installed package. Exact-alarm permissions REMOVED (we schedule inexact; USE_EXACT_ALARM would trigger Play restricted-permission review).
- Permission honesty: `NotifyService.ensurePermission()` (areNotificationsEnabled + requestNotificationsPermission, v18 API verified). Asked once on startup (flag `foxpiry_perm_asked`), always on switch-on. Fresh-install proof on emulator: system Allow dialog appeared, UI behind it in device English.
- Device-locale default: fresh installs use system language when supported (TR/EN/FR/RU/HI), else TR. Saved users untouched. Emulator (EN) booted straight into English UI.
- AAB built: `app-release.aab` 71-74MB (debug-signed, Play needs real keystore). APK 108MB for device tests.
- Status: analyze clean, test passed, emulator fresh-install verified (permission dialog + EN default + clean home, zero Flutter errors).
- Still needs USER: real AdMob App ID + banner unit (test IDs live), real release keystore (debug signing now), Play Data Safety form + store graphics (Console work, not code).

## Session 2026-10-09 — real AdMob + release signing (English log)
- AdMob REAL Android pair live: App `ca-app-pub-1088997129209291~5448186579` (manifest), banner `ca-app-pub-1088997129209291/1009324670` (ads.dart). iOS still test banner. Note: fresh ad units need ~1h + approval before real ads serve; emulator still showed test creative after swap, no crash.
- Release keystore generated: `android/foxpiry-release.jks` (alias foxpiry, RSA-2048, 10k days) + `android/key.properties` (both git-ignored). build.gradle.kts reads via foxKey() helper (plain-Kotlin line parse — Gradle Kotlin DSL choked on java.util.Properties imports) with debug fallback when file missing.
- AAB 74MB now signed Owner CN=Foxpiry (verified via keytool -printcert). Emulator install of signed APK boots clean, no Flutter errors.
- PASSWORDS HANDED IN CHAT ONLY, never in repo. User must back up jks + password or updates become impossible.

## v1.0.1 store bundle (2026-10-09, English log)
- pubspec bumped 1.0.0+1 → 1.0.1+2. AAB 71MB Foxpiry-signed (keytool verified), APK badging proves stamp: package com.foxpiry.app.foxpiry versionCode 2 versionName 1.0.1. Upload file: build/app/outputs/bundle/release/app-release.aab.
- Emulator died mid-session (both PixelPlay boots exited); no device attached now.

## Package rename (2026-10-09) — Play demands com.foxpry.app
- applicationId + namespace + both Kotlin files moved to com.foxpry.app (old com.foxpiry.app.foxpiry dirs removed). Rebuilt AAB 71MB, badging proves package com.foxpry.app v1.0.1+2, Foxpiry-signed. NOTE: spelling is foxpry (no i) per Play Console message — permanent for this listing.

## Store screenshots (2026-10-09, English log)
- 12 shots, 1080x1920 9:16 PNG, all <400KB: store/en|tr|ru × (01_home, 02_detail Nutella+OFF card, 03_add, 04_settings). Fake den via TEMP SEED_SHOTS dart-define (6 items, Nutella barcode for live OFF backfill) — seed code FULLY REVERTED after, analyze clean, source matches shipped AAB again. Emulator forced to 1080x1920 via wm size for exact 9:16, reset after. Real AdMob creatives served during shots (fine — real app UI).
- NOTE: screenshot APK (104MB, SEED build) is NOT the store binary. Store binary stays build/app/outputs/bundle/release/app-release.aab v1.0.1+2.

## Tablet screenshots (2026-10-09, English log)
- 12 shots, 1920x1080 16:9 landscape PNG, all <250KB: store-tablet/en|tr|ru × (01_home, 02_detail, 03_add, 04_settings). UnitFoxTablet forced to 1920x1080 (portrait override caused SystemUI ANR — landscape native, healthy). Same fake den seed, reverted after, analyze clean, wm reset.
