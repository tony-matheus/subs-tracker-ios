import Foundation

/// `satoru://` URLs opened by widgets (and anything else that links in).
enum DeepLink: Equatable {
    /// Opens the add-expense sheet.
    case add
    /// Opens the day sheet for that date.
    case day(Date)

    static let scheme = "satoru"

    /// yyyy-MM-dd in the user's timezone, so a local day round-trips exactly.
    private static var dayFormat: Date.ISO8601FormatStyle {
        Date.ISO8601FormatStyle(timeZone: .current).year().month().day()
    }

    var url: URL {
        switch self {
        case .add:
            URL(string: "\(Self.scheme)://add")!
        case .day(let date):
            URL(string: "\(Self.scheme)://day/\(date.formatted(Self.dayFormat))")!
        }
    }

    init?(url: URL) {
        guard url.scheme == Self.scheme else { return nil }
        switch url.host() {
        case "add":
            self = .add
        case "day":
            guard let date = try? Self.dayFormat.parse(url.lastPathComponent) else { return nil }
            self = .day(date)
        default:
            return nil
        }
    }
}
