import Foundation

struct SparrowSigningPreset: Codable, Identifiable, Equatable {
	let id: UUID
	var name: String
	var certificateIndex: Int?
	var keepWatchComponents: Bool
	var uniqueKeychainGroups: Bool
}

final class SparrowSigningPresetStore: ObservableObject {
	static let shared = SparrowSigningPresetStore()
	@Published private(set) var presets: [SparrowSigningPreset] = []
	@Published var defaultPresetID: UUID?
	private let presetsKey = "Sparrow.signingPresets"
	private let defaultKey = "Sparrow.defaultSigningPreset"
	private init() { load() }
	func add(name: String) { presets.append(.init(id: UUID(), name: name, certificateIndex: nil, keepWatchComponents: true, uniqueKeychainGroups: false)); save() }
	func remove(_ preset: SparrowSigningPreset) { presets.removeAll { $0.id == preset.id }; if defaultPresetID == preset.id { defaultPresetID = nil }; save() }
	func setDefault(_ preset: SparrowSigningPreset) { defaultPresetID = preset.id; save() }
	private func load() { if let d = UserDefaults.standard.data(forKey: presetsKey), let p = try? JSONDecoder().decode([SparrowSigningPreset].self, from: d) { presets = p }; if let s = UserDefaults.standard.string(forKey: defaultKey) { defaultPresetID = UUID(uuidString: s) } }
	private func save() { UserDefaults.standard.set(try? JSONEncoder().encode(presets), forKey: presetsKey); UserDefaults.standard.set(defaultPresetID?.uuidString, forKey: defaultKey) }
}
