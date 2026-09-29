import Foundation
import AltSourceKit

enum RepositoryCache {
	private static let directory = URL.cachesDirectory.appendingPathComponent("RepositoryCache", isDirectory: true)

	static func repository(for url: URL) -> ASRepository? {
		let file = directory.appendingPathComponent(url.absoluteString.data(using: .utf8)!.base64EncodedString())
		guard let data = try? Data(contentsOf: file) else { return nil }
		return try? JSONDecoder().decode(ASRepository.self, from: data)
	}

	static func repositoryAsync(for url: URL) async -> ASRepository? {
		await Task.detached(priority: .utility) {
			repository(for: url)
		}.value
	}

	static func save(_ data: Data, for url: URL) {
		try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
		let file = directory.appendingPathComponent(url.absoluteString.data(using: .utf8)!.base64EncodedString())
		try? data.write(to: file, options: .atomic)
	}
}
