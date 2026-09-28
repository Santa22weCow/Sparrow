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
	let candidates: [SparrowStorageCandidate]
	var totalBytes: Int64 { categories.reduce(0) { $0 + $1.bytes } }
	var reclaimableBytes: Int64 { categories.filter(\.removable).reduce(0) { $0 + $1.bytes } }
}

struct SparrowStorageCandidate: Identifiable, Sendable {
	let id: String
	let displayName: String
	let category: String
	let bytes: Int64
	let date: Date?
	let url: URL
	let protectedReason: String?
	var removable: Bool { protectedReason == nil }
}

final class SparrowActiveJobRegistry {
	static let shared = SparrowActiveJobRegistry()
	private var active = Set<String>(); private let lock = NSLock()
	func markActive(_ url: URL) { lock.lock(); active.insert(url.standardizedFileURL.path); lock.unlock() }
	func markInactive(_ url: URL) { lock.lock(); active.remove(url.standardizedFileURL.path); lock.unlock() }
	func protectionReason(for url: URL) -> String? { lock.lock(); defer { lock.unlock() }; let path = url.standardizedFileURL.path; return active.contains(where: { path == $0 || path.hasPrefix($0 + "/") }) ? "In Use" : nil }
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
			let candidates = definitions.filter { $0.3 }.flatMap { _, title, url, _ in
				let entries = (try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey], options: [.skipsHiddenFiles])) ?? []
				return entries.map { item in
					let values = try? item.resourceValues(forKeys: [.contentModificationDateKey]); return SparrowStorageCandidate(id: item.path, displayName: item.lastPathComponent, category: title, bytes: Self.size(of: item, fileManager: fm), date: values?.contentModificationDate, url: item, protectedReason: SparrowActiveJobRegistry.shared.protectionReason(for: item))
				}
			}
			return SparrowStorageReport(categories: categories, candidates: candidates)
		}.value
	}

	func remove(_ category: SparrowStorageCategory) throws { try remove(locations: category.locations, title: category.title) }
	func remove(_ candidate: SparrowStorageCandidate) throws {
		guard candidate.removable, SparrowActiveJobRegistry.shared.protectionReason(for: candidate.url) == nil else { throw CocoaError(.userCancelled) }
		try remove(locations: [candidate.url], title: candidate.displayName)
	}
	private func remove(locations: [URL], title: String) throws {
		let fm = FileManager.default
		for location in locations where fm.fileExists(atPath: location.path) {
			try fm.removeItem(at: location)
		}
		SparrowActivityHistory.shared.record(operation: "Storage Cleanup", result: "Completed", detail: "Removed \(title)")
	}

	private static func size(of url: URL, fileManager: FileManager) -> Int64 {
		guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey], options: [.skipsHiddenFiles]) else { return 0 }
		return enumerator.compactMap { item -> Int64? in
			guard let file = item as? URL, let values = try? file.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]), values.isRegularFile == true else { return nil }
			return Int64(values.fileSize ?? 0)
		}.reduce(0, +)
	}
}
