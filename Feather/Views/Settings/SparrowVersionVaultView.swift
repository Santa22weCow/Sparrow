import SwiftUI
import CoreData

struct SparrowVersionVaultView: View {
	@FetchRequest(entity: Imported.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Imported.date, ascending: false)]) private var imported: FetchedResults<Imported>
	private var groups: [(String, [Imported])] {
		Dictionary(grouping: imported, by: { $0.identifier ?? "" }).filter { !$0.key.isEmpty && $0.value.count > 1 }.sorted { ($0.value.first?.name ?? "") < ($1.value.first?.name ?? "") }
	}
	var body: some View {
		List {
			ForEach(groups, id: \.0) { group in
				NavigationLink(destination: SparrowVersionHistoryView(name: group.1.first?.name ?? "Unknown", identifier: group.0, versions: group.1)) {
					HStack { Text(group.1.first?.name ?? "Unknown"); Spacer(); Text("\(group.1.count) Versions").foregroundStyle(.secondary) }
				}
			}
			if groups.isEmpty { if #available(iOS 17, *) { ContentUnavailableView("No Version Groups", systemImage: "clock.arrow.circlepath", description: Text("Import multiple versions of the same bundle identifier to see them here.")) } else { Text("Import multiple versions of the same bundle identifier to see them here.") } }
		}
		.navigationTitle("Version Vault")
	}
}

struct SparrowVersionHistoryView: View {
	let name: String; let identifier: String; let versions: [Imported]
	@State private var signingApp: AnyApp?
	@State private var installApp: AnyApp?
	@State private var deletingApp: Imported?
	var sorted: [Imported] { versions.sorted { ($0.version ?? "").compare($1.version ?? "", options: .numeric) == .orderedDescending } }
	var body: some View {
		List {
			Section { Text(name).font(.title2.bold()); Text(identifier).font(.footnote).foregroundStyle(.secondary) }
	Section("Versions") {
		ForEach(sorted, id: \.objectID) { app in
			VStack(alignment: .leading, spacing: 8) {
				HStack { Text(app.version ?? "Unknown").font(.headline); Spacer(); Text("Imported").font(.footnote).foregroundStyle(.secondary) }
				Text("Imported \(app.date?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown")").font(.footnote).foregroundStyle(.secondary)
				HStack {
					NavigationLink("Inspect") { SparrowIPAInspectorView(app: app) }
					Spacer()
					Button("Sign", systemImage: "signature") { signingApp = AnyApp(base: app) }
					Button("Install", systemImage: "arrow.down.app") { installApp = AnyApp(base: app) }
					Button("Delete", systemImage: "trash", role: .destructive) { deletingApp = app }
				}
			}
		}
	}
		}
		.navigationTitle(name)
		.fullScreenCover(item: $signingApp) { selected in SigningView(app: selected.base) }
		.sheet(item: $installApp) { selected in InstallPreviewView(app: selected.base).presentationDetents([.height(200)]) }
		.confirmationDialog("Delete this imported version?", item: $deletingApp) { app in
			Button("Delete", role: .destructive) { Storage.shared.deleteApp(for: app) }
			Button("Cancel", role: .cancel) { }
		} message: { _ in Text("The original imported version will be removed from Sparrow.") }
	}
}
