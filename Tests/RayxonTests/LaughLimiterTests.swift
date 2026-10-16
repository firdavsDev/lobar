import Testing
@testable import Rayxon

struct LaughLimiterTests {
    @Test func allowsFirstLaughThenStripsForAWhile() {
        var l = LaughLimiter()
        #expect(l.filter("Yutdim! Hihi.") == "Yutdim! Hihi.")
        #expect(l.filter("Non! Hihi, rahmat.") == "Non! Rahmat.")
        #expect(l.filter("Ha-ha, yana?") == "Yana?")
        #expect(l.filter("Oddiy gap.") == "Oddiy gap.")
        #expect(l.filter("Hm, hihi") == "Hm, hihi")       // cooldown over → allowed again
        #expect(l.filter("Yana hihi") == "Yana")          // and the next one is stripped
    }

    @Test func keepsSentenceReadable() {
        var l = LaughLimiter(); _ = l.filter("Hihi")
        #expect(l.filter("Hihi, qo'ying meni!") == "Qo'ying meni!")
        #expect(l.filter("Voy! Ha-ha! Tushdim.") == "Voy! Tushdim.")
    }
}
