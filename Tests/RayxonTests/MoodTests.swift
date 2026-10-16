import Testing
@testable import Rayxon

struct MoodTests {
    @Test func headPatsRaiseAffectionWithDiminishingReturns() {
        var m = Mood(affection: 50)
        let first = m.headPat(at: 0)
        #expect(first == .pleased)
        #expect(m.affection > 50)
        _ = m.headPat(at: 5); _ = m.headPat(at: 10)
        let fourth = m.headPat(at: 12)
        #expect(fourth == .annoyed)       // 4 pats within a minute → too much
    }

    @Test func shakingLowersAffection() {
        var m = Mood(affection: 50)
        m.shaken(at: 0)
        #expect(m.affection < 50)
    }

    @Test func affectionDecaysWithNeglect() {
        var m = Mood(affection: 80)
        m.decay(hoursSinceLastInteraction: 24)
        #expect(m.affection < 80)
        #expect(m.affection >= 0)
    }

    @Test func toneFollowsAffection() {
        #expect(Mood(affection: 10).tone == .sulky)
        #expect(Mood(affection: 50).tone == .sassy)
        #expect(Mood(affection: 90).tone == .sweet)
    }

    @Test func clickSpamIsAnnoying() {
        var m = Mood(affection: 50)
        var annoyed = false
        for i in 0..<8 { if m.clicked(at: Double(i) * 0.3) { annoyed = true } }
        #expect(annoyed)
    }
}

struct PhraseBookTests {
    @Test func pickRespectsToneAndNeverEmpty() {
        for tone in [Mood.Tone.sulky, .sassy, .sweet] {
            for event in PhraseBook.Event.allCases {
                #expect(!PhraseBook.line(for: event, tone: tone, name: "Rayxon").isEmpty)
            }
        }
    }

    @Test func chatterIsTimeAwareAndVaried() {
        var rng = SeededRNG(state: 11)
        var lines = Set<String>()
        for _ in 0..<60 { lines.insert(PhraseBook.chatter(hour: 2, tone: .sassy, openTasks: 2, name: "Rayxon", using: &rng)) }
        #expect(lines.count >= 6)
        #expect(lines.contains { $0.lowercased().contains("uxla") || $0.contains("tun") || $0.contains("Kech") || $0.contains("Soat") })
        #expect(lines.contains { $0.contains("2 ta vazifa") })
        #expect(lines.allSatisfy { !$0.isEmpty })
    }
}
