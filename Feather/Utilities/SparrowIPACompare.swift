import Foundation

struct SparrowIPAComparison {
	let left: SparrowIPAInspection
	let right: SparrowIPAInspection
	var versionChanged: Bool { left.version != right.version }
	var buildChanged: Bool { left.build != right.build }
	var sizeDelta: Int64 { right.appSize - left.appSize }
	var addedComponents: [String] { componentKeys(right).subtracting(componentKeys(left)).sorted() }
	var removedComponents: [String] { componentKeys(left).subtracting(componentKeys(right)).sorted() }
	var addedSchemes: [String] { Set(right.urlSchemes).subtracting(left.urlSchemes).sorted() }
	var removedSchemes: [String] { Set(left.urlSchemes).subtracting(right.urlSchemes).sorted() }
	private func componentKeys(_ value: SparrowIPAInspection) -> Set<String> { Set(value.components.map { "\($0.kind):\($0.bundleID ?? $0.name)" }) }
}

enum SparrowIPACompareService {
	static func compare(_ left: AppInfoPresentable, _ right: AppInfoPresentable) throws -> SparrowIPAComparison { .init(left: try SparrowIPAInspector.inspect(left), right: try SparrowIPAInspector.inspect(right)) }
}
