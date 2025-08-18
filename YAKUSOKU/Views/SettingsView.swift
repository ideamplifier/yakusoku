import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.yakusokuTheme) private var theme
    @Query private var settings: [AppSetting]
    
    @State private var enableNotifications = true
    @State private var reminderHour = 11
    @State private var useCloudSync = false
    @State private var showingResetAlert = false
    @State private var notificationPermissionStatus = false
    
    private var currentSettings: AppSetting? {
        settings.first
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: YK.Space.lg) {
                    notificationSection
                    dataSection
                    aboutSection
                }
                .padding(YK.Space.lg)
            }
            .background(theme.paper.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        TrafficDots(size: 6)
                        Text("설정")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(theme.ink)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                    .font(.system(size: 16))
                    .foregroundColor(theme.ink)
                }
            }
            .alert("데이터 초기화", isPresented: $showingResetAlert) {
                Button("취소", role: .cancel) { }
                Button("초기화", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("모든 약속과 기록이 삭제됩니다. 이 작업은 취소할 수 없습니다.")
            }
            .onAppear {
                loadSettings()
                checkNotificationPermission()
            }
            .onChange(of: enableNotifications) { _, newValue in
                if newValue {
                    requestNotificationPermission()
                }
                updateSettings()
            }
            .onChange(of: reminderHour) { _, _ in
                updateSettings()
                scheduleNotifications()
            }
            .onChange(of: useCloudSync) { _, _ in
                updateSettings()
            }
        }
    }
    
    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: YK.Space.sm) {
            sectionHeader("알림")
            
            theme.card {
                VStack(spacing: YK.Space.md) {
                    HStack {
                        Text("리마인더")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(theme.ink)
                        
                        Spacer()
                        
                        Toggle("", isOn: $enableNotifications)
                            .labelsHidden()
                            .tint(YK.ColorToken.green)
                    }
                
                    if enableNotifications {
                        Divider()
                            .background(theme.line)
                        
                        HStack {
                            Text("알림 시간")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(theme.ink)
                            
                            Spacer()
                            
                            Picker("", selection: $reminderHour) {
                                ForEach(6..<23) { hour in
                                    Text("\(hour):00")
                                        .tag(hour)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(theme.ink)
                        }
                    }
                }
            }
            
            Text("매일 설정한 시간에 약속을 상기시켜드려요")
                .font(.system(size: 12))
                .foregroundColor(theme.inkMuted)
                .padding(.horizontal, YK.Space.xs)
        }
    }
    
    private var dataSection: some View {
        VStack(alignment: .leading, spacing: YK.Space.sm) {
            sectionHeader("데이터")
            
            theme.card {
                HStack {
                    Text("iCloud 동기화")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(theme.ink)
                    
                    Spacer()
                    
                    Toggle("", isOn: $useCloudSync)
                        .labelsHidden()
                        .tint(YK.ColorToken.green)
                }
            }
                
            Text("여러 기기에서 데이터를 동기화합니다")
                .font(.system(size: 12))
                .foregroundColor(theme.inkMuted)
                .padding(.horizontal, YK.Space.xs)
                
            Button {
                showingResetAlert = true
                HapticFeedback.warning()
            } label: {
                HStack {
                    Text("모든 데이터 삭제")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(YK.ColorToken.red)
                    
                    Spacer()
                    
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(YK.ColorToken.red)
                }
                .padding(YK.Space.md)
                .frame(maxWidth: .infinity)
                .background(YK.ColorToken.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: YK.Radius.xl)
                        .stroke(YK.ColorToken.red, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: YK.Radius.xl))
            }
            
            Text("모든 약속과 기록이 삭제됩니다")
                .font(.system(size: 12))
                .foregroundColor(YK.ColorToken.red.opacity(0.7))
                .padding(.horizontal, YK.Space.xs)
        }
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: YK.Space.sm) {
            sectionHeader("정보")
            
            theme.card {
                VStack(spacing: YK.Space.md) {
                    HStack {
                        Text("버전")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(theme.ink)
                        
                        Spacer()
                        
                        Text("1.0.0")
                            .font(.system(size: 16))
                            .foregroundColor(theme.inkMuted)
                    }
                
                    Divider()
                        .background(theme.line)
                
                    Link(destination: URL(string: "https://github.com/yakusoku")!) {
                        HStack {
                            Text("GitHub")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(theme.ink)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(theme.inkMuted)
                        }
                    }
                
                    Divider()
                        .background(theme.line)
                
                    HStack {
                        Text("개발자")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(theme.ink)
                        
                        Spacer()
                        
                        Text("YAKUSOKU Team")
                            .font(.system(size: 16))
                            .foregroundColor(theme.inkMuted)
                    }
                }
            }
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(theme.inkMuted)
            .textCase(.uppercase)
            .tracking(0.5)
    }
    
    private func loadSettings() {
        if let settings = currentSettings {
            enableNotifications = settings.enableNotifications
            reminderHour = settings.defaultReminderHour
            useCloudSync = settings.useCloudSync
        } else {
            let newSettings = AppSetting()
            modelContext.insert(newSettings)
            try? modelContext.save()
        }
    }
    
    private func updateSettings() {
        if let settings = currentSettings {
            settings.enableNotifications = enableNotifications
            settings.defaultReminderHour = reminderHour
            settings.useCloudSync = useCloudSync
        } else {
            let newSettings = AppSetting(
                useCloudSync: useCloudSync,
                preferredTheme: "japanese_minimal",
                defaultReminderHour: reminderHour,
                enableNotifications: enableNotifications
            )
            modelContext.insert(newSettings)
        }
        
        try? modelContext.save()
    }
    
    private func resetAllData() {
        do {
            try modelContext.delete(model: Commitment.self)
            try modelContext.delete(model: Checkin.self)
            try modelContext.delete(model: AppSetting.self)
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to reset data: \(error)")
        }
    }
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationPermissionStatus = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                notificationPermissionStatus = granted
                if granted {
                    scheduleNotifications()
                }
            }
        }
    }
    
    private func scheduleNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        guard enableNotifications && notificationPermissionStatus else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "YAKUSOKU"
        content.body = "오늘의 약속을 확인해보세요"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = reminderHour
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}

#Preview {
    SettingsView()
        .environment(\.yakusokuTheme, MinimalRetroTheme())
        .modelContainer(for: AppSetting.self)
}