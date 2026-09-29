import Foundation
import UIKit
import IDeviceSwift

enum SparrowSignedIPAExporter {
	static func export(_ app: AppInfoPresentable) {
		guard app.isSigned, Storage.shared.getAppDirectory(for: app) != nil else {
			UIAlertController.showAlertWithOk(title: "Export Failed", message: "Only a signed app with an available app bundle can be exported.")
			return
		}
		let viewModel = InstallerStatusViewModel(isIdevice: false)
		Task {
			do {
				let handler = ArchiveHandler(app: app, viewModel: viewModel)
				try await handler.move()
				let archive = try await handler.archive()
				guard FileManager.default.fileExists(atPath: archive.path), (try archive.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) > 0 else { throw CocoaError(.fileReadNoSuchFile) }
				let saved = try await handler.moveToArchive(archive)
				guard let saved else { throw CocoaError(.fileWriteUnknown) }
				await MainActor.run { UIActivityViewController.show(activityItems: [saved]) }
			} catch {
				await MainActor.run { UIAlertController.showAlertWithOk(title: "Export Failed", message: error.localizedDescription) }
			}
		}
	}
}
