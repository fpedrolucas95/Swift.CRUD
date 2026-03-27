//
//  Item.swift
//  test
//
//  Created by Pedro Lucas França on 27/03/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var uuid: String = UUID().uuidString
    var title: String
    var notes: String
    var timestamp: Date
    var isFavorite: Bool
    var recurrence: String = "none"
    var reminderEnabled: Bool = false
    var reminderMinutesBefore: Int = 0

    init(
        title: String,
        notes: String = "",
        timestamp: Date = .now,
        isFavorite: Bool = false,
        recurrence: String = "none",
        reminderEnabled: Bool = false,
        reminderMinutesBefore: Int = 0,
        uuid: String = UUID().uuidString
    ) {
        self.uuid = uuid
        self.title = title
        self.notes = notes
        self.timestamp = timestamp
        self.isFavorite = isFavorite
        self.recurrence = recurrence
        self.reminderEnabled = reminderEnabled
        self.reminderMinutesBefore = reminderMinutesBefore
    }
}
