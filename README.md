# Rayxon — Mac uchun o'zbek desktop pet

Rayxon — ish stolingizda yashaydigan kichkina chibi qiz, milliy o'zbek kiyimida. U yuradi,
oynalar ustida turadi, oyna yopilsa yiqiladi, gaplashadi (Gemini yoki Claude), o'zbekcha
ovoz bilan gapiradi (Edge TTS), suv ichish / ko'zga dam / qomat eslatmalarini beradi,
Pomodoro va vazifalar ro'yxatini yuritadi, injiq qiz kayfiyati bor.

## Talablar
- macOS 15+ (Apple Silicon yoki Intel)
- Swift 6 toolchain (`swift --version`) — Xcode shart emas
- `uv` (`brew install uv`) — ovoz uchun (`edge-tts` CLI shu orqali ishga tushadi)

## Ishga tushirish
```bash
scripts/run.sh            # debug build → dist/Rayxon.app → ochadi
scripts/run.sh --install  # release build → /Applications/Rayxon.app
swift test                # unit testlar
```

Birinchi ishga tushirishdan keyin: o'ng tugma → **Sozlamalar → Suhbat** → Gemini
(aistudio.google.com) yoki Claude (platform.claude.com) API kalitini kiriting. Kalit
Keychain'da saqlanadi.

## Menyu (o'ng tugma yoki menyu bar ikonkasi)
Gaplashish · Uxla/Uyg'ot · Boshini silash · Kursor yoniga chaqirish · Ovozni o'chirish ·
Kiyimlar ▸ · Vazifalar · Pomodoro · Sozlamalar · Mac bilan birga yoqish ·
Eslab qolganlari · Xotirani tozalash · Yashirish · Chiqish

## Sprite san'ati
Rasmlar Gemini (Nano Banana) bilan yaratilgan, xom varaqlar `art/<kiyim>/` da.
Striplarni qayta kesish:
```bash
scripts/sprites/build_all.sh   # art/ → Sources/Rayxon/Resources/Sprites/<kiyim>/<holat>.png + manifest.json
```
Har bir katak 256×256 px, oyoq chizig'i y=232, gorizontal strip. Yangi kiyim qo'shish uchun
`art/<id>/` ga varaqlarni qo'ying, `build_all.sh` jadvaliga qator qo'shing va
`SpriteCatalog.outfitTitles` ga nom bering. `reference.jpg` bo'lgan kiyimlargina menyuda chiqadi.

## Arxitektura (qisqa)
- `Pet/` — oyna, sprite animator, fizika, xatti-harakat avtomati, silkitish detektori
- `Surfaces/` — boshqa ilovalar oynalarining yuqori qirralarini `CGWindowListCopyWindowInfo` orqali o'qish (ruxsat kerak emas)
- `Bubble/` — gap pufagi (NSPanel + SwiftUI)
- `Chat/` — Gemini/Claude provayderlar, persona, xotira, kayfiyat (Mood), iboralar (PhraseBook)
- `Voice/` — Edge TTS (`uv tool run edge-tts`), AVAudioPlayer
- `Wellness/` — eslatmalar, Pomodoro, o'zi gapirish, vazifa eslatmalari
- `Settings/`, `Tasks/` — SwiftUI oynalar, UserDefaults + Keychain, SMAppService

Ma'lumotlar: `~/Library/Application Support/Rayxon/{memory,tasks}.json`.

## Tarqatish (release)
```bash
sudo xcode-select -s /Applications/Xcode.app          # bir marta
xcrun notarytool store-credentials rayxon-notary --apple-id you@example.com --team-id TEAMID --password <app-specific>
RAYXON_SIGN_IDENTITY="Developer ID Application: Name (TEAMID)" NOTARY_PROFILE=rayxon-notary scripts/release.sh 0.2.0
gh release create v0.2.0 dist/Rayxon-0.2.0.dmg
```
Ilova ichidagi "Yangilanishni tekshirish" GitHub Releases dan oxirgi versiyani oladi (`UpdateChecker.repo`).
Keyinchalik Sparkle ga o'tish mumkin (EdDSA kalit + appcast kerak).
