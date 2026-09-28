import Foundation
import UIKit
import Zip

enum SparrowIconStudioError: LocalizedError {
	case appMissing, unsupportedIcons, invalidImage, archiveFailed
	var errorDescription: String? { switch self { case .appMissing: "The selected app is no longer available."; case .unsupportedIcons: "This app uses a compiled or unsupported icon catalog. Sparrow cannot safely replace it."; case .invalidImage: "The selected image could not be decoded."; case .archiveFailed: "The customized app could not be packaged." } }
}
enum SparrowIconCompatibility: String { case fileBased = "File-based icons: Supported"; case assetCatalog = "Compiled Assets.car: Limited"; case mixed = "Mixed icon storage: Partial"; case unknown = "Icon storage: Unknown" }

final class SparrowIconStudioService {
	static let shared = SparrowIconStudioService()
	private init() {}
	func compatibility(for app: AppInfoPresentable) -> SparrowIconCompatibility {
		guard let root = Storage.shared.getAppDirectory(for: app) else { return .unknown }
		let hasCatalog = FileManager.default.fileExists(atPath: root.appendingPathComponent("Assets.car").path) || (FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)?.compactMap { $0 as? URL }.contains { $0.lastPathComponent == "Assets.car" } ?? false)
		let hasFiles = (FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)?.compactMap { $0 as? URL }.contains { $0.pathExtension.lowercased() == "png" && $0.lastPathComponent.lowercased().contains("icon") } ?? false)
		if hasCatalog && hasFiles { return .mixed }; if hasCatalog { return .assetCatalog }; if hasFiles { return .fileBased }; return .unknown
	}

	func customize(app: AppInfoPresentable, imageData: Data, completion: @escaping (Result<URL, Error>) -> Void) {
		Task.detached(priority: .utility) {
			do {
				guard let image = UIImage(data: imageData), let original = Storage.shared.getAppDirectory(for: app) else { throw SparrowIconStudioError.appMissing }
				let work = FileManager.default.temporaryDirectory.appendingPathComponent("SparrowIcon-\(UUID().uuidString)"); let payload = work.appendingPathComponent("Payload")
				defer { try? FileManager.default.removeItem(at: work) }
				try FileManager.default.createDirectory(at: payload, withIntermediateDirectories: true)
				let copy = payload.appendingPathComponent(original.lastPathComponent); try FileManager.default.copyItem(at: original, to: copy)
				let plist = copy.appendingPathComponent("Info.plist")
				let referenced = ((NSDictionary(contentsOf: plist)?["CFBundleIconFiles"] as? [String]) ?? []).map { $0.hasSuffix(".png") ? $0 : "\($0).png" }
				let files = FileManager.default.enumerator(at: copy, includingPropertiesForKeys: nil)?.compactMap { $0 as? URL }.filter { $0.pathExtension.lowercased() == "png" && (referenced.contains($0.lastPathComponent) || $0.lastPathComponent.lowercased().contains("icon")) } ?? []
				guard !files.isEmpty else { throw SparrowIconStudioError.unsupportedIcons }
				let square = Self.square(image)
				for file in files { guard let data = square.pngData() else { throw SparrowIconStudioError.invalidImage }; try data.write(to: file, options: .atomic) }
				let archive = work.appendingPathComponent("SparrowIcon.ipa"); try Zip.zipFiles(paths: [payload], zipFilePath: archive, password: nil, compression: ZipCompression.allCases[ArchiveHandler.getCompressionLevel()], progress: nil); completion(.success(archive))
			} catch { completion(.failure(error)) }
		}
	}

	private static func square(_ image: UIImage) -> UIImage {
		let side = min(image.size.width, image.size.height); let origin = CGPoint(x: (image.size.width - side) / 2, y: (image.size.height - side) / 2)
		return UIGraphicsImageRenderer(size: CGSize(width: 1024, height: 1024)).image { _ in image.draw(in: CGRect(x: -origin.x * 1024 / side, y: -origin.y * 1024 / side, width: image.size.width * 1024 / side, height: image.size.height * 1024 / side)) }
	}
}
