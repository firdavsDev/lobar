import Foundation

/// Turns successive weather samples into one-shot transitions.
struct WeatherEvents: Sendable {
    enum Event: Sendable, Equatable { case rainStarted, rainStopped, snowStarted, snowStopped }
    private var raining = false
    private var snowing = false

    mutating func update(_ w: Weather) -> Event? {
        if w.isSnowing != snowing {
            snowing = w.isSnowing
            if snowing { raining = false; return .snowStarted } else { return .snowStopped }
        }
        if w.isRaining != raining {
            raining = w.isRaining
            return raining ? .rainStarted : .rainStopped
        }
        return nil
    }
}
