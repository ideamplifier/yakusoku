import SwiftUI
import SwiftData
import UserNotifications

struct SettingsMinimalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
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
                VStack(spacing: 12) {
                    // 알림 설정
                    WidgetBlock {
                        VStack(spacing: 16) {
                            HStack {
                                Label("알림", systemImage: "bell")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(MColor.ink)
                                
                                Spacer()
                                
                                Toggle("", isOn: $enableNotifications)
                                    .labelsHidden()
                                    .tint(MColor.green)
                            }
                            
                            if enableNotifications {
                                HStack {
                                    Text("알림 시간")
                                        .font(.subheadline)
                                        .foregroundStyle(MColor.secondaryText)
                                    
                                    Spacer()
                                    
                                    Picker("", selection: $reminderHour) {
                                        ForEach(6..<23) { hour in
                                            Text("\(hour):00").tag(hour)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(MColor.ink)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(MColor.border.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    
                    // 동기화 설정
                    WidgetBlock {
                        HStack {
                            Label("iCloud 동기화", systemImage: "icloud")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(MColor.ink)
                            
                            Spacer()
                            
                            Toggle("", isOn: $useCloudSync)
                                .labelsHidden()
                                .tint(MColor.green)
                        }
                    }
                    
                    // 데이터 관리
                    WidgetBlock {
                        VStack(spacing: 16) {
                            HStack {
                                Text("데이터")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(MColor.ink)
                                
                                Spacer()
                            }
                            
                            Button {
                                showingResetAlert = true
                                HapticFeedback.warning()
                            } label: {
                                HStack {
                                    Label("모든 데이터 초기화", systemImage: "trash")
                                        .foregroundStyle(MColor.red)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(MColor.tertiaryText)
                                }
                                .padding(12)
                                .background(MColor.red.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    
                    // 정보
                    WidgetBlock {
                        VStack(spacing: 12) {
                            HStack {
                                Text("정보")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(MColor.ink)
                                
                                Spacer()
                            }
                            
                            HStack {
                                Text("버전")
                                    .foregroundStyle(MColor.secondaryText)
                                Spacer()
                                Text("1.0.0")
                                    .foregroundStyle(MColor.tertiaryText)
                            }
                            
                            Divider()
                                .background(MColor.border)
                            
                            Link(destination: URL(string: "https://github.com/yakusoku")!) {
                                HStack {
                                    Label("GitHub", systemImage: "link")
                                        .foregroundStyle(MColor.ink)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundStyle(MColor.tertiaryText)
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 80)
                }
                .padding(16)
            }
            .background(MColor.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("설정")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(MColor.ink)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                    .foregroundStyle(MColor.ink)
                }
            }
            .alert("모든 데이터 초기화", isPresented: $showingResetAlert) {
                Button("취소", role: .cancel) { }
                Button("초기화", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("정말로 모든 약속과 기록을 삭제하시겠습니까?")
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
    
    // MARK: - Helper Methods (동일)
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
                preferredTheme: "minimal",
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
        content.body = "오늘의 약속을 한 번만 기억해봐요"
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
    SettingsMinimalView()
        .modelContainer(for: AppSetting.self)
}