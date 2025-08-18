import SwiftData
import Foundation

@Model
final class Commitment {
    @Attribute(.unique) var id: String
    var title: String
    var pros: String?
    var cons: String?
    var ifThen: String?
    var priority: Int
    var createdAt: Date
    var archivedAt: Date?
    
    init(
        id: String = UUID().uuidString,
        title: String,
        pros: String? = nil,
        cons: String? = nil,
        ifThen: String? = nil,
        priority: Int = 0,
        createdAt: Date = .now,
        archivedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.pros = pros
        self.cons = cons
        self.ifThen = ifThen
        self.priority = priority
        self.createdAt = createdAt
        self.archivedAt = archivedAt
    }
}