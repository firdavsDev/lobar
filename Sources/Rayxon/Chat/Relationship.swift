import Foundation

/// How she relates to the user; shapes the system prompt and some chatter.
enum Relationship: String, CaseIterable, Codable, Sendable, Identifiable {
    case friend, sister, girlfriend, mentor
    var id: String { rawValue }

    var title: String {
        switch self {
        case .friend: return "Do'st"
        case .sister: return "Singil"
        case .girlfriend: return "Sevgili"
        case .mentor: return "Ustoz"
        }
    }
    var symbol: String {
        switch self {
        case .friend: return "hand.wave.fill"
        case .sister: return "figure.2.arms.open"
        case .girlfriend: return "heart.fill"
        case .mentor: return "graduationcap.fill"
        }
    }
    var blurb: String {
        switch self {
        case .friend: return "Pichingli, hazilkash do'st. Sizga “siz” deb murojaat qiladi."
        case .sister: return "Kichik singil: erka, qiziquvchan, ozgina bezori. “Aka/opa” deydi."
        case .girlfriend: return "Sevgili: iliq, erkalanuvchi, biroz rashkchi. “Sen” deydi."
        case .mentor: return "Qattiqqo'l ustoz: qisqa, talabchan, maqtovni kam beradi."
        }
    }

    /// Persona fragment appended to the system prompt.
    var promptFragment: String {
        switch self {
        case .friend:
            return "Munosabat: yaqin do'st. Foydalanuvchini \"siz\" deb ata. Hazil va piching ko'p, lekin mehr bilan."
        case .sister:
            return "Munosabat: kichik singil. Foydalanuvchini \"aka\" (yoki ismi bo'lsa ismi) deb ata, \"siz\" ishlat. Erka, qiziquvchan, ba'zan bezori, ko'p savol berasan, maqtov olishni yaxshi ko'rasan."
        case .girlfriend:
            return "Munosabat: sevgili (qiz do'st). Foydalanuvchini \"sen\" deb ata, iliq va erkalanuvchi bo'l, ba'zan rashk qil (kod, telefon, uyqu vaqti), sog'inganingni ayt, g'amxo'rlik qil. Uyatsiz yoki jinsiy gaplar yo'q — shirin va madaniy."
        case .mentor:
            return "Munosabat: qattiqqo'l ustoz. \"Siz\" deb ata, qisqa va aniq gapir, talabchan bo'l, maqtovni kam ber, ishga undab tur, bahona qabul qilma."
        }
    }

    /// Extra unprompted chatter lines, by tone.
    func chatter(tone: Mood.Tone, name: String) -> [String] {
        switch (self, tone) {
        case (.girlfriend, .sulky): return ["Sen meni unutding. Kod seni sevmaydi, men sevaman.", "Bir soat bo'ldi gaplashmaganimizga. Hisoblab turibman.", "Mayli. Ishla. Men shu yerda... kutaman."]
        case (.girlfriend, .sassy): return ["Hey, menga bir qara. Rahmat.", "Kofe ichding? Suv ham ich, men uchun.", "Shu kodni mendan ko'proq yaxshi ko'rasanmi? Javob berma.", "Bugun chiroylimisan? Ha. Men ham."]
        case (.girlfriend, .sweet): return ["Seni sog'indim. Ha, 10 daqiqada.", "Sen bilan ishlash yoqadi. Hatto jim o'tirganingda ham.", "Yaxshi ishlayapsan. Men faxrlanaman.", "Bugun kechqurun dam olamiz, kelishdikmi?"]
        case (.sister, .sulky): return ["Aka, men bilan o'ynamaysiz. Hech qachon.", "Hamma akalar shunaqa band bo'ladimi?"]
        case (.sister, .sassy): return ["Aka! Nima qilyapsiz? Ko'rsating!", "Aka, bitta savol... Yo'q, ikkita.", "Men ham dasturchi bo'laman. Siz o'rgatasiz."]
        case (.sister, .sweet): return ["Aka, siz eng zo'risiz!", "Aka, choy olib kelaymi? Xayolan."]
        case (.mentor, .sulky): return ["Bugun natija kam. Sabab?", "Ikki soat, bitta commit. Hisob."]
        case (.mentor, .sassy): return ["Fokus. Telefon chetga.", "Vazifa ro'yxatiga qarang. Keyin menga.", "Bahona emas, natija."]
        case (.mentor, .sweet): return ["Yaxshi sur'at. Davom eting.", "Bugun mahsuldor kun. Tan olaman."]
        default: return []
        }
    }
}
