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
			let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
			let count = (json?["apps"] as? [[String: Any]])?.count
			return .init(id: identifier, status: Date().timeIntervalSince(start) > 3 ? "Slow" : "Healthy", responseTime: Date().timeIntervalSince(start), appCount: count, error: nil)
		} catch { return .init(id: identifier, status: "Unavailable", responseTime: Date().timeIntervalSince(start), appCount: nil, error: error.localizedDescription) }
	}
}
