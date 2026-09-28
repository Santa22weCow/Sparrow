import SwiftUI
import UniformTypeIdentifiers
import IDeviceSwift

private struct SparrowDeviceIdentifier: Identifiable {
	let id = UUID()
	let name: String
	let value: String
}

struct SparrowDeviceIdentifiersView: View {
	@State private var copied = false
	private var identifiers: [SparrowDeviceIdentifier] {
		var values = [
			SparrowDeviceIdentifier(name: "Device name", value: UIDevice.current.name),
			SparrowDeviceIdentifier(name: "Model", value: UIDevice.current.model),
			SparrowDeviceIdentifier(name: "System version", value: UIDevice.current.systemVersion)
		]
		if let vendor = UIDevice.current.identifierForVendor?.uuidString {
			values.append(SparrowDeviceIdentifier(name: "Identifier for vendor", value: vendor))
		}
		let pairing = HeartbeatManager.pairingFile()
		if FileManager.default.fileExists(atPath: pairing) {
			values.append(SparrowDeviceIdentifier(name: "Pairing metadata", value: "Available locally (contents hidden)"))
		}
		return values
	}
	var body: some View {
		List {
			Section("Local device identifiers") {
				ForEach(identifiers) { item in
					Button { UIPasteboard.general.string = item.value; copied = true } label: {
						LabeledContent(item.name, value: item.value).contentShape(Rectangle())
					}
				}
			}
			Section { Text("Sparrow only shows identifiers supplied by iOS or existing local pairing metadata. It never fabricates or uploads a UDID.").font(.footnote).foregroundStyle(.secondary) }
		}
		.navigationTitle("Device Identifiers")
		.toolbar { ToolbarItem(placement: .topBarTrailing) { Button(copied ? "Copied" : "Copy All") { UIPasteboard.general.string = identifiers.map { "\($0.name): \($0.value)" }.joined(separator: "\n"); copied = true } } }
	}
}

struct SparrowJITEnablerView: View {
	private var pairingAvailable: Bool { FileManager.default.fileExists(atPath: HeartbeatManager.pairingFile()) }
	var body: some View {
		Form {
			Section("JIT status") {
				Label(pairingAvailable ? "Pairing metadata detected" : "Pairing metadata not found", systemImage: pairingAvailable ? "checkmark.circle" : "exclamationmark.triangle")
				Text("Sparrow does not claim JIT is enabled unless a supported Apple pairing/tunnel helper confirms it. This build can inspect local pairing state, but iOS does not provide a public in-app JIT entitlement.").font(.footnote).foregroundStyle(.secondary)
			}
			Section("Next step") {
				Button("Open Pairing & Tunnel Settings") { NotificationCenter.default.post(name: .sparrowOpenTunnelSettings, object: nil) }
				Text("Use a compatible external helper and return to Sparrow to refresh diagnostics. No fake success state is recorded.").font(.footnote).foregroundStyle(.secondary)
			}
		}
		.navigationTitle("JIT Enabler")
	}
}

extension Notification.Name { static let sparrowOpenTunnelSettings = Notification.Name("SparrowOpenTunnelSettings") }

struct SparrowFileManagerView: View {
	private enum Location: String, CaseIterable, Identifiable {
		case unsigned = "Unsigned", signed = "Signed", archives = "Archives", certificates = "Certificates"
		var id: String { rawValue }
		var url: URL {
			switch self {
			case .unsigned: return FileManager.default.unsigned
			case .signed: return FileManager.default.signed
			case .archives: return FileManager.default.archives
			case .certificates: return FileManager.default.certificates
			}
		}
	}
	@State private var location: Location = .unsigned
	@State private var files: [URL] = []
	@State private var search = ""
	@State private var error: String?
	private var shownFiles: [URL] { files.filter { search.isEmpty || $0.lastPathComponent.localizedCaseInsensitiveContains(search) } }
	var body: some View {
		List {
			Section { Picker("Location", selection: $location) { ForEach(Location.allCases) { Text($0.rawValue).tag($0) } } }
			Section("Files") {
				ForEach(shownFiles, id: \.path) { file in
					NavigationLink { SparrowFilePreviewView(url: file) } label: { Label(file.lastPathComponent, systemImage: icon(for: file)) }
					.swipeActions { Button(role: .destructive) { try? FileManager.default.removeItem(at: file); refresh() } label: { Label("Delete", systemImage: "trash") } }
				}
				if shownFiles.isEmpty { Label("No files", systemImage: "folder").foregroundStyle(.secondary) }
			}
			if let error { Section { Text(error).foregroundStyle(.red) } }
		}
		.navigationTitle("File Manager")
		.searchable(text: $search)
		.task { refresh() }
		.onChange(of: location) { _ in refresh() }
	}
	private func refresh() { do { try FileManager.default.createDirectory(at: location.url, withIntermediateDirectories: true); files = try FileManager.default.contentsOfDirectory(at: location.url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) } catch let refreshError { error = refreshError.localizedDescription } }
	private func icon(for url: URL) -> String { switch url.pathExtension.lowercased() { case "ipa": "app.badge"; case "mobileprovision": "person.text.rectangle"; case "p12", "pfx": "key"; case "plist": "doc.text"; case "zip": "doc.zipper"; default: "doc" } }
}

struct SparrowFilePreviewView: View {
	let url: URL
	var body: some View {
		List {
			Section("File") { LabeledContent("Name", value: url.lastPathComponent); LabeledContent("Type", value: url.pathExtension.uppercased()); LabeledContent("Location", value: url.deletingLastPathComponent().lastPathComponent) }
			if url.pathExtension.lowercased() == "plist", let data = try? Data(contentsOf: url), let text = String(data: data, encoding: .utf8) { Section("Preview") { Text(text).font(.system(.footnote, design: .monospaced)).textSelection(.enabled) } }
			Section { ShareLink(item: url) { Label("Share / Export", systemImage: "square.and.arrow.up") } }
		}
		.navigationTitle(url.lastPathComponent)
	}
}

struct SparrowCapabilitiesView: View {
	@FetchRequest(entity: Imported.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Imported.date, ascending: false)]) private var apps: FetchedResults<Imported>
	var body: some View {
		List {
			Section("Choose an app") { ForEach(apps, id: \.objectID) { app in NavigationLink(app.name ?? app.identifier ?? "Unknown") { SparrowIPAInspectorView(app: app) } } }
		}
		.navigationTitle("App Capabilities")
	}
}
