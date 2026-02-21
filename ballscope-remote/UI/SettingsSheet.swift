import SwiftUI

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    let initialSettings: AppSettings
    let onSave: (String, Int, AppAppearance) -> Void

    @State private var host: String
    @State private var portText: String
    @State private var appearance: AppAppearance

    init(initialSettings: AppSettings, onSave: @escaping (String, Int, AppAppearance) -> Void) {
        self.initialSettings = initialSettings
        self.onSave = onSave
        _host = State(initialValue: initialSettings.host)
        _portText = State(initialValue: String(initialSettings.port))
        _appearance = State(initialValue: initialSettings.appearance)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Jetson") {
                    TextField("Host", text: $host)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("Port", text: $portText)
                        .keyboardType(.numberPad)
                }

                Section("Appearance") {
                    Picker("Theme", selection: $appearance) {
                        ForEach(AppAppearance.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Info") {
                    Text("Example: jetson.local and port 8000")
                    Text("The app connects over HTTP to the local Jetson hotspot.")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && Int(portText) != nil
    }

    private func save() {
        guard let port = Int(portText) else { return }
        onSave(host, port, appearance)
        dismiss()
    }
}
