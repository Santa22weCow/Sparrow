//
//  Server.swift
//  feather
//
//  Created by samara on 22.08.2024.
//  Copyright © 2024 Lakr Aream. All Rights Reserved.
//  ORIGINALLY LICENSED UNDER GPL-3.0, MODIFIED FOR USE FOR FEATHER
//

import Foundation
import Vapor
import NIOSSL
import NIOTLS
import SwiftUI
import IDeviceSwift
import OSLog

enum ServerInstallError: LocalizedError {
	case missingPackage
	case missingTLSCredentials
	case listenerDidNotStart(String)
	case listenerUnreachable(URL, String)
	case manifestProviderUnavailable(URL, String)

	var errorDescription: String? {
		switch self {
		case .missingPackage:
			return "The signed IPA is no longer available for installation."
		case .missingTLSCredentials:
			return "Fully Local requires a currently valid, trusted TLS certificate. The configured certificate could not be loaded."
		case let .listenerDidNotStart(reason):
			return "The local install server could not start: \(reason)"
		case let .listenerUnreachable(url, reason):
			return "The local install server could not be reached at \(url.absoluteString): \(reason)"
		case let .manifestProviderUnavailable(url, reason):
			return "The Semi Local manifest service is unavailable at \(url.host ?? url.absoluteString): \(reason)"
		}
	}
}

// MARK: - Class
class ServerInstaller: Identifiable, ObservableObject {
	let id = UUID()
	let port = Int.random(in: 4000...8000)
	private var _needsShutdown = false
	private let _serverMethod: Int
	private var _setupError: Error?
	
	var packageUrl: URL?
	var app: AppInfoPresentable
	@ObservedObject var viewModel: InstallerStatusViewModel
	private var _server: Application?

	init(app: AppInfoPresentable, viewModel: InstallerStatusViewModel) {
		self.app = app
		self.viewModel = viewModel
		self._serverMethod = UserDefaults.standard.integer(forKey: "Feather.serverMethod")
		do {
			try _setup()
			try _configureRoutes()
		} catch {
			_setupError = error
			Logger.misc.error("Install server configuration failed: \(error.localizedDescription)")
		}
	}
	
	deinit {
		_shutdownServer()
	}
	
	private func _setup() throws {
		self._server = try setupApp(port: port)
	}
		
	private func _configureRoutes() throws {
		_server?.get("*") { [weak self] req in
			guard let self else { return Response(status: .badGateway) }
			switch req.url.path {
			case "/health":
				return Response(status: .noContent)
			case plistEndpoint.path:
				self._updateStatus(.sendingManifest)
				return Response(status: .ok, version: req.version, headers: [
					"Content-Type": "text/xml",
				], body: .init(data: installManifestData))
			case displayImageSmallEndpoint.path:
				return Response(status: .ok, version: req.version, headers: [
					"Content-Type": "image/png",
				], body: .init(data: displayImageSmallData))
			case displayImageLargeEndpoint.path:
				return Response(status: .ok, version: req.version, headers: [
					"Content-Type": "image/png",
				], body: .init(data: displayImageLargeData))
			case payloadEndpoint.path:
				guard let packageUrl = packageUrl else {
					return Response(status: .notFound)
				}
				
				self._updateStatus(.sendingPayload)
				
				var response = req.fileio.streamFile(
					at: packageUrl.path
				) { result in
					switch result {
					case .success:
						self._updateStatus(.installing)
					case .failure(let error):
						self._updateStatus(.broken(error))
					}

				}
				response.headers.replaceOrAdd(name: .contentType, value: "application/octet-stream")
				return response
			case "/install":
				var headers = HTTPHeaders()
				headers.add(name: .contentType, value: "text/html")
				return Response(status: .ok, headers: headers, body: .init(string: self.html))
			default:
				return Response(status: .notFound)
			}
		}
	}

	/// Starts only after the signed IPA exists, then proves that the process can
	/// reach the listener before iOS/Safari is asked to download anything.
	func prepareForInstall(packageURL: URL) async throws {
		if let _setupError { throw _setupError }
		guard FileManager.default.isReadableFile(atPath: packageURL.path) else {
			throw ServerInstallError.missingPackage
		}

		packageUrl = packageURL
		do {
			try _server?.server.start()
			_needsShutdown = true
		} catch {
			Logger.misc.error("Install server failed to bind port \(self.port): \(error.localizedDescription)")
			throw ServerInstallError.listenerDidNotStart(error.localizedDescription)
		}

		Logger.misc.info("Install server listening on loopback port \(self.port), mode \(self._serverMethod)")
		try await _verifyLocalServer()
		if _serverMethod == 1 {
			try await _verifyManifestProvider()
		}
	}

	func deleteSignedPackageIfEnabled() {
		guard UserDefaults.standard.bool(forKey: "Feather.deleteSignedIPAAfterInstall"),
			let packageUrl, packageUrl.pathExtension.lowercased() == "ipa" else { return }
		do {
			try FileManager.default.removeItem(at: packageUrl)
			Logger.misc.info("Deleted signed IPA after confirmed installation")
		} catch {
			Logger.misc.error("Could not delete signed IPA after installation: \(error.localizedDescription)")
		}
	}

	private func _verifyLocalServer() async throws {
		let endpoint = healthEndpoint
		var request = URLRequest(url: endpoint)
		request.timeoutInterval = 10
		do {
			let (_, response) = try await URLSession.shared.data(for: request)
			guard (response as? HTTPURLResponse)?.statusCode == 204 else {
				throw ServerInstallError.listenerUnreachable(endpoint, "health check returned an unexpected response")
			}
			Logger.misc.info("Install server health check succeeded: \(endpoint.absoluteString)")
		} catch let error as ServerInstallError {
			throw error
		} catch {
			Logger.misc.error("Install server health check failed: \(error.localizedDescription)")
			throw ServerInstallError.listenerUnreachable(endpoint, error.localizedDescription)
		}
	}

	private func _verifyManifestProvider() async throws {
		let endpoint = externalManifestEndpoint
		var request = URLRequest(url: endpoint)
		request.timeoutInterval = 10
		do {
			let (_, response) = try await URLSession.shared.data(for: request)
			guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
				throw ServerInstallError.manifestProviderUnavailable(endpoint, "HTTP \((response as? HTTPURLResponse)?.statusCode ?? -1)")
			}
			Logger.misc.info("Semi Local manifest provider is reachable: \(endpoint.host ?? "unknown")")
		} catch let error as ServerInstallError {
			throw error
		} catch {
			Logger.misc.error("Semi Local manifest provider check failed: \(error.localizedDescription)")
			throw ServerInstallError.manifestProviderUnavailable(endpoint, error.localizedDescription)
		}
	}
	
	private func _shutdownServer() {
		guard _needsShutdown else { return }
		
		_needsShutdown = false
		_server?.server.shutdown()
		_server?.shutdown()
	}
	
	private func _updateStatus(_ newStatus: InstallerStatusViewModel.InstallerStatus) {
		DispatchQueue.main.async {
			self.viewModel.status = newStatus
		}
	}
		
	func getServerMethod() -> Int {
		_serverMethod
	}
	
	func getIPFix() -> Bool {
		UserDefaults.standard.bool(forKey: "Feather.ipFix")
	}
}
