import SwiftUI
import CoreData

struct BulkSigningView: View {
	@FetchRequest(entity: Imported.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Imported.date, ascending: false)]) private var imported: FetchedResults<Imported>
	@FetchRequest(entity: Signed.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Signed.date, ascending: false)]) private var signed: FetchedResults<Signed>
	@FetchRequest(entity: CertificatePair.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)]) private var certificates: FetchedResults<CertificatePair>
	@State private var queue = FR.BatchSigningQueue(apps: [])
	@State private var selectedCertificate = 0
	@State private var selected: Set<NSManagedObjectID> = []
	@State private var options = OptionsManager.shared.options
	@AppStorage("Sparrow.existingSignedBuildPolicy") private var existingPolicy = "ask"
	@State private var resignMode = false
	@State private var showSummary = false

	var body: some View {
		Form {
			Section("Apps") {
				Button("Re-sign All Apps") { resignMode = true; selected = Set(imported.map(\.objectID)); start() }
				ForEach(imported, id: \.objectID) { app in Toggle(app.name ?? "App", isOn: Binding(get: { selected.contains(app.objectID) }, set: { value in if value { selected.insert(app.objectID) } else { selected.remove(app.objectID) } })) }
			}
			Section("Certificate") { Picker("Signing certificate", selection: $selectedCertificate) { ForEach(Array(certificates.enumerated()), id: \.offset) { index, cert in Text(cert.nickname ?? "Certificate").tag(index) } } }
			Section("Existing Signed Builds") { Picker("Policy", selection: $existingPolicy) { Text("Keep Existing").tag("keep"); Text("Replace Existing").tag("replace"); Text("Ask Each Time").tag("ask") } }
			Section { Button(queue.running ? "Cancel Queue" : "Sign Selected Apps") { if queue.running { queue.cancel() } else { start() } }; if !queue.running && !queue.items.isEmpty { Button("Retry All Failed") { queue.retryFailed(options: options, certificate: selectedCert) }; Button("Show Batch Summary") { showSummary = true } } }
			if !queue.items.isEmpty { Section("Batch Progress") { Text("Completed: \(queue.items.filter { $0.state == .completed }.count) / \(queue.items.count)"); ForEach(queue.items) { item in VStack(alignment: .leading) { Text(item.app.name ?? "App"); Text(item.state.rawValue.capitalized).foregroundStyle(item.state == .failed ? .red : .secondary); if let error = item.error { Text(error).font(.caption).foregroundStyle(.red); Button("Retry") { queue.retry(item: item, options: options, certificate: selectedCert) } } } } } }
		}
		.navigationTitle("Bulk Signing")
		.sheet(isPresented: $showSummary) { BatchSummaryView(items: queue.items) }
	}
	private var selectedCert: CertificatePair? { certificates.indices.contains(selectedCertificate) ? certificates[selectedCertificate] : nil }
	private func start() { let apps = imported.filter { selected.contains($0.objectID) }.map { $0 as AppInfoPresentable }; queue = FR.BatchSigningQueue(apps: apps); queue.start(options: options, certificate: selectedCert) }
}

struct BatchSummaryView: View { let items: [FR.BatchSigningQueue.Item]; var body: some View { NavigationStack { List { Text("Total: \(items.count)"); Text("Completed: \(items.filter { $0.state == .completed }.count)"); Text("Failed: \(items.filter { $0.state == .failed }.count)"); Text("Cancelled: \(items.filter { $0.state == .cancelled }.count)"); ForEach(items) { item in HStack { Text(item.state == .completed ? "✓" : item.state == .failed ? "⚠" : "⏹"); Text(item.app.name ?? "App"); Spacer(); Text(item.state.rawValue.capitalized) } } }.navigationTitle("Batch Summary") } } }
