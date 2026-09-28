import Foundation

struct SparrowActivityEvent: Codable, Identifiable {
	let id: UUID
	let date: Date
	let operation: String
	let subject: String?
	let result: String
	let detail: String?
}

final class SparrowActivityHistory: ObservableObject {
	static let shared = SparrowActivityHistory()
	@Published private(set) var events: [SparrowActivityEvent] = []
	private let key = "Sparrow.activityHistory"
	private init() { load() }
	func record(operation: String, subject: String? = nil, result: String, detail: String? = nil) {
		events.insert(.init(id: UUID(), date: Date(), operation: operation, subject: subject, result: result, detail: detail), at: 0)
		events = Array(events.prefix(300)); save()
	}
	func clear() { events.removeAll(); save() }
	private func load() { guard let data = UserDefaults.standard.data(forKey: key), let value = try? JSONDecoder().decode([SparrowActivityEvent].self, from: data) else { return }; events = value }
	private func save() { if let data = try? JSONEncoder().encode(events) { UserDefaults.standard.set(data, forKey: key) } }
}
