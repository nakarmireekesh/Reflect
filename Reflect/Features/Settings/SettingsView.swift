import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isLockEnabled") private var isLockEnabled = false
    @AppStorage("isReminderEnabled") private var isReminderEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 20
    @AppStorage("reminderMinute") private var reminderMinute = 0

    @State private var biometry = AppLockState.availableBiometry()
    @State private var reminderDeniedMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: $isLockEnabled) {
                        Label("Require \(biometry.label)", systemImage: biometry.symbolName)
                    }
                    .tint(.brand)
                    .disabled(biometry == .unavailable)
                } header: {
                    Text("Privacy")
                } footer: {
                    Text(footer)
                }

                Section {
                    Toggle(isOn: reminderToggleBinding) {
                        Label("Daily reminder", systemImage: "bell")
                    }
                    .tint(.brand)

                    if isReminderEnabled {
                        DatePicker("Remind me at", selection: reminderTimeBinding, displayedComponents: .hourAndMinute)
                    }
                } header: {
                    Text("Reminder")
                } footer: {
                    Text(reminderDeniedMessage ?? "A gentle nudge to write, once a day.")
                }

                Section {
                    Label("Everything you write stays on this iPhone.", systemImage: "iphone")
                    Label("No account, no cloud, no one else — ever.", systemImage: "eye.slash")
                } footer: {
                    Text("Reflect's mood, theme and summary features run entirely on device using Apple's Foundation Models framework. It isn't a substitute for professional support.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var footer: String {
        switch biometry {
        case .unavailable:
            return "Set a passcode on this device in Settings to lock Reflect."
        default:
            return "When on, Reflect asks for \(biometry.label) each time you open it."
        }
    }

    private var reminderToggleBinding: Binding<Bool> {
        Binding(
            get: { isReminderEnabled },
            set: { newValue in
                guard newValue else {
                    isReminderEnabled = false
                    reminderDeniedMessage = nil
                    ReminderScheduler.cancel()
                    return
                }
                Task {
                    let granted = await ReminderScheduler.requestAuthorizationIfNeeded()
                    isReminderEnabled = granted
                    if granted {
                        reminderDeniedMessage = nil
                        ReminderScheduler.schedule(hour: reminderHour, minute: reminderMinute)
                    } else {
                        reminderDeniedMessage = "Notifications are off for Reflect. Enable them in the iPhone Settings app to get a daily reminder."
                    }
                }
            }
        )
    }

    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(from: DateComponents(hour: reminderHour, minute: reminderMinute)) ?? .now
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                reminderHour = components.hour ?? reminderHour
                reminderMinute = components.minute ?? reminderMinute
                ReminderScheduler.schedule(hour: reminderHour, minute: reminderMinute)
            }
        )
    }
}

#Preview {
    SettingsView()
}
