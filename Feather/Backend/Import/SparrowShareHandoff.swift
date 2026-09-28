import Foundation

/// Transactional handoff storage shared by Sparrow and its future Share Extension.
/// Jobs are only visible after `ready` is atomically written, so a killed extension
/// cannot cause the main app to import a half-copied IPA.
final class SparrowShareHandoff {
	static let shared = SparrowShareHandoff()
	private let fm = FileManager.default
	private let group = "group.com.sparrow.app"
	private init() {}

	struct Job: Codable {
		let id: String
		let filename: String
		let createdAt: Date
		let action: String
		let size: Int64
	}

	private var root: URL? { fm.containerURL(forSecurityApplicationGroupIdentifier: group)?.appendingPathComponent("PendingImports", isDirectory: true) }

	func createJob(from source: URL, action: String) throws -> Job {
		guard let root else { throw CocoaError(.fileNoSuchFile) }
		try fm.createDirectory(at: root, withIntermediateDirectories: true)
		let id = UUID().uuidString
		let dir = root.appendingPathComponent(id, isDirectory: true)
		let temp = root.appendingPathComponent(".\(id).partial", isDirectory: true)
		try fm.createDirectory(at: temp, withIntermediateDirectories: true)
		let destination = temp.appendingPathComponent(source.lastPathComponent)
		try fm.copyItem(at: source, to: destination)
		let size = (try? destination.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? 0
		let job = Job(id: id, filename: source.lastPathComponent, createdAt: Date(), action: action, size: size)
		let data = try JSONEncoder().encode(job)
		try data.write(to: temp.appendingPathComponent("import.json"), options: .atomic)
		try fm.moveItem(at: temp, to: dir)
		try Data("ready".utf8).write(to: dir.appendingPathComponent("ready"), options: .atomic)
		return job
	}

	func consumeReadyJobs() -> [(Job, URL)] {
		guard let root, let entries = try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: [.contentModificationDateKey]) else { return [] }
		var result: [(Job, URL)] = []
		for dir in entries where dir.lastPathComponent.first != "." {
			guard fm.fileExists(atPath: dir.appendingPathComponent("ready").path),
				let data = try? Data(contentsOf: dir.appendingPathComponent("import.json")),
				let job = try? JSONDecoder().decode(Job.self, from: data),
				let file = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil).first(where: { $0.pathExtension.lowercased() == "ipa" || $0.pathExtension.lowercased() == "tipa" }) else { continue }
			result.append((job, file))
		}
		return result
	}

	func remove(job: Job) { guard let root else { return }; try? fm.removeItem(at: root.appendingPathComponent(job.id)) }
}
