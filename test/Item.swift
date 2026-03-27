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
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
