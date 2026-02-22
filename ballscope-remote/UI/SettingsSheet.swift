import SwiftUI

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    let initialSettings: AppSettings
    let onSave: (AppSettings) -> Void
    let onResetAppCache: () -> Void

    @State private var systems: [BallScopeSystem]
    @State private var activeSystemID: UUID
    @State private var appearance: AppAppearance
    @State private var editorDraft: SystemEditorDraft?

    init(initialSettings: AppSettings,
         onSave: @escaping (AppSettings) -> Void,
         onResetAppCache: @escaping () -> Void) {
        self.initialSettings = initialSettings
        self.onSave = onSave
        self.onResetAppCache = onResetAppCache
        _systems = State(initialValue: initialSettings.systems)
        _activeSystemID = State(initialValue: initialSettings.activeSystemID)
        _appearance = State(initialValue: initialSettings.appearance)
    }

    var body: some View {
        NavigationStack {
            List {
                systemsSection
                appearanceSection
                connectionSection
                aboutSection
                appDataSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .sheet(item: $editorDraft) { draft in
                BallScopeSystemEditorSheet(
                    draft: draft,
                    onSave: { savedSystem in
                        upsertSystem(savedSystem)
                    }
                )
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private var systemsSection: some View {
        Section {
            ForEach(systems) { system in
                Button {
                    activeSystemID = system.id
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(system.id == activeSystemID ? Color.accentColor.opacity(0.16) : Color.secondary.opacity(0.12))
                                .frame(width: 38, height: 38)
                            Image(systemName: system.id == activeSystemID ? "checkmark.circle.fill" : "cpu")
                                .foregroundStyle(system.id == activeSystemID ? Color.accentColor : Color.secondary)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(system.displayName)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                if system.id == activeSystemID {
                                    Text("Active")
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.accentColor.opacity(0.14))
                                        .clipShape(Capsule())
                                }
                            }

                            Text(system.addressLabel)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 10)

                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(system.id == activeSystemID ? Color.accentColor : .clear)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        editorDraft = .edit(system)
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)

                    if systems.count > 1 {
                        Button(role: .destructive) {
                            deleteSystem(system)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }

            Button {
                editorDraft = .addDefault
            } label: {
                Label("Add BallScope System", systemImage: "plus.circle.fill")
                    .fontWeight(.semibold)
            }
        } header: {
            Text("BallScope Systems")
        } footer: {
            Text("Select the active system used by Record, Analysis, and Live.")
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: $appearance) {
                ForEach(AppAppearance.allCases) { style in
                    Text(style.title).tag(style)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var connectionSection: some View {
        Section("Connection Guide") {
            SettingsInfoRow(
                icon: "wifi",
                tint: .blue,
                title: "Use BallScope Wi-Fi",
                subtitle: "Connect your phone to the BallScope hotspot for the most stable local connection."
            )

            SettingsInfoRow(
                icon: "network",
                tint: .green,
                title: "Local Address",
                subtitle: "Each system stores its own host and port, for example jetson.local:8000."
            )
        }
    }

    private var aboutSection: some View {
        Section("About") {
            SettingsInfoRow(
                icon: "sparkles",
                tint: .purple,
                title: "BallScope Remote",
                subtitle: "Native iOS companion app for controlling your BallScope device."
            )

            SettingsInfoRow(
                icon: "rectangle.3.group.bubble.left",
                tint: .orange,
                title: "Navigation Sync",
                subtitle: "Tabs stay in sync with the Jetson route while keeping a native app feel."
            )
        }
    }

    private var appDataSection: some View {
        Section("App Data") {
            Button(role: .destructive) {
                onResetAppCache()
                dismiss()
            } label: {
                Label("Reset App Cache", systemImage: "trash")
            }

            Text("Clears local web cache, resets saved systems to default, and shows onboarding again.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var isValid: Bool {
        !sanitizedSystems().isEmpty
    }

    private func sanitizedSystems() -> [BallScopeSystem] {
        systems.compactMap { system in
            let host = system.trimmedHost
            let name = system.trimmedName
            guard !host.isEmpty else { return nil }
            guard (1...65535).contains(system.port) else { return nil }
            return BallScopeSystem(
                id: system.id,
                name: name.isEmpty ? host : name,
                host: host,
                port: system.port
            )
        }
    }

    private func upsertSystem(_ system: BallScopeSystem) {
        if let index = systems.firstIndex(where: { $0.id == system.id }) {
            systems[index] = system
        } else {
            systems.append(system)
            activeSystemID = system.id
        }
    }

    private func deleteSystem(_ system: BallScopeSystem) {
        guard systems.count > 1 else { return }
        systems.removeAll { $0.id == system.id }
        if activeSystemID == system.id, let first = systems.first {
            activeSystemID = first.id
        }
    }

    private func save() {
        let cleaned = sanitizedSystems()
        guard !cleaned.isEmpty else { return }
        let resolvedActiveID = cleaned.contains(where: { $0.id == activeSystemID }) ? activeSystemID : cleaned[0].id
        let updated = AppSettings(systems: cleaned, activeSystemID: resolvedActiveID, appearance: appearance)
        onSave(updated)
        dismiss()
    }
}

private struct SettingsInfoRow: View {
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(0.14))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .font(.system(size: 15, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct SystemEditorDraft: Identifiable {
    enum Mode {
        case add
        case edit
    }

    let id: UUID
    let mode: Mode
    let system: BallScopeSystem

    static var addDefault: SystemEditorDraft {
        let base = BallScopeSystem(name: "BallScope", host: "jetson.local", port: 8000)
        return .init(id: UUID(), mode: .add, system: base)
    }

    static func edit(_ system: BallScopeSystem) -> SystemEditorDraft {
        .init(id: system.id, mode: .edit, system: system)
    }
}

private struct BallScopeSystemEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let draft: SystemEditorDraft
    let onSave: (BallScopeSystem) -> Void

    @State private var name: String
    @State private var host: String
    @State private var portText: String

    init(draft: SystemEditorDraft, onSave: @escaping (BallScopeSystem) -> Void) {
        self.draft = draft
        self.onSave = onSave
        _name = State(initialValue: draft.system.name)
        _host = State(initialValue: draft.system.host)
        _portText = State(initialValue: String(draft.system.port))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("System") {
                    TextField("Name", text: $name)
                    TextField("Host", text: $host)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Port", text: $portText)
                        .keyboardType(.numberPad)
                }

                Section("Info") {
                    Text("Examples: jetson.local, 192.168.4.1")
                    Text("Default BallScope web port is usually 8000.")
                }
            }
            .navigationTitle(draft.mode == .add ? "Add System" : "Edit System")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { save() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedHost.isEmpty else { return false }
        guard let port = Int(portText) else { return false }
        return (1...65535).contains(port)
    }

    private func save() {
        guard let port = Int(portText) else { return }
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedHost.isEmpty else { return }

        onSave(
            BallScopeSystem(
                id: draft.system.id,
                name: trimmedName.isEmpty ? trimmedHost : trimmedName,
                host: trimmedHost,
                port: port
            )
        )
        dismiss()
    }
}

