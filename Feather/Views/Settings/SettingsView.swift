//
//  SettingsView.swift
//  Feather
//
//  Created by samara on 10.04.2025.
//

import SwiftUI
import NimbleViews
import UIKit
import Darwin
import IDeviceSwift

// MARK: - View
struct SettingsView: View {
	@AppStorage("feather.selectedCert") private var _storedSelectedCert: Int = 0
	@State private var _currentIcon: String? = UIApplication.shared.alternateIconName
	
	// MARK: Fetch
	@FetchRequest(
		entity: CertificatePair.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
		animation: .snappy
	) private var _certificates: FetchedResults<CertificatePair>
	
	private var selectedCertificate: CertificatePair? {
		guard
			_storedSelectedCert >= 0,
			_storedSelectedCert < _certificates.count
		else {
			return nil
		}
		return _certificates[_storedSelectedCert]
	}

    
	private let _donationsUrl = "https://github.com/sponsors/claration"
	private let _githubUrl = "https://github.com/valentinobomba10-afk/Sparrow"
    
	// MARK: Body
	var body: some View {
		NBNavigationView(.localized("Settings")) {
			Form {
				Section { NavigationLink(destination: SparrowDashboardView()) { Label("Sparrow Dashboard", systemImage: "rectangle.3.group") } }
				#if !NIGHTLY && !DEBUG
					SettingsDonationCellView(site: _donationsUrl)
				#endif
                
				_feedback()
                
				Section {
					NavigationLink(destination: AppearanceView()) {
						Label(.localized("Appearance"), systemImage: "paintbrush")
					}
					NavigationLink(destination: AppIconView(currentIcon: $_currentIcon)) {
						Label(.localized("App Icon"), systemImage: "app.badge")
					}
				}
                
				NBSection(.localized("Certificates")) {
                    
					if let cert = selectedCertificate {
						CertificatesCellView(cert: cert)
					} else {
						Text(.localized("No Certificate"))
							.font(.footnote)
							.foregroundColor(.disabled())
					}
					NavigationLink(destination: CertificatesView()) {
						Label(.localized("Certificates"), systemImage: "checkmark.seal")
					}
                 
				} footer: {
					Text(.localized("Add and manage certificates used for signing applications."))
				}
                
				NBSection(.localized("Features")) {
					NavigationLink(destination: SparrowSigningPresetsView()) { Label("Signing Presets", systemImage: "square.stack.3d.up") }
					NavigationLink(destination: SparrowDiagnosticsView()) { Label("Diagnostics & Activity", systemImage: "stethoscope") }
					NavigationLink(destination: SparrowUpdatesView()) {
						Label("Sparrow Updates", systemImage: "arrow.down.circle")
					}
					NavigationLink(destination: ConfigurationView()) {
						Label(.localized("Signing Options"), systemImage: "signature")
					}
					NavigationLink(destination: ArchiveView()) {
						Label(.localized("Archive & Compression"), systemImage: "archivebox")
					}
					NavigationLink(destination: InstallationView()) {
						Label(.localized("Installation"), systemImage: "arrow.down.circle")
					}
					NavigationLink(destination: InstallDiagnosticsView()) {
						Label("Install Diagnostics", systemImage: "stethoscope")
					}
					NavigationLink(destination: ArchiveManagerView()) {
						Label("App Archive", systemImage: "archivebox")
					}
				} footer: {
					Text(.localized("Configure the apps way of installing, its zip compression levels, and custom modifications to apps."))
				}
                
				_directories()
                
				Section {
					NavigationLink(destination: ResetView()) {
						Label(.localized("Reset"), systemImage: "trash")
					}
				} footer: {
					Text(.localized("Reset the applications sources, certificates, apps, and general contents."))
				}
			}
		}
	}
}

@MainActor
final class SparrowUpdateManager: ObservableObject {
	static let shared = SparrowUpdateManager()
	@Published private(set) var release: Release?
	@Published private(set) var isChecking = false
	@Published private(set) var errorMessage: String?
	@Published private(set) var lastChecked: Date?
	private let endpoint = URL(string: "https://api.github.com/repos/valentinobomba10-afk/Sparrow/releases")!
	private init() {}

	struct Release: Codable, Identifiable {
		let id: Int
		let tagName: String
		let name: String
		let body: String?
		let htmlURL: URL
		let publishedAt: Date?
		let prerelease: Bool
		let assets: [Asset]
		var version: String { tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV")) }
		struct Asset: Codable { let name: String; let browserDownloadURL: URL; enum CodingKeys: String, CodingKey { case name; case browserDownloadURL = "browser_download_url" } }
		enum CodingKeys: String, CodingKey { case id; case tagName = "tag_name"; case name; case body; case htmlURL = "html_url"; case publishedAt = "published_at"; case prerelease; case assets }
	}

	func check(force: Bool = false) async {
		guard !isChecking else { return }
		let cached = UserDefaults.standard.object(forKey: "Sparrow.lastUpdateCheck") as? Date
		if !force, let cached, Date().timeIntervalSince(cached) < 86400 { lastChecked = cached; return }
		isChecking = true; errorMessage = nil
		defer { isChecking = false }
		var request = URLRequest(url: endpoint); request.setValue("Sparrow/1.0", forHTTPHeaderField: "User-Agent")
		do {
			let (data, response) = try await URLSession.shared.data(for: request)
			guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
			let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
			let beta = UserDefaults.standard.bool(forKey: "Sparrow.updateChannelBeta")
			let releases = try decoder.decode([Release].self, from: data).filter { beta || !$0.prerelease }
			release = releases.max { $0.version.compare($1.version, options: .numeric) == .orderedAscending }
			lastChecked = Date(); UserDefaults.standard.set(lastChecked, forKey: "Sparrow.lastUpdateCheck")
		} catch { lastChecked = cached; errorMessage = cached == nil ? "Unable to check Sparrow updates: \(error.localizedDescription)" : "Sparrow is offline. Showing the last available result." }
	}
}

struct SparrowUpdatesView: View {
	@StateObject private var manager = SparrowUpdateManager.shared
	@AppStorage("Sparrow.updateChannelBeta") private var betaChannel = false
	@AppStorage("Sparrow.autoUpdateChecks") private var automaticChecks = true
	private var current: String { Bundle.main.version }
	var body: some View {
		Form {
			Section("Sparrow Updates") {
				Picker("Update Channel", selection: $betaChannel) { Text("Stable").tag(false); Text("Beta").tag(true) }.pickerStyle(.segmented)
				Toggle("Automatically Check for Sparrow Updates", isOn: $automaticChecks)
				LabeledContent("Installed", value: current)
				if let release = manager.release {
					LabeledContent("Latest", value: release.version)
					if release.version.compare(current, options: .numeric) == .orderedDescending {
						Link("View Update", destination: release.htmlURL)
						if let ipa = release.assets.first(where: { $0.name.lowercased().hasSuffix(".ipa") }) { Link("Download IPA", destination: ipa.browserDownloadURL) }
					} else { Label("Sparrow is up to date", systemImage: "checkmark.circle.fill").foregroundStyle(.green) }
				}
				if let error = manager.errorMessage { Text(error).foregroundStyle(.red) }
				if let last = manager.lastChecked { Text("Last checked: \(last.formatted(date: .abbreviated, time: .shortened))").font(.footnote).foregroundStyle(.secondary) }
				Button("Check for Updates") { Task { await manager.check(force: true) } }.disabled(manager.isChecking)
			}
		}
		.navigationTitle("Sparrow Updates")
		.task { if automaticChecks { await manager.check() } }
	}
}

// MARK: - View extension
extension SettingsView {
	@ViewBuilder
	private func _feedback() -> some View {
		Section {
			NavigationLink(destination: AboutView()) {
				Label {
					Text(verbatim: .localized("About %@", arguments: Bundle.main.name))
				} icon: {
					FRAppIconView(size: 23)
				}
			}
            
			Button(.localized("Submit Feedback"), systemImage: "safari") {
				UIApplication.open(URL(string: "\(_githubUrl)/issues/new/choose")!)
			}
			Button(.localized("GitHub Repository"), systemImage: "safari") {
				UIApplication.open(_githubUrl)
			}
		} footer: {
			Text(.localized("If any issues occur within the app please report it via the GitHub repository. When submitting an issue, make sure to submit detailed information."))
		}
	}
    
	@ViewBuilder
	private func _directories() -> some View {
		NBSection(.localized("Misc")) {
			Button(.localized("Open Documents"), systemImage: "folder") {
				UIApplication.open(URL.documentsDirectory.toSharedDocumentsURL()!)
			}
			Button(.localized("Open Archives"), systemImage: "folder") {
				UIApplication.open(FileManager.default.archives.toSharedDocumentsURL()!)
			}
			Button(.localized("Open Certificates"), systemImage: "folder") {
				UIApplication.open(FileManager.default.certificates.toSharedDocumentsURL()!)
			}
		} footer: {
			Text(.localized("All of the apps files are contained in the documents directory, here are some quick links to these."))
		}
	}
}
