import SwiftData
import Foundation

@Model
final class AppSetting {
    var useCloudSync: Bool
    var preferredTheme: String
    var defaultReminderHour: Int
    var enableNotifications: Bool
    
    init(
        useCloudSync: Bool = false,
        preferredTheme: String = "creamGreen",
        defaultReminderHour: Int = 11,
        enableNotifications: Bool = true
    ) {
        self.useCloudSync = useCloudSync
        self.preferredTheme = preferredTheme
        self.defaultReminderHour = defaultReminderHour
        self.enableNotifications = enableNotifications
    }
}