import SwiftUI

struct CloneAppView: View {
	let app: AppInfoPresentable
	@State private var cloneName = ""
	@State private var cloneIdentifier = ""
	@State private var versionSuffix = ""
	@State private var buildSuffix = ""
	@State private var message: String?
	private var validation: SparrowCloneIdentifierResult { SparrowCloneIdentifier.validate(cloneIdentifier) }
	var body: some View {
		Form {
			Section("Original") { LabeledContent("App", value: app.name ?? "Unknown"); LabeledContent("Bundle ID", value: app.identifier ?? "Unknown"); LabeledContent("Version", value: app.version ?? "Unknown") }
			Section("Clone") { TextField("Clone Name", text: $cloneName); TextField("New Bundle ID", text: $cloneIdentifier).textInputAutocapitalization(.never); TextField("Version suffix (optional)", text: $versionSuffix); TextField("Build suffix (optional)", text: $buildSuffix) }
			Section("Suggestions") { ForEach(SparrowCloneIdentifier.suggestions(for: app.identifier ?? ""), id: \.self) { suggestion in Button(suggestion) { cloneIdentifier = suggestion } } }
			if let warning = message { Text(warning).foregroundStyle(.orange) }
			Section { Button("Create Clone") { message = "Clone planning is ready, but Sparrow will not modify the original app. Archive rewriting and signing must be completed before a clone is created." }.disabled(!validation.valid || cloneName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
		}
		.navigationTitle("Clone App")
		.onAppear { cloneName = (app.name ?? "App") + " 2"; cloneIdentifier = SparrowCloneIdentifier.suggestions(for: app.identifier ?? "").first ?? "com.sparrow.clone.app" }
	}
}
