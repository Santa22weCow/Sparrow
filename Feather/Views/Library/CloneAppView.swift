import SwiftUI

struct CloneAppView: View {
	let app: AppInfoPresentable
	@State private var cloneName = ""
	@State private var cloneIdentifier = ""
	@State private var versionSuffix = ""
	@State private var buildSuffix = ""
	@State private var message: String?
	@State private var isCloning = false
	private var validation: SparrowCloneIdentifierResult { SparrowCloneIdentifier.validate(cloneIdentifier) }
	var body: some View {
		Form {
			Section("Original") { LabeledContent("App", value: app.name ?? "Unknown"); LabeledContent("Bundle ID", value: app.identifier ?? "Unknown"); LabeledContent("Version", value: app.version ?? "Unknown") }
			Section("Clone") { TextField("Clone Name", text: $cloneName); TextField("New Bundle ID", text: $cloneIdentifier).textInputAutocapitalization(.never); TextField("Version suffix (optional)", text: $versionSuffix); TextField("Build suffix (optional)", text: $buildSuffix) }
			Section("Suggestions") { ForEach(SparrowCloneIdentifier.suggestions(for: app.identifier ?? ""), id: \.self) { suggestion in Button(suggestion) { cloneIdentifier = suggestion } } }
			if let warning = message { Text(warning).foregroundStyle(.orange) }
			Section { Button(isCloning ? "Creating Clone…" : "Create Clone") { isCloning = true; SparrowCloneService.shared.clone(app: app, name: cloneName, identifier: cloneIdentifier, version: versionSuffix.isEmpty ? nil : versionSuffix, build: buildSuffix.isEmpty ? nil : buildSuffix) { result in DispatchQueue.main.async { isCloning = false; switch result { case .success(let url): FR.handlePackageFile(url) { error in try? FileManager.default.removeItem(at: url.deletingLastPathComponent()); message = error == nil ? "Clone imported into Sparrow. Review it before signing." : error!.localizedDescription }; case .failure(let error): message = error.localizedDescription } } } }.disabled(isCloning || !validation.valid || cloneName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
		}
		.navigationTitle("Clone App")
		.onAppear { cloneName = (app.name ?? "App") + " 2"; cloneIdentifier = SparrowCloneIdentifier.suggestions(for: app.identifier ?? "").first ?? "com.sparrow.clone.app" }
	}
}
