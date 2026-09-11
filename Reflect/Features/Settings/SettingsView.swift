import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isLockEnabled") private var isLockEnabled = false

    @State private var biometry = AppLockState.availableBiometry()

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
}

#Preview {
    SettingsView()
}
