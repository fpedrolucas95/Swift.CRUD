//
//  NotificationManager.swift
//  test
//
//  Created by Pedro Lucas França on 27/03/26.
//

import Foundation
import UserNotifications

enum Recurrence: String, CaseIterable, Identifiable {
    case none, daily, weekly, monthly
    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: return "Sem recorrência"
        case .daily: return "Diária"
        case .weekly: return "Semanal"
        case .monthly: return "Mensal"
        }
    }
}

struct NotificationManager {
    static func requestAuthorization() async throws {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        if !granted {
            print("[Notification] Permissão negada")
        }
    }

    static func scheduleNotification(for item: Item) async {
        guard item.reminderEnabled else { return }

        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = item.title
        content.body = item.notes.isEmpty ? "Lembrete" : item.notes
        content.sound = .default

        let triggerDate = Calendar.current.date(byAdding: .minute, value: -item.reminderMinutesBefore, to: item.timestamp) ?? item.timestamp

        let components: DateComponents
        let repeats: Bool
        switch Recurrence(rawValue: item.recurrence) ?? .none {
        case .none:
            components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            repeats = false
        case .daily:
            components = Calendar.current.dateComponents([.hour, .minute], from: triggerDate)
            repeats = true
        case .weekly:
            components = Calendar.current.dateComponents([.weekday, .hour, .minute], from: triggerDate)
            repeats = true
        case .monthly:
            components = Calendar.current.dateComponents([.day, .hour, .minute], from: triggerDate)
            repeats = true
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
        let request = UNNotificationRequest(identifier: item.uuid, content: content, trigger: trigger)
        do {
            try await center.add(request)
        } catch {
            print("[Notification] Erro ao agendar: \(error)")
        }
    }

    static func cancelNotification(for item: Item) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [item.uuid])
    }
}
