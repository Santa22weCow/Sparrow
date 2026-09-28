import SwiftUI

struct ArchiveManagerView: View {
	@State private var entries: [(URL, Int64)] = []

	var body: some View {
		List {
			Section("Stored IPA files") {
				ForEach(entries, id: \.0) { entry in
					LabeledContent(entry.0.lastPathComponent, value: ByteCountFormatter.string(fromByteCount: entry.1, countStyle: .file))
				}
			}
		}
		.navigationTitle("App Archive")
		.toolbar { Button("Refresh") { load() } }
		.onAppear(perform: load)
	}

	private func load() {
		let folders = [FileManager.default.archives, FileManager.default.signed]
		entries = folders.flatMap { folder in
			(try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.fileSizeKey], options: .skipsHiddenFiles)) ?? []
		}.filter { $0.pathExtension.lowercased() == "ipa" }.map { url in
			let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? 0
			return (url, size)
		}.sorted { $0.0.lastPathComponent < $1.0.lastPathComponent }
	}
}
