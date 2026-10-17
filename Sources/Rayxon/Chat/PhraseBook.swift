import Foundation

/// Tone-aware Uzbek lines. `{name}` is replaced with the pet's name.
enum PhraseBook {
    enum Event: CaseIterable, Sendable {
        case drag, dragArmsOut, dizzy, fell, headPat, headPatTooMuch, clickSpam, sleep, wake, cameToCursor,
             outfit, water, eyes, posture, pomodoroStart, breakStart, workStart, pomodoroStop,
             taskAdded, taskDone, allTasksDone, taskDue, chatOpen, noKey, memoryCleared,
             actRead, actCook, actLie, actTea, actDastarxon,
             morning, lunch, evening, night, userAway, userGone, userBack, cursorNear, hardLanding,
             distracted, backToWork, startedCoding, openedMessaging, commit, peekaboo, chaseFail, bread, parachute, catVisit, peerHello,
             rain, rainStopped, snow, birthday
    }

    static func event(for activity: PetState) -> Event? {
        switch activity {
        case .read: return .actRead
        case .cook: return .actCook
        case .lie: return .actLie
        case .tea: return .actTea
        case .dastarxon: return .actDastarxon
        default: return nil
        }
    }

    private static let table: [Event: [Mood.Tone: [String]]] = [
        .drag: [
            .sulky: ["Qo'ying. Kayfiyatim yo'q.", "Yana men... Ha, mayli.", "Ko'taravering, baribir e'tibor bermaysiz."],
            .sassy: ["Qo'ying meni! Men sumka emasman.", "Hoy! Men o'yinchoq emasman.", "Qayerga? Xabar bermasdan olib ketyapsiz.", "Bir daqiqa, yoqam cho'zilyapti!"],
            .sweet: ["Voy, uchyapman!", "Sekinroq, boshim aylanadi.", "Qayerga olib boryapsiz, do'stim?"],
        ],
        .dragArmsOut: [
            .sulky: ["...", "Mayli."],
            .sassy: ["Qo'yvoring! Qanotim yo'q.", "Samolyot emasman-ku!"],
            .sweet: ["Uchdim! Qarang, uchdim!"],
        ],
        .dizzy: [
            .sulky: ["Boshim aylandi. Rahmat sizga.", "Buni unutmayman."],
            .sassy: ["Boshim aylandi... Buni eslab qolaman.", "Bas qiling! Men karusel emasman.", "Voy... hammasi aylanayapti."],
            .sweet: ["Voy-voy, dunyo aylanyapti...", "Hihi, yana! Yo'q, yo'q, yetarli."],
        ],
        .fell: [
            .sulky: ["Tushdim. Hech kim ushlamadi.", "Oyna ketdi, men ketdim."],
            .sassy: ["Oyna yopildi... oyoq tagimdan ketdi!", "Voy, tushib ketdim! Ogohlantirsangiz bo'lardi.", "Pol qattiq ekan. Bilib qo'ying."],
            .sweet: ["Tushdim, lekin hechqisi yo'q!", "Oh! Yaxshiyam yumshoq qo'ndim."],
        ],
        .headPat: [
            .sulky: ["Hm. Endi esladingizmi?", "Mayli... yana bir marta."],
            .sassy: ["Hmm... yana bir marta silasangiz bo'ladi.", "Yaxshi, yaxshi. Endi ishlang.", "Ha, men shirin qizman, bilaman."],
            .sweet: ["Rahmat! Kun yaxshilandi.", "Sizni yaxshi ko'raman, bilasizmi?", "Yana, yana!"],
        ],
        .headPatTooMuch: [
            .sulky: ["Bo'ldi!", "Sochim buzildi."],
            .sassy: ["Bo'ldi! Sochim buzilyapti.", "Yetadi. Ishingizga qarang.", "Men mushuk emasman."],
            .sweet: ["Hihi, qitiqlayapti! Bo'ldi.", "Yetarli, uyalyapman."],
        ],
        .clickSpam: [
            .sulky: ["Nima?! Bosavermang.", "Men tugma emasman."],
            .sassy: ["Nima bo'ldi? Men tugma emasman.", "Bosavermang, uyg'oqman.", "Hoy, hoy, hoy. Tinchlaning."],
            .sweet: ["Ha, ha, shu yerdaman!", "Nima kerak, do'stim?"],
        ],
        .sleep: [
            .sulky: ["Uxlayman. Bezovta qilmang.", "Yaxshi bo'ldi, dam olaman."],
            .sassy: ["Uxlayapman. Bezovta qilmang.", "Zzz... keyinroq gaplashamiz.", "Men uxlayman, siz ishlang."],
            .sweet: ["Xayrli tun... yo kun? Mayli.", "Biroz uxlab olay, keyin yana suhbat."],
        ],
        .wake: [
            .sulky: ["Nima bo'ldi endi?", "Uyg'otdingiz. Umid qilamanki muhim."],
            .sassy: ["Uyg'ondim. Nima bo'ldi?", "Hm? Men uxlamayotgan edim.", "Tush ko'rayotgan edim. Rahmat."],
            .sweet: ["Uyg'ondim! Sizni sog'indim.", "Hayrli kun! Nima qilamiz?"],
        ],
        .cameToCursor: [
            .sulky: ["Keldim. Nima?", "Ha?"],
            .sassy: ["Keldim. Nima kerak?", "Ha, chaqirdingizmi?", "Yugurib keldim. Endi ayting."],
            .sweet: ["Keldim! Nima kerak, azizim?", "Shu yerdaman!"],
        ],
        .outfit: [
            .sulky: ["Kiyim almashtirdim. Baribir qaramaysiz.", "Ha, yangi kiyim. Ishlang."],
            .sassy: ["Kiyim almashtirdim. Ko'zingizni olmang... yo'q, oling, ishlang.", "Yangi kiyimimni kiydim. Yarashdimi?", "Buni ko'rganlar hayratda qoladi."],
            .sweet: ["Qarang! Yarashdimi?", "Siz uchun kiydim!"],
        ],
        .water: [
            .sulky: ["Suv iching. Aytdim.", "Suv. Hozir."],
            .sassy: ["Suv ichdingizmi? Kofe hisobga kirmaydi.", "Bir stakan suv. Hozir. Men kutaman.", "Suv iching, miyangiz quriyapti, kod ham.", "Hey, suv! Keyin davom etasiz."],
            .sweet: ["Suv ichib oling, iltimos. Men ham ichdim.", "Suv vaqti! Sog'lig'ingiz menga muhim."],
        ],
        .eyes: [
            .sulky: ["Ko'zingizga dam bering.", "Uzoqqa qarang. 20 soniya."],
            .sassy: ["Ko'zingizga dam bering: 20 soniya uzoqqa qarang.", "20-20-20: 6 metr naridagi narsaga 20 soniya qarang.", "Ekranga tikilib qoldingiz. Derazaga qarang."],
            .sweet: ["Ko'zlaringiz charchadi. Menga emas, derazaga qarang.", "20 soniya uzoqqa qarang, men kutaman."],
        ],
        .posture: [
            .sulky: ["Qomat.", "Turing. Yuring."],
            .sassy: ["Qomatingiz! O'rningizdan turing, cho'ziling.", "Bir daqiqa yuring. Stul qochib ketmaydi.", "Yelkangiz quloqqa yetib qoldi. Bo'shashtiring."],
            .sweet: ["Turib cho'zilib oling, men ham cho'zilaman.", "Yelkalarni aylantiring. Shunday, ajoyib!"],
        ],
        .pomodoroStart: [
            .sulky: ["Boshladik. Chalg'imang.", "Pomodoro. Ishlang."],
            .sassy: ["Pomodoro boshlandi. Ishlang, men kuzataman.", "Boshladik. Telefonni qo'ying.", "Taymer ketdi. Endi gap yo'q."],
            .sweet: ["Boshladik! Siz uddalaysiz.", "Pomodoro ketdi. Men yoningizdaman."],
        ],
        .breakStart: [
            .sulky: ["Tanaffus. Boring.", "Dam oling."],
            .sassy: ["Tanaffus! Turing, choy damlang.", "Dam oling. Men ham dam olaman.", "Tanaffus vaqti. Kod qochmaydi."],
            .sweet: ["Tanaffus! Zo'r ishladingiz.", "Choy vaqti! Palov ham bo'lsa yaxshi."],
        ],
        .workStart: [
            .sulky: ["Ishga.", "Tanaffus tugadi."],
            .sassy: ["Tanaffus tugadi. Ishga qaytamiz.", "Yetarli dam oldingiz. Ishlang.", "Hop, qaytdik. Fokus."],
            .sweet: ["Davom etamiz! Siz zo'rsiz.", "Yana ish. Men ishonaman sizga."],
        ],
        .pomodoroStop: [
            .sulky: ["To'xtadi.", "Mayli."],
            .sassy: ["Pomodoro to'xtatildi.", "Bo'ldi, bugun shuncha.", "To'xtatdik. Umid qilamanki sabab bor."],
            .sweet: ["To'xtatdik. Yaxshi ishladingiz!", "Dam oling, munosibsiz."],
        ],
        .taskAdded: [
            .sulky: ["Yozib qo'ydim.", "Yana bir vazifa. Ajoyib."],
            .sassy: ["Yozib qo'ydim. Endi bajaring ham.", "Vazifa ro'yxatda. Ro'yxat sizni kutyapti.", "Qo'shildi. Eslatib turaman, xavotir olmang."],
            .sweet: ["Yozdim! Birga bajaramiz.", "Qo'shildi. Siz uddalaysiz!"],
        ],
        .taskDone: [
            .sulky: ["Bitta bajarildi. Hm.", "Yaxshi."],
            .sassy: ["Bitta bajarildi. Qolganlari?", "O, siz ishlaysiz ekan!", "Zo'r. Keyingisi."],
            .sweet: ["Barakalla! Faxrlanaman.", "Zo'r ish! Yana bitta!"],
        ],
        .allTasksDone: [
            .sulky: ["Hammasi tugadi. Endi nima?", "Bo'sh ro'yxat."],
            .sassy: ["Hammasi bajarildi?! Kim siz?", "Ro'yxat bo'sh. Dam olishga ruxsat.", "Hammasi tayyor. Men hayratdaman."],
            .sweet: ["Hammasi tayyor! Siz eng zo'risiz!", "Ro'yxat bo'sh! Bayram qilamiz!"],
        ],
        .taskDue: [
            .sulky: ["Vaqti keldi: {task}.", "{task}. Hozir."],
            .sassy: ["Eslatma: {task}. Vaqti keldi.", "{task} — hozir. Men aytgandim.", "Soat bo'ldi: {task}."],
            .sweet: ["Vaqti keldi: {task}. Siz uddalaysiz!", "Eslatma: {task}. Men yoningizdaman."],
        ],
        .chatOpen: [
            .sulky: ["Eshityapman. Qisqa qiling.", "Nima?"],
            .sassy: ["Eshityapman. Nima deysiz?", "Gapiring, lekin kodga aloqador bo'lsin.", "Ha? Vaqtim bor."],
            .sweet: ["Eshityapman! Nima bo'ldi?", "Gaplashamiz! Kuningiz qanday o'tdi?"],
        ],
        .noKey: [
            .sulky: ["Gaplasha olmayman. Kalit yo'q.", "Sozlamalarga kiring."],
            .sassy: ["Gaplashish uchun Sozlamalarda API kalit kiriting.", "Miyam yo'q. Sozlamalar → Suhbat → kalit."],
            .sweet: ["Gaplashishni xohlayman, lekin kalit kerak. Sozlamalarga kiring."],
        ],
        .actRead: [
            .sulky: ["Kitob o'qiyapman. Xalaqit bermang.", "O'qiyapman. Siz ham o'qing."],
            .sassy: ["Kitob o'qiyapman. Siz dokumentatsiya o'qing.", "Bu kitobda sizdan aqlliroq qahramon bor.", "Sh-sh. Qiziq joyi."],
            .sweet: ["Kitob o'qiyapman. Keyin aytib beraman!", "O'qish yoqadi. Siz nimani yoqtirasiz?"],
        ],
        .actCook: [
            .sulky: ["Ovqat pishiryapman. O'zimga.", "Qozon. Men. Yolg'iz."],
            .sassy: ["Palov pishiryapman. Sizga tegmaydi.", "Qozonda nima borligini bilmaysiz. Hayajonlanmang.", "Oshpaz Rayxon ish boshida."],
            .sweet: ["Palov pishiryapman! Hidini sezyapsizmi?", "Sizga ham pishirdim. Xayolan, lekin mehr bilan."],
        ],
        .actLie: [
            .sulky: ["Yotaman. Charchadim.", "Dam olaman. Jim."],
            .sassy: ["Yotib olaman. Siz ishlang, men nazorat qilaman.", "Gorizontal holat. Eng samarali.", "Biroz yotib olay. Siz ko'rmagandek bo'ling."],
            .sweet: ["Biroz yotaman. Siz ham dam oling, mayli?", "Shu yerda yotsam bo'ladimi? Rahmat."],
        ],
        .actTea: [
            .sulky: ["Choy. O'zimga.", "Choy ichaman."],
            .sassy: ["Ko'k choy. Sizga qora kofe, bilaman.", "Choy ichyapman. Piyola bitta.", "Choy vaqti. Dasturchilar buni unutadi."],
            .sweet: ["Choy damladim! Siz ham iching.", "Issiq choy, yaxshi kayfiyat."],
        ],
        .actDastarxon: [
            .sulky: ["Ovqatlanyapman.", "Dasturxon. Men. Siz ishlang."],
            .sassy: ["Dasturxonga o'tirdim. Siz ovqatlandingizmi? Shubham bor.", "Non ushatdim. Sizga ham yetadi, nazariy jihatdan.", "Ovqatlanyapman. Qarab turmang."],
            .sweet: ["Ovqat vaqti! Siz ham yeb oling.", "Dasturxon yoyildi. Keling!"],
        ],
        .morning: [
            .sulky: ["Xayrli tong. Kechagi gap esimda.", "Tong. Men uyg'oq edim. Siz yo'q edingiz."],
            .sassy: ["Xayrli tong! Kofe? Yo'q, avval suv.", "Tong otdi. Kod o'zini yozmaydi.", "Uyg'ondingizmi? Men allaqachon ishdaman."],
            .sweet: ["Xayrli tong! Sizni sog'indim.", "Tong otdi! Bugun zo'r kun bo'ladi, his qilyapman."],
        ],
        .lunch: [
            .sulky: ["Tushlik. Boring.", "Ovqat. Hozir."],
            .sassy: ["Tushlik vaqti. Klaviatura ustida yemang.", "Ovqatlanmasangiz, men ham yemayman. Ha, bu tahdid.", "Tushlik! Palov bo'lsa menga ham."],
            .sweet: ["Tushlik vaqti! Yaxshi ovqatlaning, iltimos.", "Ovqat vaqti. Men sizni kutaman."],
        ],
        .evening: [
            .sulky: ["Kech bo'ldi. Yoping.", "Bugun yetarli."],
            .sassy: ["Soat 21. Kodni yoping, hayot kutyapti.", "Kech. Ertaga ham kun bor, ishoning.", "Bugun nima qildik? Hisobot kutaman... hazil. Dam oling."],
            .sweet: ["Kech bo'ldi. Bugun zo'r ishladingiz.", "Dam oling. Men ham uxlayman. Xayrli tun!"],
        ],
        .night: [
            .sulky: ["Tun. Men uxlayman. Siz ham.", "Zzz."],
            .sassy: ["Tun yarmi. Men uxlayman, siz ham uxlang.", "Tungi kod ertalab xato bo'ladi. Uxlang.", "Soat nechaligini bilasizmi? Men bilaman. Zzz."],
            .sweet: ["Xayrli tun. Ertaga ko'rishamiz.", "Uxlang, azizim. Men shu yerdaman."],
        ],
        .userAway: [
            .sulky: ["Ketdingizmi? Mayli.", "..."],
            .sassy: ["Tirikmisiz? 10 daqiqa jim.", "Qayerdasiz? Kompyuter sog'indi.", "Hey? Bormisiz?"],
            .sweet: ["Qayerdasiz? Sog'indim.", "Bormisiz? Men kutaman."],
        ],
        .userGone: [
            .sulky: ["Ketdi. Uxlayman.", "Yolg'iz qoldim. Odatdagidek."],
            .sassy: ["Yarim soat yo'qsiz. Men uxlab olaman.", "Ketdingiz. Men ham dam olaman."],
            .sweet: ["Uzoq ketdingiz... dam olaman. Qaytganingizda uyg'oting."],
        ],
        .userBack: [
            .sulky: ["Qaytdingizmi. Hm.", "Keldingiz."],
            .sassy: ["Qaytdingiz! Qayerda edingiz?", "O, tirik ekansiz.", "Keldingizmi? Ishga!"],
            .sweet: ["Qaytdingiz! Xursandman.", "Sizni sog'indim! Qayerda edingiz?"],
        ],
        .cursorNear: [
            .sulky: ["Nima?", "Yaqin kelmang."],
            .sassy: ["Nima qarayapsiz?", "Kursor bilan tegmang.", "Ha? Menda nima bor?"],
            .sweet: ["Hihi, qitiq.", "Salom! Nima kerak?"],
        ],
        .hardLanding: [
            .sulky: ["Tashladingiz. Boshim... Rahmat.", "Yulduzlar ko'rinyapti. Sizning aybingiz."],
            .sassy: ["Voy! Shunaqa balanddan tashlaydimi?!", "Boshim aylandi... yulduzlar... Sizni eslab qolaman.", "Men qush emasman! Sekinroq qo'ying."],
            .sweet: ["Voy-voy... hammasi aylanyapti. Ushlab turing meni.", "Ohh... baland edi. Hechqisi yo'q, tirikman."],
        ],
        .distracted: [
            .sulky: ["10 daqiqa. Ish qani?", "Telegram ish emas."],
            .sassy: ["10 daqiqa bo'ldi. Bu ishmi yoki... hm?", "Telegram ishga kirmaydi, aytib qo'yay.", "Skroll, skroll. Kod o'zini yozmaydi."],
            .sweet: ["Dam olyapsizmi? Mayli, lekin 5 daqiqa, keyin kod.", "Hey, qaytamizmi? Men kutyapman."],
        ],
        .backToWork: [
            .sulky: ["Nihoyat.", "Qaytdingiz. Hm."],
            .sassy: ["O, ishga qaytdik! Qoyil.", "Ha, mana bu boshqa gap.", "Fokus! Men kuzataman."],
            .sweet: ["Zo'r, ishga qaytdik!", "Siz uddalaysiz!"],
        ],
        .startedCoding: [
            .sulky: ["Kod. Mayli.", "Yozing."],
            .sassy: ["Kod yozyapsizmi? Buglarga salom ayting.", "O, redaktor ochildi. Jiddiy odam.", "Kod vaqti. Men jim turaman... 10 daqiqa."],
            .sweet: ["Kod yozyapsiz! Men yoningizdaman.", "Omad! Buglar qochsin."],
        ],
        .openedMessaging: [
            .sulky: ["Kim yozdi? Mayli, aytmang.", "Yana telefon."],
            .sassy: ["Kim yozdi? Ko'rsating. Yo'q, ko'rsatmang. Ko'rsating!", "Telegram... Men bilan gaplashmaysiz, u bilan gaplashasiz.", "Kimdir yozdi-ya? Rashk qilyapman. Ozgina."],
            .sweet: ["Kimdir yozdimi? Salom ayting mendan.", "Xabar keldimi? Yaxshi xabar bo'lsin."],
        ],
        .commit: [
            .sulky: ["Commit. Yaxshi.", "Bitta commit. Davom eting."],
            .sassy: ["Commit! Buzilmagan bo'lsa yaxshi. Hihi.", "Ura, commit! Juma emas-ku? Yaxshi.", "Commit qildingiz! Men ham xursandman. Ozgina."],
            .sweet: ["Commit! Barakalla!", "Yangi commit! Siz zo'rsiz!"],
        ],
        .peekaboo: [
            .sulky: ["...Bo.", "Men shu yerdaman."],
            .sassy: ["Bo! Qo'rqdingizmi? Hihi.", "Ku-ku! Meni yo'qotdingizmi?", "Yashiringan edim. Hech kim qidirmadi."],
            .sweet: ["Ku-ku! Men keldim!", "Bo! Hihi, sog'indingizmi?"],
        ],
        .chaseFail: [
            .sulky: ["Charchadim. Bo'ldi.", "Quvmayman."],
            .sassy: ["Uf, charchadim. Kursoringiz tez ekan.", "Ushlay olmadim. Keyingi safar.", "Bo'ldi, o'tiraman. Siz yuguring."],
            .sweet: ["Hihi, tez ekansiz! Dam olay.", "Uf... o'yin yoqdi, lekin charchadim."],
        ],
        .bread: [
            .sulky: ["Non. Rahmat.", "Yedim."],
            .sassy: ["Non! Issiqmi? Issiq emas. Baribir rahmat.", "O, non! Siz ham yeng, faqat klaviaturaga emas.", "Non tushdi. Osmondan. Mo''jiza."],
            .sweet: ["Non! Rahmat! Siz eng yaxshisiz!", "Mmm, issiq non! Yarmi sizga."],
        ],
        .parachute: [
            .sulky: ["Oyna yopildi. Parashyut bor.", "Uchyapman. Mayli."],
            .sassy: ["Oyna ketdi! Yaxshiyam parashyut olgandim.", "Uchyapmaaan! Pastda ushlang!", "Parashyut! Kim aytdi men tayyor emasman?"],
            .sweet: ["Uuuchyapman! Qarang!", "Parashyut bilan! Zo'r-ku!"],
        ],
        .catVisit: [
            .sulky: ["Mushuk keldi. Hech bo'lmasa u e'tibor beradi.", "Mushuk. Yaxshi."],
            .sassy: ["Mushuk keldi! Uning ismi Mo'ylov. Hihi.", "Mo'ylov! Yana kelibdi. Palov hidini sezgan.", "Mushuk bilan gaplashyapman. Siz band edingiz."],
            .sweet: ["Mo'ylov keldi! Qarang qanday shirin!", "Mushukcha! Siz ham silang!"],
        ],
        .peerHello: [
            .sulky: ["Boshqa Rayxon bor ekan. Hm.", "U ham yolg'izmi?"],
            .sassy: ["Tarmoqda yana bitta men bor! Salom, men!", "Boshqa Mac'da ham qiz bor ekan. Kim chiroyliroq? Men.", "Qo'shni Rayxon salom aytdi. Gap sotdik."],
            .sweet: ["Dugonam topildi! Tarmoqda!", "Salom dedik bir-birimizga! Yaxshi qiz ekan."],
        ],
        .rain: [
            .sulky: ["Yomg'ir. Soyabon oldim. Siz ham oling.", "Yomg'ir yog'yapti. Kayfiyatimga mos."],
            .sassy: ["Yomg'ir! Soyabon oldim. Siz ho'l bo'lasiz, men yo'q.", "Tashqarida yomg'ir. Ichkarida siz. Ikkalasi ham ho'l.", "Soyabon ochdim. Pastda ishlang, tomchilamasin."],
            .sweet: ["Yomg'ir yog'yapti. Soyabon bor, kelasizmi?", "Yomg'ir ovozi yoqadi. Choy damlaymi?"],
        ],
        .rainStopped: [
            .sulky: ["Yomg'ir to'xtadi.", "Soyabonni yopdim."],
            .sassy: ["Yomg'ir to'xtadi. Soyabon ortiqcha bo'lib qoldi.", "Quyosh chiqdi. Derazadan qarang, bir marta."],
            .sweet: ["Yomg'ir to'xtadi! Sayrga chiqamizmi?", "Havo ochildi. Zo'r!"],
        ],
        .snow: [
            .sulky: ["Qor. Sovuq. Qor odam yasadim, u ham sovuq.", "Qor yog'yapti. Men ichkaridaman, baribir."],
            .sassy: ["Qor yog'yapti! Qor odam yasadim, ismi Qorvoy.", "Qor! Qorvoy keldi. U sizdan ko'ra ko'proq gaplashadi.", "Tashqarida qor. Qorvoyga do'ppi kiydirdim."],
            .sweet: ["Qor yog'yapti! Qarang, qor odam yasadim!", "Qor! Issiq choy va qor odam. Mukammal."],
        ],
        .birthday: [
            .sulky: ["Tug'ilgan kuningiz bilan. Tort oldim. Yarmi meniki.", "Bugun sizniki. Mayli, tabriklayman."],
            .sassy: ["Tug'ilgan kuningiz bilan! Tort pishirdim. Shamni men puflayman.", "Bugun tug'ilgan kuningiz! Sovg'a? Men. Men sovg'aman.", "Bayram! Bugun kod yozish taqiqlanadi. Mening qarorim."],
            .sweet: ["Tug'ilgan kuningiz bilan! Siz eng yaxshisiz!", "Bayramingiz muborak! Tort, sovg'a va men — hammasi siz uchun!"],
        ],
        .memoryCleared: [
            .sulky: ["Unutdim. Hammasini.", "Bo'ldi."],
            .sassy: ["Bo'ldi. Siz kim edingiz?", "Xotira tozalandi. Tanishamizmi?"],
            .sweet: ["Unutdim... lekin sizni yana taniyman!", "Boshidan boshlaymiz!"],
        ],
    ]

    static func line(for event: Event, tone: Mood.Tone, name: String, task: String = "") -> String {
        let pool = table[event]?[tone] ?? table[event]?[.sassy] ?? ["..."]
        return (pool.randomElement() ?? "...")
            .replacingOccurrences(of: "{name}", with: name)
            .replacingOccurrences(of: "{task}", with: task)
    }

    /// Unprompted chatter, time- and task-aware.
    static func chatter(hour: Int, tone: Mood.Tone, openTasks: Int, name: String) -> String {
        var rng = SystemRandomNumberGenerator()
        return chatter(hour: hour, tone: tone, openTasks: openTasks, name: name, using: &rng)
    }

    static func chatter<G: RandomNumberGenerator>(hour: Int, tone: Mood.Tone, openTasks: Int, name: String,
                                                  relationship: Relationship = .friend, using rng: inout G) -> String {
        var pool: [String] = []
        pool += relationship.chatter(tone: tone, name: name)
        pool += relationship.chatter(tone: tone, name: name)   // weight relationship flavor ×2
        switch hour {
        case 0..<5:
            pool += ["Soat \(hour). Uxlamaysizmi? Men uxlayman.", "Tunda yozilgan kod ertalab xato bo'ladi. Uxlang.", "Kech bo'ldi. Kompyuter ham charchadi."]
        case 5..<10:
            pool += ["Xayrli tong! Choy ichdingizmi?", "Ertalab. Eng yaxshi kod shu paytda yoziladi.", "Nonushta qildingizmi? Men qildim. Hayolan."]
        case 10..<13:
            pool += ["Ishlar qanday? Men kuzatyapman.", "Tushlikgacha bitta vazifa. Kelishdikmi?", "Diqqat! Fokus! Men yoningizdaman."]
        case 13..<15:
            pool += ["Tushlik qildingizmi? Yo'qmi? Boring.", "Tushdan keyin uyqu keladi. Suv iching.", "Palov vaqti. Rasmiy e'lon."]
        case 15..<19:
            pool += ["Kun tugayapti. Nima qildik bugun?", "Yana bir soat, keyin dam.", "Ko'zingizni uqalang. Men ko'rdim."]
        default:
            pool += ["Kech. Bugun yetarli emasmi?", "Oqshom. Kodni yoping, hayotni oching.", "Soat \(hour). Ertaga ham kun bor."]
        }
        if openTasks > 0 {
            pool += ["Ro'yxatda \(openTasks) ta vazifa bor. Eslatib qo'ydim.", "\(openTasks) ta vazifa sizni kutyapti. Men ham."]
        }
        switch tone {
        case .sulky: pool += ["Men bu yerdaman. Hali ham.", "Gaplashmaysiz ham. Mayli.", "Unutdingiz meni, bilaman.",
                              "Men bilan o'ynamaysiz. Hech qachon.", "Hey. Ha, siz. Men ham odamman. Deyarli."]
        case .sassy: pool += ["Zerikdim. Biror qiziq narsa ayting.", "Tirikmisiz? Men ha.", "Kodingiz chiroyli ekanmi? Mening kiyimim chiroyliroq.",
                              "Heyy! Nima qilyapsiz?", "Men bilan o'ynamaysiz-a? Mayli, kodingiz bilan o'ynang.",
                              "Hey, bir daqiqa. Boshimni silang. Keyin ishlang.", "Nima yozyapsiz? Menga ko'rsating. Yo'q, mayli, tushunmayman.",
                              "Bugun nima rejangiz bor? Men bilan o'ynash ro'yxatda yo'q, bilaman."]
        case .sweet: pool += ["Siz bilan ishlash yoqadi.", "Bugun ajoyib ko'rinasiz. Ha, ko'raman.", "Men baxtliman. Shunchaki aytmoqchi edim.",
                              "Heyy! Nima qilyapsiz? Men qarab turibman.", "Birga o'ynaymizmi? Boshimni silang, bo'ldi.", "Siz borligingizdan xursandman."]
        }
        return pool.randomElement(using: &rng)!.replacingOccurrences(of: "{name}", with: name)
    }
}
