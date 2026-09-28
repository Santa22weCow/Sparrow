import SwiftUI
import CoreData

struct SparrowSignInstallView: View {
	@FetchRequest(entity: Imported.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Imported.date, ascending: false)]) private var apps: FetchedResults<Imported>
	@FetchRequest(entity: CertificatePair.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)]) private var certificates: FetchedResults<CertificatePair>
	@FetchRequest(entity: Signed.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Signed.date, ascending: false)]) private var signed: FetchedResults<Signed>
	@ObservedObject private var presets = SparrowSigningPresetStore.shared
	@State private var selectedID: NSManagedObjectID?
	@State private var signingApp: AnyApp?
	@State private var installApp: AnyApp?
	@State private var message: String?

	var body: some View {
		Form {
			Section("Sign & Install") {
				Picker("App", selection: $selectedID) { Text("Choose an imported app").tag(nil as NSManagedObjectID?); ForEach(apps, id: \.objectID) { Text("\($0.name ?? "Unknown") \($0.version ?? "")").tag(Optional($0.objectID)) } }
			LabeledContent("Preset", value: presets.presets.first(where: { $0.id == presets.defaultPresetID })?.name ?? "Default")
			LabeledContent("Certificates", value: certificates.isEmpty ? "Missing" : "Available")
			}
			Section("Preflight") {
				if let app = selectedApp { preflight(app) } else { Text("Choose an app to validate signing and installation.").foregroundStyle(.secondary) }
			}
			if let message { Text(message).foregroundStyle(.orange) }
			Section { Button("Sign & Install", systemImage: "arrow.down.app") { begin() }.disabled(selectedApp == nil || certificates.isEmpty) }
		}
		.navigationTitle("Sign & Install")
		.fullScreenCover(item: $signingApp) { selected in SigningView(app: selected.base) { if let result = signed.first(where: { $0.identifier == selected.base.identifier }) { installApp = AnyApp(base: result) } } }
		.sheet(item: $installApp) { selected in InstallPreviewView(app: selected.base).presentationDetents([.height(200)]) }
	}
	private var selectedApp: Imported? { guard let selectedID else { return nil }; return apps.first(where: { $0.objectID == selectedID }) }
	@ViewBuilder private func preflight(_ app: Imported) -> some View { Label("Bundle identifier: \(app.identifier ?? "Unknown")", systemImage: "checkmark.circle").foregroundStyle(.green); if let cert = certificates.first, let profile = Storage.shared.getProvisionFileDecoded(for: cert) { let result = profile.compatibility(for: app.identifier ?? ""); Label(result.message, systemImage: result.compatible ? "checkmark.circle" : "exclamationmark.triangle").foregroundStyle(result.compatible ? .green : .orange) } else { Label("Provisioning profile is unavailable.", systemImage: "exclamationmark.triangle").foregroundStyle(.red) } }
	private func begin() { guard let app = selectedApp, let cert = certificates.first else { return }; if let profile = Storage.shared.getProvisionFileDecoded(for: cert), !profile.compatibility(for: app.identifier ?? "").compatible { message = "Cannot sign: the selected provisioning profile does not match this bundle identifier."; return }; signingApp = AnyApp(base: app) }
}
