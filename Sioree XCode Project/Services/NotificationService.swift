//
//  NotificationService.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation
import UserNotifications
import UIKit

class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    // Request push notification permissions
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ Notification authorization error: \(error)")
            } else if granted {
                print("✅ Push notifications authorized")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("⚠️ Push notifications denied")
            }
        }
    }
    
    // Schedule a local notification
    func scheduleNotification(title: String, body: String, identifier: String, timeInterval: TimeInterval = 1.0) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error)")
            } else {
                print("✅ Notification scheduled: \(title)")
            }
        }
    }
    
    // Send notification for signup
    func notifySignup(userName: String) {
        scheduleNotification(
            title: "Welcome to Sioree! 🎉",
            body: "Hi \(userName), thanks for joining Sioree!",
            identifier: "signup_\(UUID().uuidString)"
        )
    }
    
    // Send notification for login
    func notifyLogin(userName: String) {
        scheduleNotification(
            title: "Welcome back! 👋",
            body: "Hi \(userName), welcome back to Sioree!",
            identifier: "login_\(UUID().uuidString)"
        )
    }
    
    // Send notification for new message
    func notifyNewMessage(from userName: String, message: String) {
        scheduleNotification(
            title: "New message from \(userName)",
            body: message,
            identifier: "message_\(UUID().uuidString)"
        )
    }
    
    // Send notification for event RSVP
    func notifyEventRSVP(eventName: String) {
        scheduleNotification(
            title: "Event RSVP Confirmed ✅",
            body: "You're going to \(eventName)! Check your tickets for the QR code.",
            identifier: "rsvp_\(UUID().uuidString)"
        )
    }
}








