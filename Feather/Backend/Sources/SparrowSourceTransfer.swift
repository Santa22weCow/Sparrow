import Foundation

struct SparrowSourceRecord: Codable, Identifiable { let id: String; let url: URL; let name: String?; let pinned: Bool }

enum SparrowSourceTransfer {
	static func export(_ sources: [AltSource]) -> Data? {
		let records = sources.compactMap { source -> SparrowSourceRecord? in guard let url = source.sourceURL else { return nil }; return .init(id: source.identifier ?? url.absoluteString, url: url, name: source.name, pinned: source.isPinned) }
		return try? JSONEncoder().encode(records)
	}
	static func importRecords(from url: URL, into storage: Storage) throws -> Int {
		let records = try JSONDecoder().decode([SparrowSourceRecord].self, from: Data(contentsOf: url))
		var added = 0
		for record in records where !storage.sourceExists(record.id) {
			storage.addSource(record.url, name: record.name, identifier: record.id, deferSave: true) { _ in }
			added += 1
		}
		storage.saveContext(); return added
	}
}
