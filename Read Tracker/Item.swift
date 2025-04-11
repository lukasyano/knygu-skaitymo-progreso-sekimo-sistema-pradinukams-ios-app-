//
//  Item.swift
//  Read Tracker
//
//  Created by Lukas Toliusis on 11/04/2025.
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
