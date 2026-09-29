import Foundation

struct SparrowSourceHealth: Identifiable { let id: String; let status: String; let responseTime: TimeInterval?; let appCount: Int?; let error: String? }

enum SparrowSourceHealthChecker {
	static func check(_ source: AltSource) async -> SparrowSourceHealth {
		let identifier = source.identifier ?? source.sourceURL?.absoluteString ?? UUID().uuidString
		guard let url = source.sourceURL else { return .init(id: identifier, status: "Invalid", responseTime: nil, appCount: nil, error: "Missing URL") }
		let start = Date(); var request = URLRequest(url: url); request.timeoutInterval = 15
		do {
			let (data, response) = try await URLSession.shared.data(for: request)
			guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw URLError(.badServerResponse) }
			guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return .init(id: identifier, status: "Invalid Format", responseTime: Date().timeIntervalSince(start), appCount: nil, error: "Source response is not a JSON object.") }
			guard let apps = json["apps"] as? [[String: Any]] else { return .init(id: identifier, status: "Missing Required Fields", responseTime: Date().timeIntervalSince(start), appCount: nil, error: "The source does not contain an apps array.") }
			let unavailable = apps.filter { app in
				guard let urlString = app["downloadURL"] as? String else { return true }
				return URL(string: urlString) == nil
			}.count
			let status = unavailable > 0 ? "Some Apps Unavailable" : (Date().timeIntervalSince(start) > 3 ? "Valid (Slow)" : "Valid")
			return .init(id: identifier, status: status, responseTime: Date().timeIntervalSince(start), appCount: apps.count, error: unavailable > 0 ? "\(unavailable) app download URL(s) are invalid." : nil)
		} catch { return .init(id: identifier, status: "Unavailable", responseTime: Date().timeIntervalSince(start), appCount: nil, error: error.localizedDescription) }
	}
}
