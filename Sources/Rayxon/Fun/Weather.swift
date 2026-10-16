import Foundation

/// Open-Meteo current weather (no API key). Default: Tashkent.
struct Weather: Sendable, Equatable {
    var temperature: Double
    var code: Int
    var wind: Double

    var isRaining: Bool { (51...67).contains(code) || (80...82).contains(code) || (95...99).contains(code) }
    var isSnowing: Bool { (71...77).contains(code) || code == 85 || code == 86 }

    var summaryUz: String {
        let t = Int(temperature.rounded())
        if isSnowing { return "Tashqarida qor, \(t)°. Chapan kiydim." }
        if isRaining { return "Tashqarida yomg'ir, \(t)°. Soyabon oldingizmi?" }
        if temperature <= 5 { return "Tashqarida \(t)°, sovuq. Men chapan kiydim, siz ham issiq kiyining." }
        if temperature >= 32 { return "Tashqarida \(t)°, jazirama. Suv! Ko'proq suv!" }
        return "Tashqarida \(t)°, yaxshi havo. Bir aylanib kelsangiz bo'ladi."
    }

    static func parse(_ data: Data) throws -> Weather {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let cur = json["current"] as? [String: Any],
              let t = cur["temperature_2m"] as? Double else { throw LLMError.badResponse("weather") }
        return Weather(temperature: t, code: cur["weather_code"] as? Int ?? 0, wind: cur["wind_speed_10m"] as? Double ?? 0)
    }

    static func fetch(latitude: Double = 41.3111, longitude: Double = 69.2797) async throws -> Weather {
        let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current=temperature_2m,weather_code,wind_speed_10m")!
        return try parse(try await LLMHTTP.send(URLRequest(url: url)))
    }

    /// Cold → quilted adras chapan, hot → light atlas; nil = keep current.
    static func suggestedOutfit(temperature: Double, available: [String]) -> String? {
        if temperature <= 10, available.contains("adras") { return "adras" }
        if temperature >= 28, available.contains("atlas") { return "atlas" }
        return nil
    }
}
