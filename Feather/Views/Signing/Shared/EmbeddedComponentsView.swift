import SwiftUI
import UniformTypeIdentifiers

struct EmbeddedComponentsView: View {
	let app: AppInfoPresentable
	@State private var components: [Component] = []
	@State private var search = ""
	struct Component: Identifiable { let id: String; let name: String; let path: String; let type: String; var enabled: Bool }
	var filtered: [Component] { search.isEmpty ? components : components.filter { $0.name.localizedCaseInsensitiveContains(search) || $0.path.localizedCaseInsensitiveContains(search) } }
	var body: some View {
		List {
			Section { Button("Select All") { setAll(true) }; Button("Deselect All") { setAll(false) }; Button("Reset") { components = components.map { Component(id: $0.id, name: $0.name, path: $0.path, type: $0.type, enabled: true) } } }
			Section("\(components.count) Components") { ForEach(filtered) { item in Toggle(isOn: Binding(get: { item.enabled }, set: { update(item.id, $0) })) { VStack(alignment: .leading) { Text(item.name); Text("\(item.type) • \(item.path)").font(.caption).foregroundStyle(.secondary) } } } }
		}
		.searchable(text: $search)
		.navigationTitle("Extensions")
		.task { load() }
	}
	private func load() { guard let root = Storage.shared.getAppDirectory(for: app) else { return }; let fm = FileManager.default; guard let e = fm.enumerator(at: root, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else { return }; components = e.compactMap { ($0 as? URL) }.filter { ["appex", "app"].contains($0.pathExtension) }.compactMap { url in let plist = url.appendingPathComponent("Info.plist"); guard let d = NSDictionary(contentsOf: plist), let id = d["CFBundleIdentifier"] as? String else { return nil }; let type = url.pathExtension == "appex" ? "Extension" : (url.pathComponents.contains("Watch") ? "Watch App" : "Embedded App"); let key = "Sparrow.component.\(app.uuid ?? "").\(id)"; return Component(id: id, name: d["CFBundleDisplayName"] as? String ?? d["CFBundleName"] as? String ?? id, path: url.path.replacingOccurrences(of: root.path + "/", with: ""), type: type, enabled: UserDefaults.standard.object(forKey: key) as? Bool ?? true) } }
	private func update(_ id: String, _ value: Bool) { UserDefaults.standard.set(value, forKey: "Sparrow.component.\(app.uuid ?? "").\(id)"); components = components.map { $0.id == id ? Component(id: $0.id, name: $0.name, path: $0.path, type: $0.type, enabled: value) : $0 } }
	private func setAll(_ value: Bool) { components.forEach { UserDefaults.standard.set(value, forKey: "Sparrow.component.\(app.uuid ?? "").\($0.id)") }; components = components.map { Component(id: $0.id, name: $0.name, path: $0.path, type: $0.type, enabled: value) } }
}
