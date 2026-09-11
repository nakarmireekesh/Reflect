import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isLockEnabled") private var isLockEnabled = false
    @AppStorage("isReminderEnabled") private var isReminderEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 20
    @AppStorage("reminderMinute") private var reminderMinute = 0
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]

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
                    ShareLink(item: markdownExportURL) {
                        Label("Export as Markdown", systemImage: "doc.text")
                    }
                    ShareLink(item: jsonExportURL) {
                        Label("Export as JSON", systemImage: "curlybraces")
                    }
                } header: {
                    Text("Export")
                } footer: {
                    Text(entries.isEmpty
                        ? "Write a few entries first, then export a copy here."
                        : "Save a copy of your journal — nothing is uploaded, you choose where it goes.")
                }
                .disabled(entries.isEmpty)
                .foregroundStyle(entries.isEmpty ? .secondary : .primary)

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

    // MARK: - Export

    private var markdownExportURL: URL {
        Self.writeTemp(JournalExporter.markdown(for: entries), named: "Reflect-Export-\(Self.exportDateStamp).md")
    }

    private var jsonExportURL: URL {
        let data = try? JournalExporter.json(for: entries)
        return Self.writeTemp(data ?? Data(), named: "Reflect-Export-\(Self.exportDateStamp).json")
    }

    private static var exportDateStamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: .now)
    }

    private static func writeTemp(_ content: String, named filename: String) -> URL {
        writeTemp(Data(content.utf8), named: filename)
    }

    private static func writeTemp(_ data: Data, named filename: String) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: url, options: .atomic)
        return url
    }
}

#Preview {
    SettingsView()
        .modelContainer(PreviewData.container)
}
