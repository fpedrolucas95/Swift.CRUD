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
    var title: String
    var notes: String
    var timestamp: Date
    var isFavorite: Bool

    init(
        title: String,
        notes: String = "",
        timestamp: Date = .now,
        isFavorite: Bool = false
    ) {
        self.title = title
        self.notes = notes
        self.timestamp = timestamp
        self.isFavorite = isFavorite
    }
}
