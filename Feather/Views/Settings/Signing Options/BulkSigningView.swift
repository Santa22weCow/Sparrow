import SwiftUI
import CoreData

struct BulkSigningView: View {
	let initialSelection: Set<String>
	@FetchRequest(entity: Imported.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Imported.date, ascending: false)]) private var imported: FetchedResults<Imported>
	@FetchRequest(entity: Signed.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Signed.date, ascending: false)]) private var signed: FetchedResults<Signed>
	@FetchRequest(entity: CertificatePair.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)]) private var certificates: FetchedResults<CertificatePair>
	@State private var queue = FR.BatchSigningQueue(apps: [])
	@State private var selectedCertificate = 0
	@State private var selected: Set<String> = []
	@State private var options = OptionsManager.shared.options
	@AppStorage("Sparrow.existingSignedBuildPolicy") private var existingPolicy = "ask"
	@State private var resignMode = false
	@State private var showSummary = false
	@State private var preflightComplete = false

	init(initialSelection: Set<String> = []) { self.initialSelection = initialSelection }

	var body: some View {
		Form {
			Section("Apps") {
				HStack { Text("\(selected.count) Apps Selected"); Spacer(); Button("Select All") { selected = Set(imported.compactMap(\.uuid)) }; Button("Deselect All") { selected.removeAll() } }
				Button("Re-sign All Apps") { resignMode = true; selected = Set(imported.compactMap(\.uuid)); runPreflight() }
				ForEach(imported, id: \.objectID) { app in Toggle(app.name ?? "App", isOn: Binding(get: { selected.contains(app.uuid ?? "") }, set: { value in if let uuid = app.uuid { if value { selected.insert(uuid) } else { selected.remove(uuid) } } })) }
			}
			Section("Certificate") { Picker("Signing certificate", selection: $selectedCertificate) { ForEach(Array(certificates.enumerated()), id: \.offset) { index, cert in Text(cert.nickname ?? "Certificate").tag(index) } } }
			Section("Existing Signed Builds") { Picker("Policy", selection: $existingPolicy) { Text("Keep Existing").tag("keep"); Text("Replace Existing").tag("replace"); Text("Ask Each Time").tag("ask") } }
			Section("Preflight") {
				HStack { Text("READY"); Spacer(); Text("\(readyCount)").foregroundStyle(.green) }
				HStack { Text("WARNINGS"); Spacer(); Text("\(warningCount)").foregroundStyle(.orange) }
				HStack { Text("BLOCKED"); Spacer(); Text("\(blockedCount)").foregroundStyle(blockedCount == 0 ? .green : .red) }
				Button(preflightComplete ? "Run Preflight Again" : "Run Preflight") { runPreflight() }
			}
			Section { Button(queue.running ? "Cancel Queue" : "Sign Selected Apps") { if queue.running { queue.cancel() } else { start() } }.disabled(selected.isEmpty || (!preflightComplete && !queue.running)); if !queue.running && !queue.items.isEmpty { Button("Retry All Failed") { queue.retryFailed(options: options, certificate: selectedCert) }; Button("Show Batch Summary") { showSummary = true } } }
			if !queue.items.isEmpty { Section("Batch Progress") { Text("Completed: \(queue.items.filter { $0.state == .completed }.count) / \(queue.items.count)"); ForEach(queue.items) { item in VStack(alignment: .leading) { Text(item.app.name ?? "App"); Text(item.state.rawValue.capitalized).foregroundStyle(item.state == .failed ? .red : .secondary); if let error = item.error { Text(error).font(.caption).foregroundStyle(.red); Button("Retry") { queue.retry(item: item, options: options, certificate: selectedCert) } } } } } }
		}
		.navigationTitle("Bulk Signing")
		.sheet(isPresented: $showSummary) { BatchSummaryView(items: queue.items) }
		.onAppear { if selected.isEmpty { selected = initialSelection } }
	}
	private var selectedCert: CertificatePair? { certificates.indices.contains(selectedCertificate) ? certificates[selectedCertificate] : nil }
	private var selectedApps: [Imported] { imported.filter { selected.contains($0.uuid ?? "") } }
	private var readyCount: Int { preflightComplete && selectedCert != nil ? selectedApps.count : 0 }
	private var blockedCount: Int { selectedCert == nil && !selectedApps.isEmpty ? selectedApps.count : 0 }
	private var warningCount: Int { preflightComplete && selectedCert != nil ? 0 : selectedApps.isEmpty ? 0 : 1 }
	private func runPreflight() { preflightComplete = true }
	private func start() { let apps = selectedApps.map { $0 as AppInfoPresentable }; queue = FR.BatchSigningQueue(apps: apps); queue.start(options: options, certificate: selectedCert) }
}

struct BatchSummaryView: View { let items: [FR.BatchSigningQueue.Item]; var body: some View { NavigationStack { List { Text("Total: \(items.count)"); Text("Completed: \(items.filter { $0.state == .completed }.count)"); Text("Failed: \(items.filter { $0.state == .failed }.count)"); Text("Cancelled: \(items.filter { $0.state == .cancelled }.count)"); ForEach(items) { item in HStack { Text(item.state == .completed ? "✓" : item.state == .failed ? "⚠" : "⏹"); Text(item.app.name ?? "App"); Spacer(); Text(item.state.rawValue.capitalized) } } }.navigationTitle("Batch Summary") } } }
