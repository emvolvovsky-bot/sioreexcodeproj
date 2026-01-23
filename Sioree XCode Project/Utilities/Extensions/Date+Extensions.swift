//
//  Date+Extensions.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation

extension Date {
    private static let eventDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }()

    private static let eventTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    func formattedEventDate() -> String {
        return Self.eventDateFormatter.string(from: self)
    }

    func formattedEventTime() -> String {
        return Self.eventTimeFormatter.string(from: self)
    }
    
    func formattedRelative() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    func isToday() -> Bool {
        Calendar.current.isDateInToday(self)
    }
    
    func isTomorrow() -> Bool {
        Calendar.current.isDateInTomorrow(self)
    }
}

