import UIKit
import UniformTypeIdentifiers

/// Lightweight Share Extension handoff. Heavy validation/signing stays in Sparrow.
final class ShareViewController: UIViewController {
	private var provider: NSItemProvider?
	private var sharedURL: URL?

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .systemBackground
		let title = UILabel(); title.text = "Sparrow"; title.font = .preferredFont(forTextStyle: .title2); title.translatesAutoresizingMaskIntoConstraints = false
		let importButton = UIButton(type: .system); importButton.setTitle("Import", for: .normal); importButton.addTarget(self, action: #selector(importFile), for: .touchUpInside); importButton.translatesAutoresizingMaskIntoConstraints = false
		let signButton = UIButton(type: .system); signButton.setTitle("Import & Sign", for: .normal); signButton.addTarget(self, action: #selector(importAndSign), for: .touchUpInside); signButton.translatesAutoresizingMaskIntoConstraints = false
		let stack = UIStackView(arrangedSubviews: [title, importButton, signButton]); stack.axis = .vertical; stack.spacing = 18; stack.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(stack)
		NSLayoutConstraint.activate([stack.centerXAnchor.constraint(equalTo: view.centerXAnchor), stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)])
		guard let item = extensionContext?.inputItems.first as? NSExtensionItem, let attachment = item.attachments?.first else { return }
		provider = attachment
		attachment.loadFileRepresentation(forTypeIdentifier: UTType.data.identifier) { [weak self] url, _ in self?.sharedURL = url }
	}

	@objc private func importFile() { handoff(action: "import") }
	@objc private func importAndSign() { handoff(action: "importAndSign") }
	private func handoff(action: String) {
		guard let url = sharedURL, ["ipa", "tipa"].contains(url.pathExtension.lowercased()) else { extensionContext?.cancelRequest(withError: CocoaError(.fileReadUnsupportedScheme)); return }
		guard let root = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.sparrow.app")?.appendingPathComponent("PendingImports") else { extensionContext?.cancelRequest(withError: CocoaError(.fileNoSuchFile)); return }
		do {
			try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
			let id = UUID().uuidString, partial = root.appendingPathComponent(".\(id).partial"), job = root.appendingPathComponent(id)
			try FileManager.default.createDirectory(at: partial, withIntermediateDirectories: true)
			try FileManager.default.copyItem(at: url, to: partial.appendingPathComponent(url.lastPathComponent))
			let values = try partial.appendingPathComponent(url.lastPathComponent).resourceValues(forKeys: [.fileSizeKey])
			let json: [String: Any] = ["id": id, "filename": url.lastPathComponent, "createdAt": Date().timeIntervalSince1970, "action": action, "size": values.fileSize ?? 0]
			let data = try JSONSerialization.data(withJSONObject: json)
			try data.write(to: partial.appendingPathComponent("import.json"), options: .atomic)
			try FileManager.default.moveItem(at: partial, to: job)
			try Data("ready".utf8).write(to: job.appendingPathComponent("ready"), options: .atomic)
			extensionContext?.completeRequest(returningItems: nil)
		} catch { extensionContext?.cancelRequest(withError: error) }
	}
}
