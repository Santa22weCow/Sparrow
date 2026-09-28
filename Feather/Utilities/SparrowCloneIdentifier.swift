import Foundation

struct SparrowCloneIdentifierResult: Equatable {
	let identifier: String
	let valid: Bool
	let message: String?
}

enum SparrowCloneIdentifier {
	static func suggestions(for original: String) -> [String] {
		let base = original.isEmpty ? "com.sparrow.app" : original
		let name = base.split(separator: ".").last.map(String.init) ?? "app"
		return ["\(base).clone", "\(base).clone2", "com.sparrow.clone.\(name)"]
	}

	static func validate(_ value: String, existing: Set<String> = []) -> SparrowCloneIdentifierResult {
		guard value.count <= 255, !value.contains(" ") else { return .init(identifier: value, valid: false, message: "Bundle identifier must not contain spaces and must be 255 characters or fewer.") }
		let parts = value.split(separator: ".", omittingEmptySubsequences: false)
		guard parts.count >= 2, parts.allSatisfy({ !$0.isEmpty && $0.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" } }) else { return .init(identifier: value, valid: false, message: "Use reverse-domain format such as com.sparrow.clone.app.") }
		guard !existing.contains(value) else { return .init(identifier: value, valid: false, message: "That bundle identifier is already in use.") }
		return .init(identifier: value, valid: true, message: nil)
	}
}
