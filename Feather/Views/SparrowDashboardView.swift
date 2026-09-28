import SwiftUI

struct SparrowDashboardView: View {
	@FetchRequest(entity: Imported.entity(), sortDescriptors: []) private var imported: FetchedResults<Imported>
	@FetchRequest(entity: Signed.entity(), sortDescriptors: []) private var signed: FetchedResults<Signed>
	@FetchRequest(entity: AltSource.entity(), sortDescriptors: []) private var sources: FetchedResults<AltSource>
	@FetchRequest(entity: CertificatePair.entity(), sortDescriptors: []) private var certificates: FetchedResults<CertificatePair>
	var body: some View {
		List {
			Section("Sparrow") { Text("Your signing and app dashboard").font(.headline) }
			Section("Overview") {
				Label("\(imported.count) Imported Apps", systemImage: "square.grid.2x2")
				Label("\(signed.count) Signed Apps", systemImage: "checkmark.seal")
				Label("\(certificates.count) Certificates", systemImage: "person.text.rectangle")
				Label("\(sources.count) Sources", systemImage: "globe")
			}
			Section("Quick Actions") {
				Text("Import an IPA from Files or use the Share Sheet to add it to Sparrow.").foregroundStyle(.secondary)
			}
		}
		.navigationTitle("Dashboard")
	}
}
