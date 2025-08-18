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
        ("creamGreen", "크림 그린", Color.green),
        ("softBlue", "소프트 블루", Color.blue),
        ("warmPink", "웜 핑크", Color.pink),
        ("mintGreen", "민트 그린", Color.mint)
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: $enableNotifications) {
                        Label("알림 받기", systemImage: "bell")
                    }
                    .onChange(of: enableNotifications) { _, newValue in
                        if newValue {
                            requestNotificationPermission()
                        }
                        updateSettings()
                    }
                    
                    if enableNotifications {
                        Picker("알림 시간", selection: $reminderHour) {
                            ForEach(6..<23) { hour in
                                Text("\(hour):00").tag(hour)
                            }
                        }
                        .onChange(of: reminderHour) { _, _ in
                            updateSettings()
                            scheduleNotifications()
                        }
                    }
                } header: {
                    Text("알림 설정")
                } footer: {
                    Text("매일 설정한 시간에 약속을 상기시켜드려요")
                }
                
                Section {
                    ForEach(themes, id: \.0) { theme in
                        HStack {
                            Circle()
                                .fill(theme.2)
                                .frame(width: 24, height: 24)
                            
                            Text(theme.1)
                            
                            Spacer()
                            
                            if selectedTheme == theme.0 {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedTheme = theme.0
                            updateSettings()
                        }
                    }
                } header: {
                    Text("테마")
                }
                
                Section {
                    Toggle(isOn: $useCloudSync) {
                        Label("iCloud 동기화", systemImage: "icloud")
                    }
                    .onChange(of: useCloudSync) { _, _ in
                        updateSettings()
                    }
                } header: {
                    Text("데이터")
                } footer: {
                    Text("여러 기기에서 데이터를 동기화합니다")
                }
                
                Section {
                    Button {
                        showingResetAlert = true
                    } label: {
                        Label("모든 데이터 초기화", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                } footer: {
                    Text("모든 약속과 기록이 삭제됩니다. 이 작업은 취소할 수 없습니다.")
                }
                
                Section {
                    HStack {
                        Text("버전")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com/yakusoku")!) {
                        HStack {
                            Label("GitHub", systemImage: "link")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("정보")
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
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