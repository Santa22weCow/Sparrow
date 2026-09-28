import SwiftUI

struct SparrowIPAInspectorView: View {
	let app: AppInfoPresentable
	@State private var inspection: SparrowIPAInspection?
	@State private var error: String?
	var body: some View {
		List {
			if let data = inspection {
				Section("App") { LabeledContent("Name", value: data.appName); LabeledContent("Bundle ID", value: data.bundleIdentifier); LabeledContent("Version", value: data.version); LabeledContent("Build", value: data.build); if let minimumOS = data.minimumOS { LabeledContent("Minimum iOS", value: minimumOS) }; LabeledContent("Size", value: ByteCountFormatter.string(fromByteCount: data.appSize, countStyle: .file)) }
				Section("Components (\(data.components.count))") { ForEach(data.components) { item in VStack(alignment: .leading) { Text(item.name); Text("\(item.kind) · \(item.path)").font(.footnote).foregroundStyle(.secondary); if let id = item.bundleID { Text(id).font(.footnote).foregroundStyle(.secondary) } } } }
				if !data.urlSchemes.isEmpty { Section("URL Schemes") { ForEach(data.urlSchemes, id: \.self) { Text($0) } } }
				if !data.entitlements.isEmpty { Section("Detected Entitlements") { ForEach(data.entitlements, id: \.self) { Text($0) } } }
			} else if let error { Text(error).foregroundStyle(.red) } else { ProgressView("Inspecting IPA…") }
		}
		.navigationTitle("IPA Inspector")
		.task { do { inspection = try SparrowIPAInspector.inspect(app) } catch { self.error = error.localizedDescription } }
	}
}
