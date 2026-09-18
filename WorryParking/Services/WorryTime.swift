import SwiftUI

/// Helpers around the user's daily "Worry Time" — the scheduled window
/// where parked worries come back for review (worry postponement).
enum WorryTime {
    static let defaultHour = 18
    static let defaultMinute = 0

    /// The next occurrence of the Worry Time that is at least `minimumLead` away.
    static func next(
        hour: Int,
        minute: Int,
        after date: Date = .now,
        minimumLead: TimeInterval = 30 * 60
    ) -> Date {
        let earliest = date.addingTimeInterval(minimumLead)
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        components.second = 0
        return Calendar.current.nextDate(
            after: earliest,
            matching: components,
            matchingPolicy: .nextTime
        ) ?? earliest.addingTimeInterval(24 * 60 * 60)
    }

    static func sameTimeNextDay(after date: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date.addingTimeInterval(24 * 60 * 60)
    }

    /// "today at 6:00 PM", "tomorrow at 6:00 PM", or "Friday 6:00 PM".
    static func describe(_ date: Date) -> String {
        let calendar = Calendar.current
        let time = date.formatted(date: .omitted, time: .shortened)
        if calendar.isDateInToday(date) { return "today at \(time)" }
        if calendar.isDateInTomorrow(date) { return "tomorrow at \(time)" }
        return date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day().hour().minute())
    }

    static func timeString(hour: Int, minute: Int) -> String {
        let date = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }

    /// Bridges two stored Int values (hour / minute) to a Date for DatePicker.
    static func dateBinding(hour: Binding<Int>, minute: Binding<Int>) -> Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: hour.wrappedValue,
                    minute: minute.wrappedValue,
                    second: 0,
                    of: .now
                ) ?? .now
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                hour.wrappedValue = components.hour ?? defaultHour
                minute.wrappedValue = components.minute ?? defaultMinute
            }
        )
    }
}
