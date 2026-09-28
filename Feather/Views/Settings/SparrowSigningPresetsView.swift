import SwiftUI

struct SparrowSigningPresetsView: View {
	@ObservedObject private var store = SparrowSigningPresetStore.shared
	@State private var newName = ""
	var body: some View {
		List {
			Section("Signing Presets") {
				ForEach(store.presets) { preset in
					HStack { VStack(alignment: .leading) { Text(preset.name); Text(preset.keepWatchComponents ? "Keeps Apple Watch components" : "Removes Apple Watch components").font(.footnote).foregroundStyle(.secondary) }; Spacer(); if store.defaultPresetID == preset.id { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) } }
					.contentShape(Rectangle()).onTapGesture { store.setDefault(preset) }
				}
				.onDelete { offsets in offsets.map { store.presets[$0] }.forEach(store.remove) }
			}
			Section("New Preset") {
				TextField("Preset name", text: $newName)
				Button("Create Preset") { let value = newName.trimmingCharacters(in: .whitespacesAndNewlines); guard !value.isEmpty else { return }; store.add(name: value); newName = "" }
			}
		}
		.navigationTitle("Signing Presets")
	}
}
