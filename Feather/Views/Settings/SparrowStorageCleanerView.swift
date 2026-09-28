import SwiftUI

struct SparrowStorageCleanerView: View {
	@State private var report: SparrowStorageReport?
	@State private var selected = Set<String>()
	@State private var isScanning = false
	@State private var error: String?
	@State private var showConfirmation = false
	@State private var cleanedMessage: String?

	var body: some View {
		List {
			if let report {
				Section("Storage Overview") {
					LabeledContent("Total Sparrow Storage", value: Self.format(report.totalBytes))
					LabeledContent("Reclaimable Storage", value: Self.format(report.reclaimableBytes))
				}
				Section("Categories") {
					ForEach(report.categories) { category in
						HStack {
							if category.removable { Image(systemName: selected.contains(category.id) ? "checkmark.circle.fill" : "circle").foregroundStyle(selected.contains(category.id) ? .blue : .secondary) }
							VStack(alignment: .leading) { Text(category.title); Text(Self.format(category.bytes)).font(.footnote).foregroundStyle(.secondary) }
							Spacer(); if !category.removable { Text("Protected").font(.caption).foregroundStyle(.secondary) }
						}
						.contentShape(Rectangle()).onTapGesture { guard category.removable else { return }; if selected.contains(category.id) { selected.remove(category.id) } else { selected.insert(category.id) } }
					}
				}
				Section { Button("Clean Selected", role: .destructive) { showConfirmation = true }.disabled(selected.isEmpty) }
			} else if isScanning { ProgressView("Scanning Sparrow storage…") } else { Text("Storage has not been scanned yet.") }
			if let error { Text(error).foregroundStyle(.red) }
		}
		.navigationTitle("Storage Cleaner")
		.toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Refresh", systemImage: "arrow.clockwise") { scan() }.disabled(isScanning) } }
		.task { scan() }
		.confirmationDialog("Clean selected storage?", isPresented: $showConfirmation) {
			Button("Clean", role: .destructive) { cleanSelected() }
			Button("Cancel", role: .cancel) { }
		} message: { Text("Only selected Sparrow-owned cache, archive, and signed-build locations will be removed. Imported IPAs and certificates are protected.") }
		.alert("Storage Cleaned", isPresented: Binding(get: { cleanedMessage != nil }, set: { if !$0 { cleanedMessage = nil } })) { Button("OK") { cleanedMessage = nil } } message: { Text(cleanedMessage ?? "") }
	}
	private func scan() { isScanning = true; Task { let value = await SparrowStorageManager.shared.scan(); await MainActor.run { report = value; isScanning = false } } }
	private func cleanSelected() { guard let report else { return }; let targets = report.categories.filter { selected.contains($0.id) }; do { try targets.forEach { try SparrowStorageManager.shared.remove($0) }; selected.removeAll(); cleanedMessage = "Selected Sparrow storage was removed."; scan() } catch let caught { self.error = caught.localizedDescription } }
	private static func format(_ bytes: Int64) -> String { ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file) }
}
