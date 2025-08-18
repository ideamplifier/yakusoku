import SwiftData
import Foundation

enum SharedContainer {
    static let appGroupIdentifier = "group.app.yakusoku"
    
    static func container() throws -> ModelContainer {
        // App Group이 설정되지 않은 경우 기본 Documents 디렉토리 사용
        let url: URL
        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) {
            url = containerURL.appendingPathComponent("Yakusoku.sqlite")
        } else {
            // App Group이 없을 때 Documents 디렉토리 사용
            let documentsURL = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first!
            url = documentsURL.appendingPathComponent("Yakusoku.sqlite")
        }
        
        let config = ModelConfiguration(url: url)
        
        return try ModelContainer(
            for: Commitment.self,
            Checkin.self,
            AppSetting.self,
            configurations: config
        )
    }
}