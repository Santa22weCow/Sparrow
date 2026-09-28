import SwiftUI

struct EmbeddedLibrariesView: View {
	let app: AppInfoPresentable
	@State private var files: [URL] = []
	@State private var search = ""
	var body: some View {
		List {
			ForEach(files.filter { search.isEmpty || $0.lastPathComponent.localizedCaseInsensitiveContains(search) }, id: \.path) { file in
				HStack { VStack(alignment: .leading) { Text(file.lastPathComponent); Text(file.path).font(.caption).foregroundStyle(.secondary) }; Spacer(); if file.pathExtension == "dylib" { ShareLink(item: file) { Image(systemName: "square.and.arrow.up") } } }
			}
		}
		.searchable(text: $search)
		.navigationTitle("Embedded Libraries")
		.task { scan() }
	}
	private func scan() { guard let root = Storage.shared.getAppDirectory(for: app), let e = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) else { return }; files = e.compactMap { $0 as? URL }.filter { $0.pathExtension == "dylib" || $0.pathExtension == "framework" } }
}
