//
//  IPAHandler.swift
//  Feather
//
//  Created by samara on 11.04.2025.
//

import Foundation
import Zip
import SwiftUI

final class AppFileHandler: NSObject, @unchecked Sendable {
	private let _fileManager = FileManager.default
	private let _uuid = UUID().uuidString
	private let _uniqueWorkDir: URL
	var uniqueWorkDirPayload: URL?
	var progressHandler: ((Double) -> Void)?

	private var _ipa: URL
	private let _install: Bool
	private let _download: Download?
	private let _sourceProvenance: SourceAppProvenance?
	
	init(
		file ipa: URL,
		install: Bool = false,
		download: Download? = nil,
		sourceProvenance: SourceAppProvenance? = nil
	) {
		self._ipa = ipa
		self._install = install
		self._download = download
		self._sourceProvenance = sourceProvenance ?? download?.sourceProvenance
		self._uniqueWorkDir = _fileManager.temporaryDirectory
			.appendingPathComponent("FeatherImport_\(_uuid)", isDirectory: true)
		
		super.init()
	}
	
	func copy() async throws {
		try _fileManager.createDirectoryIfNeeded(at: _uniqueWorkDir)
		
		let destinationURL = _uniqueWorkDir.appendingPathComponent(_ipa.lastPathComponent)

		try _fileManager.removeFileIfNeeded(at: destinationURL)
		
		let attributes = try _fileManager.attributesOfItem(atPath: _ipa.path)
		let expected = (attributes[.size] as? NSNumber)?.int64Value ?? 0
		guard expected > 0 else { throw ImportedFileHandlerError.invalidFile }
		guard (try? _fileManager.attributesOfFileSystem(forPath: _uniqueWorkDir.path)[.systemFreeSize] as? NSNumber)?.int64Value ?? 0 > expected else { throw ImportedFileHandlerError.insufficientStorage }
		try _fileManager.removeFileIfNeeded(at: destinationURL)
		FileManager.default.createFile(atPath: destinationURL.path, contents: nil)
		let input = try FileHandle(forReadingFrom: _ipa)
		let output = try FileHandle(forWritingTo: destinationURL)
		defer { try? input.close(); try? output.close() }
		var copied: Int64 = 0
		while true {
			try Task.checkCancellation()
			let chunk = try input.read(upToCount: 4 * 1024 * 1024) ?? Data()
			if chunk.isEmpty { break }
			try output.write(contentsOf: chunk)
			copied += Int64(chunk.count)
			let progress = min(1, Double(copied) / Double(expected))
			progressHandler?(progress)
			if let download = _download { DispatchQueue.main.async { download.progress = progress; download.bytesDownloaded = copied; download.totalBytes = expected } }
		}
		guard copied == expected else { throw ImportedFileHandlerError.invalidFile }
		_ipa = destinationURL
	}
	
	func extract() async throws {
		if _ipa.pathExtension == "ipa" {
			Zip.addCustomFileExtension("ipa")
		}
		if _ipa.pathExtension == "tipa" {
			Zip.addCustomFileExtension("tipa")
		}
		
		let download = self._download
		
		try await withCheckedThrowingContinuation { continuation in
			DispatchQueue.global(qos: .utility).async {
				do {
					try Zip.unzipFile(
						self._ipa,
						destination: self._uniqueWorkDir,
						overwrite: true,
						password: nil,
						progress: { progress in
							if let download = download {
								DispatchQueue.main.async {
									download.unpackageProgress = progress
									
									#if !targetEnvironment(macCatalyst)
									if #available(iOS 26.0, *) {
										BackgroundTaskManager.shared.updateProgress(for: download.id, progress: download.overallProgress)
									}
									#endif
								}
							}
						}
					)
					
					self.uniqueWorkDirPayload = self._uniqueWorkDir.appendingPathComponent("Payload")
					continuation.resume()
				} catch {
					continuation.resume(throwing: error)
				}
			}
		}
	}
	
	func move() async throws {
		guard let payloadURL = uniqueWorkDirPayload else {
			throw ImportedFileHandlerError.payloadNotFound
		}
		
		let destinationURL = try await _directory()
		
		guard _fileManager.fileExists(atPath: payloadURL.path) else {
			throw ImportedFileHandlerError.payloadNotFound
		}
		
		try _fileManager.moveItem(at: payloadURL, to: destinationURL)
		
		try? _fileManager.removeItem(at: _uniqueWorkDir)
	}
	
	func addToDatabase() async throws {
		let app = try await _directory()
		
		guard let appUrl = _fileManager.getPath(in: app, for: "app") else {
			return
		}
		
		let bundle = Bundle(url: appUrl)
		
		Storage.shared.addImported(
			uuid: _uuid,
			source: _sourceProvenance?.sourceRepositoryURL,
			appName: bundle?.name,
			appIdentifier: bundle?.bundleIdentifier,
			appVersion: bundle?.version,
			appIcon: bundle?.iconFileName
		) { _ in }
		
		if let sourceProvenance = _sourceProvenance {
			Storage.shared.addSourceMetadata(
				for: _uuid,
				kind: .imported,
				provenance: sourceProvenance
			)
		}
	}
	
	private func _directory() async throws -> URL {
		// Documents/Feather/Unsigned/\(UUID)
		_fileManager.unsigned(_uuid)
	}
	
	func clean() async throws {
		try _fileManager.removeFileIfNeeded(at: _uniqueWorkDir)
	}
}

private enum ImportedFileHandlerError: Error {
	case payloadNotFound
	case invalidFile
	case insufficientStorage
}
