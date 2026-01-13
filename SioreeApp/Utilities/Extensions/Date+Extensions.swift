//
//  Date+Extensions.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation

extension Date {
    func formattedEventDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: self)
    }
    
    func formattedEventTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
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

