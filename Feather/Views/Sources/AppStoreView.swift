import CoreData
import SwiftUI
import AltSourceKit
import NimbleViews

struct AppStoreView: View {
	@StateObject private var viewModel = SourcesViewModel.shared
	@FetchRequest(entity: AltSource.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)]) private var sources: FetchedResults<AltSource>

	var body: some View {
		NBNavigationView("App Store") {
			if sources.isEmpty {
				VStack(spacing: 12) {
					Image(systemName: "bag").font(.largeTitle)
					Text("No Sources").font(.headline)
					Text("Add repositories in Sources to fill your App Store.").foregroundStyle(.secondary)
				}
			} else {
				SourceAppsView(object: Array(sources), title: "App Store", viewModel: viewModel)
					.refreshable { await viewModel.fetchSources(sources, refresh: true) }
			}
		}
		.task { await viewModel.fetchSources(sources) }
	}
}
