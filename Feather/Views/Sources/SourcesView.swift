//
//  SourcesView.swift
//  Feather
//
//  Created by samara on 10.04.2025.
//

import CoreData
import AltSourceKit
import SwiftUI
import NimbleViews
import UniformTypeIdentifiers

// MARK: - View
struct SourcesView: View {
	#if !NIGHTLY && !DEBUG
		@AppStorage("Feather.shouldStar") private var _shouldStar: Int = 0
	#endif
	@StateObject var viewModel = SourcesViewModel.shared
	@State private var _isAddingPresenting = false
	@State private var _addingSourceLoading = false
	@State private var _isImportingSources = false
	@State private var _exportData: Data?
	@State private var _clipboardURLs: [URL] = []
	@State private var _showClipboardSources = false
	@State private var _searchText = ""
	
	private var _filteredSources: [AltSource] {
		_sources.filter { _searchText.isEmpty || ($0.name?.localizedCaseInsensitiveContains(_searchText) ?? false) }
	}
	private var clipboardSourceURLs: [URL] {
		let text = UIPasteboard.general.string ?? ""
		return text.split(whereSeparator: { CharacterSet.whitespacesAndNewlines.contains($0.unicodeScalars.first!) }).compactMap { URL(string: String($0)) }.filter { $0.scheme == "https" || $0.scheme == "http" }
	}
	
	@FetchRequest(
		entity: AltSource.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.isPinned, ascending: false), NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
		animation: .snappy
	) private var _sources: FetchedResults<AltSource>
	
	// MARK: Body
	var body: some View {
		NBNavigationView(.localized("Sources")) {
			NBListAdaptable {
				if !_filteredSources.isEmpty {
					NBSection(
						.localized("Repositories"),
						secondary: _filteredSources.count.description
					) {
						ForEach(_filteredSources) { source in
							NavigationLink {
								SourceAppsView(object: [source], viewModel: viewModel)
							} label: {
								SourcesCellView(source: source)
							}
							.buttonStyle(.plain)
							.contextMenu {
								Button(source.isPinned ? "Unpin Source" : "Pin Source", systemImage: source.isPinned ? "pin.slash" : "pin") {
									Storage.shared.togglePinned(source)
								}
							}
						}
					}
				}
			}
			.searchable(text: $_searchText, placement: .platform())
			.overlay {
				if _filteredSources.isEmpty {
					if #available(iOS 17, *) {
						ContentUnavailableView {
							Label(.localized("No Repositories"), systemImage: "globe.desk.fill")
						} description: {
							Text(.localized("Get started by adding your first repository."))
						} actions: {
							Button {
								_isAddingPresenting = true
							} label: {
								NBButton(.localized("Add Source"), style: .text)
							}
						}
					}
				}
			}
			.toolbar {
				ToolbarItemGroup(placement: .topBarLeading) {
					Button("Export Sources", systemImage: "square.and.arrow.up") { _exportData = SparrowSourceTransfer.export(Array(_sources)) }
					Button("Import Sources", systemImage: "square.and.arrow.down") { _isImportingSources = true }
					Button("Add from Clipboard", systemImage: "doc.on.clipboard") {
						_clipboardURLs = clipboardSourceURLs
						_showClipboardSources = !_clipboardURLs.isEmpty
					}
				}
				NBToolbarButton(
					systemImage: "plus",
					style: .icon,
					placement: .topBarTrailing,
					isDisabled: _addingSourceLoading
				) {
					_isAddingPresenting = true
				}
			}
			.refreshable {
				await viewModel.fetchSources(_sources, refresh: true)
			}
			.sheet(isPresented: $_isAddingPresenting) {
				SourcesAddView()
			}
			.fileImporter(isPresented: $_isImportingSources, allowedContentTypes: [.json]) { result in
				if case .success(let url) = result, url.startAccessingSecurityScopedResource() { defer { url.stopAccessingSecurityScopedResource() }; _ = try? SparrowSourceTransfer.importRecords(from: url, into: Storage.shared) }
			}
			.sheet(isPresented: Binding(get: { _exportData != nil }, set: { if !$0 { _exportData = nil } })) { if let data = _exportData { ShareLink(item: data, preview: SharePreview("Sparrow Sources", image: Image(systemName: "globe"))).padding() } }
			.alert("Add Sources from Clipboard", isPresented: $_showClipboardSources) {
				Button("Add") { for url in _clipboardURLs { Storage.shared.addSource(url, identifier: url.absoluteString) { _ in } } }
				Button("Cancel", role: .cancel) { }
			} message: { Text("Found \(_clipboardURLs.count) web URL(s). Add them to Sparrow?") }
		}
		.task(id: Array(_sources)) {
			await viewModel.fetchSources(_sources)
		}
		#if !NIGHTLY && !DEBUG
		.onAppear {
				guard _shouldStar < 6 else { return }; _shouldStar += 1
				guard _shouldStar == 6 else { return }
			
				let github = UIAlertAction(title: "GitHub", style: .default) { _ in
					UIApplication.open("https://github.com/valentinobomba10-afk/Sparrow")
				}
			
				let cancel = UIAlertAction(title: .localized("Dismiss"), style: .cancel)
			
				UIAlertController.showAlert(
					title: .localized("Enjoying %@?", arguments: Bundle.main.name),
					message: .localized("Go to our GitHub and give us a star!"),
					actions: [github, cancel]
				)
			}
		#endif
	}
}
