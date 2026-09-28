import SwiftUI
import CoreData

struct SparrowIPACompareView: View {
	@FetchRequest(entity: Imported.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Imported.date, ascending: false)]) private var apps: FetchedResults<Imported>
	@State private var leftID: NSManagedObjectID?
	@State private var rightID: NSManagedObjectID?
	@State private var comparison: SparrowIPAComparison?
	@State private var error: String?
	var body: some View {
		Form {
			Section("IPA Selection") {
				Picker("IPA A", selection: $leftID) { Text("Choose an app").tag(nil as NSManagedObjectID?); ForEach(apps, id: \.objectID) { Text(label(for: $0)).tag(Optional($0.objectID)) } }
				Picker("IPA B", selection: $rightID) { Text("Choose an app").tag(nil as NSManagedObjectID?); ForEach(apps, id: \.objectID) { Text(label(for: $0)).tag(Optional($0.objectID)) } }
				Button("Compare") { runCompare() }.disabled(leftID == nil || rightID == nil || leftID == rightID)
			}
			if let result = comparison {
				Section("Overview") { diff("Name", result.left.appName, result.right.appName); diff("Bundle ID", result.left.bundleIdentifier, result.right.bundleIdentifier); diff("Version", result.left.version, result.right.version); diff("Build", result.left.build, result.right.build); diff("Size", ByteCountFormatter.string(fromByteCount: result.left.appSize, countStyle: .file), ByteCountFormatter.string(fromByteCount: result.right.appSize, countStyle: .file)); if result.sizeDelta != 0 { Text("Size change: \(ByteCountFormatter.string(fromByteCount: result.sizeDelta, countStyle: .file))") } }
				Section("Components") { if result.addedComponents.isEmpty && result.removedComponents.isEmpty { Text("No component changes") }; ForEach(result.addedComponents, id: \.self) { Text("Added · \($0)").foregroundStyle(.green) }; ForEach(result.removedComponents, id: \.self) { Text("Removed · \($0)").foregroundStyle(.red) } }
				Section("URL Schemes") { ForEach(result.addedSchemes, id: \.self) { Text("Added · \($0)") }; ForEach(result.removedSchemes, id: \.self) { Text("Removed · \($0)") }; if result.addedSchemes.isEmpty && result.removedSchemes.isEmpty { Text("No URL scheme changes") } }
			}
			if let error { Text(error).foregroundStyle(.red) }
		}
		.navigationTitle("Compare IPAs")
	}
	private func diff(_ title: String, _ left: String, _ right: String) -> some View { VStack(alignment: .leading) { Text(title).font(.headline); Text(left); if left != right { Text("→ \(right)").foregroundStyle(.orange) } } }
	private func label(for app: Imported) -> String { "\(app.name ?? "Unknown") \(app.version ?? "")" }
	private func runCompare() { guard let l = leftID, let r = rightID, let left = apps.first(where: { $0.objectID == l }), let right = apps.first(where: { $0.objectID == r }) else { return }; do { comparison = try SparrowIPACompareService.compare(left, right); error = nil } catch let caught { error = caught.localizedDescription } }
}
