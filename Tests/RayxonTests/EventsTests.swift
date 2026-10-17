import Testing
import Foundation
@testable import Rayxon

struct BirthdayTests {
    func d(_ m: Int, _ day: Int, year: Int = 2026) -> Date {
        var c = DateComponents(); c.year = year; c.month = m; c.day = day; c.hour = 10
        return Calendar(identifier: .gregorian).date(from: c)!
    }
    @Test func matchesMonthAndDayOnly() {
        #expect(Birthday.isToday(birthday: d(3, 21, year: 1995), now: d(3, 21)))
        #expect(!Birthday.isToday(birthday: d(3, 21, year: 1995), now: d(3, 22)))
    }
    @Test func ageIsComputed() {
        #expect(Birthday.age(birthday: d(3, 21, year: 1995), now: d(3, 21)) == 31)
    }
}

struct WeatherEventTests {
    @Test func rainAndSnowProduceDistinctEventsOnce() {
        var t = WeatherEvents()
        #expect(t.update(Weather(temperature: 8, code: 61, wind: 5)) == .rainStarted)
        #expect(t.update(Weather(temperature: 8, code: 63, wind: 5)) == nil)         // still raining
        #expect(t.update(Weather(temperature: 8, code: 1, wind: 5)) == .rainStopped)
        #expect(t.update(Weather(temperature: -2, code: 71, wind: 5)) == .snowStarted)
    }
}

struct HotKeyTests {
    @Test func parsesCarbonModifiers() {
        #expect(HotKey.carbonModifiers(option: true, command: false, control: false, shift: false) == 2048)
        #expect(HotKey.carbonModifiers(option: true, command: true, control: false, shift: false) == 2048 + 256)
    }
}
