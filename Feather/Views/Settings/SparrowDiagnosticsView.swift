import SwiftUI

struct SparrowDiagnosticsView: View {
	@ObservedObject private var history = SparrowActivityHistory.shared
	@FetchRequest(entity: Imported.entity(), sortDescriptors: []) private var imported: FetchedResults<Imported>
	@FetchRequest(entity: Signed.entity(), sortDescriptors: []) private var signed: FetchedResults<Signed>
	@FetchRequest(entity: AltSource.entity(), sortDescriptors: []) private var sources: FetchedResults<AltSource>
	@FetchRequest(entity: CertificatePair.entity(), sortDescriptors: []) private var certificates: FetchedResults<CertificatePair>
	@State private var copied = false
	private var diagnostics: String {
		let appGroupStatus = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.sparrow.app") != nil ? "OK" : "Unavailable"
		let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
		return "Sparrow \(Bundle.main.version) (\(build))\niOS \(UIDevice.current.systemVersion)\nArchitecture: arm64\n\nApps: \(imported.count + signed.count)\nSources: \(sources.count)\nCertificates: \(certificates.count)\nApp Group: \(appGroupStatus)\nShare Extension: Embedded"
	}
	var body: some View {
		Form {
			Section("Sparrow Diagnostics") {
				Text(diagnostics).font(.system(.footnote, design: .monospaced))
				Button(copied ? "Copied" : "Copy Diagnostics") { UIPasteboard.general.string = diagnostics; copied = true }
			}
			Section("Activity History") {
				ForEach(history.events) { event in
					VStack(alignment: .leading) { Text(event.operation + (event.subject.map { " — \($0)" } ?? "")); Text(event.date.formatted(date: .abbreviated, time: .shortened) + " · " + event.result).font(.footnote).foregroundStyle(.secondary) }
				}
				if !history.events.isEmpty { Button("Clear History", role: .destructive) { history.clear() } }
			}
		}
		.navigationTitle("Diagnostics")
	}
}
