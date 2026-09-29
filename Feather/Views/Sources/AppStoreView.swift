import CoreData
import SwiftUI
import AltSourceKit
import NimbleViews
import NukeUI
import NaturalLanguage

struct AppStoreView: View {
	@StateObject private var viewModel = SourcesViewModel.shared
	@FetchRequest(entity: AltSource.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)]) private var sources: FetchedResults<AltSource>
	@State private var selectedCategory = "All"
	private let categories = ["All", "Entertainment", "Utilities", "Games", "Productivity"]
	private var items: [AppStoreItem] {
		var values = sources.compactMap { source -> [AppStoreItem]? in guard let repository = viewModel.sources[source] else { return nil }; return repository.apps.map { AppStoreItem(sourceURL: source.sourceURL, source: repository, app: $0) } }.flatMap { $0 }
		if selectedCategory != "All" { values = values.filter { $0.app.category?.localizedCaseInsensitiveCompare(selectedCategory) == .orderedSame } }
		return values
	}
	private var featured: AppStoreItem? { items.first }
	private var mustHave: [AppStoreItem] { Array(items.dropFirst(featured == nil ? 0 : 1).prefix(12)) }
	var body: some View {
		ScrollView { VStack(alignment: .leading, spacing: 24) {
			Text("Apps").font(.system(size: 42, weight: .bold, design: .rounded)).padding(.horizontal)
			ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 12) { ForEach(categories, id: \.self) { category in Button { selectedCategory = category } label: { Text(category).font(.headline).foregroundStyle(selectedCategory == category ? .primary : .secondary).padding(.horizontal, 20).padding(.vertical, 12).background(.thinMaterial, in: Capsule()) } } }.padding(.horizontal) }
			if let featured { NavigationLink { SourceAppsDetailView(sourceURL: featured.sourceURL, source: featured.source, app: featured.app) } label: { AppStoreFeaturedCard(item: featured) }.buttonStyle(.plain).padding(.horizontal) }
			if !mustHave.isEmpty { AppStoreSection(title: "Must-Have for iPhone", subtitle: "Get started with these apps", items: mustHave) }
			if items.isEmpty { Text("Add repositories in Sources to fill your App Store.").foregroundStyle(.secondary).padding(.horizontal) }
		}.padding(.vertical) }.background(Color(uiColor: .systemBackground)).navigationTitle("").refreshable { await viewModel.fetchSources(sources, refresh: true) }.task { await viewModel.fetchSources(sources) }
	}
}

private struct AppStoreItem: Identifiable { let sourceURL: URL?; let source: ASRepository; let app: ASRepository.App; var id: String { "\(source.id ?? source.name ?? "source")-\(app.currentUniqueId)" } }

private struct AppStoreFeaturedCard: View {
	let item: AppStoreItem
	var body: some View { VStack(alignment: .leading, spacing: 0) { ZStack(alignment: .bottomLeading) { if let url = item.app.screenshotURLs?.first { LazyImage(url: url) { state in (state.image ?? Image(systemName: "app.fill")).resizable().scaledToFill() }.frame(height: 250).clipped() } else { RoundedRectangle(cornerRadius: 28).fill(Color.accentColor.gradient).frame(height: 250) }; LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .center, endPoint: .bottom); VStack(alignment: .leading, spacing: 4) { Text(item.app.currentName).font(.title.bold()); Text(item.app.currentDescription ?? "").lineLimit(2).font(.subheadline) }.foregroundStyle(.white).padding(20) }; HStack { FRIconCellView(title: item.app.currentName, subtitle: item.app.currentVersion ?? "", iconUrl: item.app.iconURL); Spacer(); DownloadButtonView(sourceURL: item.sourceURL, source: item.source, app: item.app) }.padding(12).background(.ultraThinMaterial) }.clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous)).shadow(color: .black.opacity(0.12), radius: 12, y: 5) }
}

private struct AppStoreSection: View {
	let title: String; let subtitle: String; let items: [AppStoreItem]
	var body: some View { VStack(alignment: .leading, spacing: 4) { HStack { VStack(alignment: .leading) { Text(title).font(.title2.bold()); Text(subtitle).foregroundStyle(.secondary) }; Spacer(); Image(systemName: "chevron.right").foregroundStyle(.secondary) }.padding(.horizontal); ForEach(items) { item in NavigationLink { SourceAppsDetailView(sourceURL: item.sourceURL, source: item.source, app: item.app) } label: { AppStoreListRow(item: item) }.buttonStyle(.plain) } } }
}

private struct AppStoreListRow: View {
	let item: AppStoreItem
	var body: some View { HStack(spacing: 14) { LazyImage(url: item.app.iconURL) { state in (state.image ?? Image(systemName: "app.fill")).resizable().scaledToFit() }.frame(width: 62, height: 62).clipShape(RoundedRectangle(cornerRadius: 14)); VStack(alignment: .leading, spacing: 3) { Text(item.app.currentName).font(.headline); SparrowTranslatedText(text: item.app.currentDescription ?? item.app.subtitle ?? "", fallback: item.app.localizedDescription).foregroundStyle(.secondary).lineLimit(2) }; Spacer(); DownloadButtonView(sourceURL: item.sourceURL, source: item.source, app: item.app) }.padding(.horizontal).padding(.vertical, 8) }
}

private struct SparrowTranslatedText: View {
	let text: String
	let fallback: String?
	@State private var detectedLanguage: NLLanguage?
	var body: some View {
		Text(displayText).font(.subheadline).task {
			let recognizer = NLLanguageRecognizer(); recognizer.processString(text); detectedLanguage = recognizer.dominantLanguage
		}
	}
	private var displayText: String {
		guard detectedLanguage != nil, detectedLanguage != .english, let fallback, !fallback.isEmpty else { return text }
		return fallback
	}
}
