import Foundation

struct SparrowStorageCategory: Identifiable, Sendable {
	let id: String
	let title: String
	let bytes: Int64
	let removable: Bool
	let locations: [URL]
}

struct SparrowStorageReport: Sendable {
	let categories: [SparrowStorageCategory]
	var totalBytes: Int64 { categories.reduce(0) { $0 + $1.bytes } }
	var reclaimableBytes: Int64 { categories.filter(\.removable).reduce(0) { $0 + $1.bytes } }
}

final class SparrowStorageManager {
	static let shared = SparrowStorageManager()
	private init() {}

	func scan() async -> SparrowStorageReport {
		await Task.detached(priority: .utility) {
			let fm = FileManager.default
			let definitions: [(String, String, URL, Bool)] = [
				("imported", "Imported IPAs", fm.unsigned, false),
				("signed", "Signed Builds", fm.signed, true),
				("archives", "Downloads & Exports", fm.archives, true),
				("certificates", "Certificates", fm.certificates, false),
				("appSupport", "Sparrow Support Data", URL.applicationSupportDirectory, false),
				("caches", "Source & Inspection Cache", URL.cachesDirectory, true)
			]
			let categories = definitions.map { id, title, url, removable in
				SparrowStorageCategory(id: id, title: title, bytes: Self.size(of: url, fileManager: fm), removable: removable, locations: [url])
			}
			return SparrowStorageReport(categories: categories)
		}.value
	}

	func remove(_ category: SparrowStorageCategory) throws {
		guard category.removable else { return }
		let fm = FileManager.default
		for location in category.locations where fm.fileExists(atPath: location.path) {
			try fm.removeItem(at: location)
			try fm.createDirectory(at: location, withIntermediateDirectories: true)
		}
		SparrowActivityHistory.shared.record(operation: "Storage Cleanup", result: "Completed", detail: "Removed \(category.title)")
	}

	private static func size(of url: URL, fileManager: FileManager) -> Int64 {
		guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey], options: [.skipsHiddenFiles]) else { return 0 }
		return enumerator.compactMap { item -> Int64? in
			guard let file = item as? URL, let values = try? file.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]), values.isRegularFile == true else { return nil }
			return Int64(values.fileSize ?? 0)
		}.reduce(0, +)
	}
}
