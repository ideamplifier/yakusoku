//
//  Item.swift
//  YAKUSOKU
//
//  Created by EUIHYUNG JUNG on 8/18/25.
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
