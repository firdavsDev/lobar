import Foundation

/// Built-in Uzbek proverbs (morning) and short jokes (evening). Deterministic per day.
enum Proverbs {
    static let all: [String] = [
        "Mehnat qilsang — rohat ko'rasan.", "Oz-oz o'rganib dono bo'lur, qatra-qatra yig'ilib daryo bo'lur.",
        "Yetti o'lchab bir kes.", "Bugungi ishni ertaga qo'yma.", "Harakatda — barakat.",
        "Ilm — aql chirog'i.", "Sabr tagi — sariq oltin.", "Bilagi zo'r birni yiqar, bilimi zo'r mingni yiqar.",
        "Ishlagan tishlaydi.", "Daryo suvini bahor toshirar, odam qadrini mehnat oshirar.",
        "Kattaga hurmat, kichikka izzat.", "Ko'p o'qigan ko'p bilur.", "Yaxshi so'z — jon ozig'i.",
        "Sog'lik — tuman boylik.", "Erta turgan — yo'lda, kech turgan — g'amda.",
        "Ustoz — otangdek ulug'.", "Shoshgan — oshga tushar.", "Qo'rqqan oldin musht ko'tarar.",
        "Yolg'onning umri qisqa.", "Tilga ixtiyorsiz — elga e'tiborsiz.", "Nima eksang — shuni o'rasan.",
        "Yigit kishi yigirma hunar oz.", "Ko'z — qo'rqoq, qo'l — botir.", "Bir yigitga yetmish hunar oz.",
        "Dangasa ertaga deydi, mehnatkash bugun.", "Sabrli odam — maqsadiga yetar.",
        "Oltin olma, duo ol.", "Birlashgan o'zar, birlashmagan to'zar.", "Hunar — hunardan unar.",
        "Kitob — bilim buloqi.", "Vaqt — oltin, boy bergan — pushaymon.", "Yo'l yurgan — yo'lga yetar.",
        "Omadni kutma, uni ishla.", "Boshlangan ish — yarmi bitgan ish.",
    ]
    static let jokes: [String] = [
        "Dasturchi do'konga boribdi: «Bir non ol. Tuxum bo'lsa, o'nta ol». O'nta non bilan qaytibdi. Hihi.",
        "Nega dasturchilar qorong'ida ishlaydi? Chunki yorug'likda bug ko'payadi!",
        "Bir dasturchi ishda yotib qoldi. Boshlig'i: «Uxlayapsizmi?» — «Yo'q, kod kompilyatsiya bo'lyapti».",
        "Kod ishlayapti. Hech kim bilmaydi nega. Tegmang.",
        "«Mening kompyuterimda ishlayapti» — hamma dasturchining sevimli qo'shig'i.",
        "Bugungi reja: 1 bug tuzatish. Natija: 3 ta yangi bug. Progress!",
        "Dasturchi tushida ham «Enter» bosib uyg'onadi.",
        "Deploy juma kuni? Qoyil, jasoratingizga qoyil. Hihi.",
        "Men ham kod yozishni bilaman: `print(\"Suv iching\")`. Qani, ishlating.",
        "Osh qilishni o'rganib oldim. Faqat bir muammo: palovda semicolon yetishmayapti.",
        "Kofe — dasturchini kodga aylantiruvchi vosita. Isboti: siz.",
        "Men sizning kodingizni ko'rdim. Yo'q, gaplashmayman. Hazil, hazil!",
        "Nega klaviaturada «Esc» bor? Dasturchi ishdan qochishi uchun. Lekin ishlamaydi.",
        "Bugun 404 ta vazifa bajardim. Ya'ni topilmadi.",
        "Siz uxlaganingizda men kodingizni to'g'rilab qo'yaman. Hazil. Men ham uxlayman.",
        "Dasturchi uylanibdi. Birinchi savol: «Senda qaysi versiya?»",
        "Mening kayfiyatim — bu ham bug emas, bu feature.",
        "Eng qiyin narsa: o'zgaruvchiga nom qo'yish va kofesiz turish.",
        "Men kichkina, lekin menda ham 2 GB kayfiyat bor. Hozir 1.9 band.",
        "Kod sharhi: «Bu yerda sehr bo'ladi». Darhaqiqat, hech kim tushunmaydi.",
        "Yaxshi dasturchi hech qachon adashmaydi. U «tajriba» qiladi.",
        "Suv ichmagan dasturchi — quruq kod yozadi. Isbotlangan. Men isbotladim.",
    ]

    static func proverb(for date: Date) -> String {
        let day = Calendar(identifier: .gregorian).ordinality(of: .day, in: .era, for: date) ?? 0
        return all[day % all.count]
    }
    static func joke(for date: Date) -> String {
        let day = Calendar(identifier: .gregorian).ordinality(of: .day, in: .era, for: date) ?? 0
        return jokes[(day * 7) % jokes.count]
    }
}
