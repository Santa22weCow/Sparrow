import Foundation

struct SparrowIPAInspection {
	struct Component: Identifiable { let id = UUID(); let kind: String; let name: String; let bundleID: String?; let path: String; let size: Int64 }
	let appName: String; let bundleIdentifier: String; let version: String; let build: String; let minimumOS: String?; let executable: String?; let bundlePath: String; let appSize: Int64; let components: [Component]; let urlSchemes: [String]; let entitlements: [String]
}

enum SparrowIPAInspector {
	static func inspect(_ app: AppInfoPresentable) throws -> SparrowIPAInspection {
		guard let directory = Storage.shared.getAppDirectory(for: app) else { throw CocoaError(.fileNoSuchFile) }
		let fm = FileManager.default; let plistURL = directory.appendingPathComponent("Info.plist")
		guard let info = NSDictionary(contentsOf: plistURL) as? [String: Any] else { throw CocoaError(.fileReadCorruptFile) }
		let size = directorySize(directory, fm: fm)
		var components: [SparrowIPAInspection.Component] = []
		let enumerator = fm.enumerator(at: directory, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey])
		while let url = enumerator?.nextObject() as? URL {
			let relative = url.path.replacingOccurrences(of: directory.path + "/", with: "")
			let values = try? url.resourceValues(forKeys: [.fileSizeKey]); let itemSize = Int64(values?.fileSize ?? 0)
			if url.pathExtension == "appex" { let nested = NSDictionary(contentsOf: url.appendingPathComponent("Info.plist")) as? [String: Any]; components.append(.init(kind: "Extension", name: nested?["CFBundleDisplayName"] as? String ?? url.deletingPathExtension().lastPathComponent, bundleID: nested?["CFBundleIdentifier"] as? String, path: relative, size: itemSize)) }
			else if url.pathExtension == "framework" { components.append(.init(kind: "Framework", name: url.deletingPathExtension().lastPathComponent, bundleID: nil, path: relative, size: itemSize)) }
			else if url.pathExtension == "dylib" { components.append(.init(kind: "Dynamic Library", name: url.lastPathComponent, bundleID: nil, path: relative, size: itemSize)) }
			else if url.pathExtension == "app" && relative != "" && relative != directory.lastPathComponent { let nested = NSDictionary(contentsOf: url.appendingPathComponent("Info.plist")) as? [String: Any]; components.append(.init(kind: relative.contains("Watch") ? "Watch App" : "Embedded App", name: nested?["CFBundleDisplayName"] as? String ?? url.deletingPathExtension().lastPathComponent, bundleID: nested?["CFBundleIdentifier"] as? String, path: relative, size: itemSize)) }
		}
		let schemes = (info["CFBundleURLTypes"] as? [[String: Any]] ?? []).flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }
		let entitlementKeys = ["application-identifier": "App Identifier", "com.apple.security.application-groups": "App Groups", "keychain-access-groups": "Keychain Sharing", "com.apple.developer.associated-domains": "Associated Domains", "aps-environment": "Push Notifications", "com.apple.developer.icloud-container-identifiers": "iCloud", "get-task-allow": "Debuggable"].compactMap { info[$0.key] != nil ? $0.value : nil }
		return .init(appName: info["CFBundleDisplayName"] as? String ?? info["CFBundleName"] as? String ?? app.name ?? "Unknown", bundleIdentifier: info["CFBundleIdentifier"] as? String ?? app.identifier ?? "Unknown", version: info["CFBundleShortVersionString"] as? String ?? app.version ?? "Unknown", build: info["CFBundleVersion"] as? String ?? "Unknown", minimumOS: info["MinimumOSVersion"] as? String, executable: info["CFBundleExecutable"] as? String, bundlePath: directory.path, appSize: size, components: components, urlSchemes: schemes, entitlements: entitlementKeys)
	}
	private static func directorySize(_ url: URL, fm: FileManager) -> Int64 { Int64((fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey])?.compactMap { try? ($0 as? URL)?.resourceValues(forKeys: [.fileSizeKey]).fileSize }.reduce(0, +)) ?? 0) }
}
