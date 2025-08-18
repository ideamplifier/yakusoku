import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSetting]
    
    @State private var enableNotifications = true
    @State private var reminderHour = 11
    @State private var useCloudSync = false
    @State private var selectedTheme = "creamGreen"
    @State private var showingResetAlert = false
    @State private var notificationPermissionStatus = false
    
    private var currentSettings: AppSetting? {
        settings.first
    }
    
    let themes = [
        ("retro", "레트로", YKColor.green),
        ("creamGreen", "크림 그린", YKColor.green),
        ("warmRed", "웜 레드", YKColor.red),
        ("sunnyYellow", "써니 옐로우", YKColor.yellow)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 알림 설정
                    VStack(alignment: .leading, spacing: 16) {
                        Text("알림 설정")
                            .font(.headline)
                            .foregroundStyle(YKColor.primaryText)
                        
                        VStack(spacing: 16) {
                            HStack {
                                Label("알림 받기", systemImage: "bell.fill")
                                    .foregroundStyle(YKColor.green)
                                
                                Spacer()
                                
                                Toggle("", isOn: $enableNotifications)
                                    .labelsHidden()
                                    .tint(YKColor.green)
                            }
                            
                            if enableNotifications {
                                HStack {
                                    Label("알림 시간", systemImage: "clock.fill")
                                        .foregroundStyle(YKColor.green.opacity(0.7))
                                    
                                    Spacer()
                                    
                                    Picker("", selection: $reminderHour) {
                                        ForEach(6..<23) { hour in
                                            Text("\(hour):00").tag(hour)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(YKColor.green)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(YKColor.mint.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                        
                        Text("매일 설정한 시간에 약속을 상기시켜드려요")
                            .font(.caption)
                            .foregroundStyle(YKColor.secondaryText)
                    }
                    .stickerCard()
                    
                    // 테마 설정
                    VStack(alignment: .leading, spacing: 16) {
                        Text("테마")
                            .font(.headline)
                            .foregroundStyle(YKColor.primaryText)
                        
                        VStack(spacing: 12) {
                            ForEach(themes, id: \.0) { theme in
                                HStack {
                                    Circle()
                                        .fill(theme.2)
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 2)
                                        )
                                        .shadow(color: theme.2.opacity(0.3), radius: 4)
                                    
                                    Text(theme.1)
                                        .font(.subheadline)
                                        .foregroundStyle(YKColor.primaryText)
                                    
                                    Spacer()
                                    
                                    if selectedTheme == theme.0 {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(YKColor.green)
                                    }
                                }
                                .padding(12)
                                .background(
                                    selectedTheme == theme.0 
                                    ? YKColor.mint.opacity(0.15) 
                                    : Color.clear
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(
                                            selectedTheme == theme.0 
                                            ? YKColor.green.opacity(0.3) 
                                            : Color.clear, 
                                            lineWidth: 1
                                        )
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedTheme = theme.0
                                    updateSettings()
                                    HapticFeedback.light()
                                }
                            }
                        }
                    }
                    .stickerCard()
                    
                    // 데이터 설정
                    VStack(alignment: .leading, spacing: 16) {
                        Text("데이터")
                            .font(.headline)
                            .foregroundStyle(YKColor.primaryText)
                        
                        HStack {
                            Label("iCloud 동기화", systemImage: "icloud.fill")
                                .foregroundStyle(YKColor.green)
                            
                            Spacer()
                            
                            Toggle("", isOn: $useCloudSync)
                                .labelsHidden()
                                .tint(ZenColors.primaryGreen)
                        }
                        
                        Text("여러 기기에서 데이터를 동기화합니다")
                            .font(.caption)
                            .foregroundStyle(YKColor.secondaryText)
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        Button {
                            showingResetAlert = true
                            HapticFeedback.warning()
                        } label: {
                            Label("모든 데이터 초기화", systemImage: "trash.fill")
                                .foregroundStyle(YKColor.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(YKColor.red.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(YKColor.red.opacity(0.3), lineWidth: 1.5)
                                )
                        }
                        
                        Text("모든 약속과 기록이 삭제됩니다. 이 작업은 취소할 수 없습니다.")
                            .font(.caption)
                            .foregroundStyle(YKColor.red.opacity(0.7))
                    }
                    .stickerCard()
                    
                    // 정보
                    VStack(alignment: .leading, spacing: 16) {
                        Text("정보")
                            .font(.headline)
                            .foregroundStyle(YKColor.primaryText)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("버전")
                                    .foregroundStyle(YKColor.primaryText)
                                Spacer()
                                Text("1.0.0")
                                    .foregroundStyle(YKColor.secondaryText)
                            }
                            .padding(.vertical, 8)
                            
                            Divider()
                            
                            Link(destination: URL(string: "https://github.com/yakusoku")!) {
                                HStack {
                                    Label("GitHub", systemImage: "link")
                                        .foregroundStyle(YKColor.green)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundStyle(YKColor.green.opacity(0.7))
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .stickerCard()
                    
                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(YKColor.cream)
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(YKColor.green)
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
    
    private func loadSettings() {
        if let settings = currentSettings {
            enableNotifications = settings.enableNotifications
            reminderHour = settings.defaultReminderHour
            useCloudSync = settings.useCloudSync
            selectedTheme = settings.preferredTheme
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
            settings.preferredTheme = selectedTheme
        } else {
            let newSettings = AppSetting(
                useCloudSync: useCloudSync,
                preferredTheme: selectedTheme,
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
    SettingsView()
        .modelContainer(for: AppSetting.self)
}