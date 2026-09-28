import Foundation
import Zip

enum SparrowCloneError: LocalizedError { case appMissing, invalidInfo, insufficientStorage, archiveFailed
	var errorDescription: String? { switch self { case .appMissing: "The original app could not be found."; case .invalidInfo: "The app metadata could not be read."; case .insufficientStorage: "Not enough storage is available for a safe clone."; case .archiveFailed: "The cloned IPA could not be packaged." } }
}

final class SparrowCloneService {
	static let shared = SparrowCloneService()
	private init() {}

	func clone(app: AppInfoPresentable, name: String, identifier: String, version: String?, build: String?, completion: @escaping (Result<URL, Error>) -> Void) {
		Task.detached(priority: .utility) {
			let fm = FileManager.default; let work = fm.temporaryDirectory.appendingPathComponent("SparrowClone-\(UUID().uuidString)"); let payload = work.appendingPathComponent("Payload")
			defer { try? fm.removeItem(at: work) }
			do {
				guard let original = Storage.shared.getAppDirectory(for: app) else { throw SparrowCloneError.appMissing }
				let size = (try? original.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
				guard (try fm.attributesOfFileSystem(forPath: fm.temporaryDirectory.path)[.systemFreeSize] as? NSNumber)?.int64Value ?? 0 > Int64(size * 3) else { throw SparrowCloneError.insufficientStorage }
				try fm.createDirectory(at: payload, withIntermediateDirectories: true); let cloned = payload.appendingPathComponent(original.lastPathComponent); try fm.copyItem(at: original, to: cloned)
				let plist = cloned.appendingPathComponent("Info.plist"); guard var info = NSDictionary(contentsOf: plist) as? [String: Any] else { throw SparrowCloneError.invalidInfo }
				let originalID = info["CFBundleIdentifier"] as? String ?? ""; info["CFBundleIdentifier"] = identifier; info["CFBundleDisplayName"] = name; info["CFBundleName"] = name
				if let version, !version.isEmpty { info["CFBundleShortVersionString"] = version }; if let build, !build.isEmpty { info["CFBundleVersion"] = build }
				try (info as NSDictionary).write(to: plist)
				for url in fm.enumerator(at: cloned, includingPropertiesForKeys: nil)?.compactMap({ $0 as? URL }) ?? [] {
					if url.lastPathComponent == "_CodeSignature" { try? fm.removeItem(at: url) }
					if url.lastPathComponent == "Info.plist", url.path != plist.path, var nested = NSDictionary(contentsOf: url) as? [String: Any], let nestedID = nested["CFBundleIdentifier"] as? String, nestedID.hasPrefix(originalID + ".") { nested["CFBundleIdentifier"] = identifier + String(nestedID.dropFirst(originalID.count)); try? (nested as NSDictionary).write(to: url) }
				}
				let archive = work.appendingPathComponent("SparrowClone.ipa"); try Zip.zipFiles(paths: [payload], zipFilePath: archive, password: nil, compression: ZipCompression.allCases[ArchiveHandler.getCompressionLevel()], progress: nil); completion(.success(archive))
			} catch { completion(.failure(error)) }
		}
	}
}
