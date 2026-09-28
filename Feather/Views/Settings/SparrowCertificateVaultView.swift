import SwiftUI
import LocalAuthentication

struct SparrowCertificateVaultView: View {
	@FetchRequest(entity: CertificatePair.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)]) private var certificates: FetchedResults<CertificatePair>
	@AppStorage("Sparrow.certificateVault.biometricProtection") private var biometricProtection = false
	@ObservedObject private var session = SparrowCertificateVaultSession.shared
	@State private var error: String?
	@State private var deleting: CertificatePair?

	var body: some View {
		Form {
			Section("Certificate Vault") {
				Toggle("Protect vault with Face ID / Touch ID", isOn: $biometricProtection)
				Text("Private keys remain in Sparrow's protected certificate storage. Passwords are stored only in the device Keychain when you choose to remember them.").font(.footnote).foregroundStyle(.secondary)
			}
			Section("Signing Identities") {
				ForEach(certificates, id: \.objectID) { cert in
					VStack(alignment: .leading, spacing: 4) {
						HStack { Text(cert.nickname ?? "Signing Certificate").font(.headline); Spacer(); Image(systemName: "lock.fill").foregroundStyle(.secondary) }
						if let profile = Storage.shared.getProvisionFileDecoded(for: cert) { Text("Team: \(profile.TeamIdentifier.first ?? "Unknown")") }
						Text(cert.expiration.map { "Expires \($0.formatted(date: .abbreviated, time: .omitted))" } ?? "Expiration unknown").font(.footnote).foregroundStyle(.secondary)
						Text("Password: Stored securely").font(.footnote).foregroundStyle(.secondary)
					}
					.swipeActions { Button("Delete", role: .destructive) { deleting = cert } }
				}
				if certificates.isEmpty { Text("No signing identities imported.").foregroundStyle(.secondary) }
			}
			Section { Button(session.isAuthorized && biometricProtection ? "Vault Unlocked" : "Unlock Vault") { unlock() }.disabled(session.isAuthorized && biometricProtection || !biometricProtection); if session.isAuthorized && biometricProtection { Button("Lock Immediately", role: .destructive) { session.lock() } } } footer: { Text(biometricProtection ? "Authentication is required before signing. Sessions expire after one minute and are never persisted across relaunch." : "Enable protection to require device authentication before sensitive signing operations.") }
			if let error { Text(error).foregroundStyle(.red) }
		}
		.navigationTitle("Certificate Vault")
		.confirmationDialog("Remove Signing Identity?", item: $deleting) { cert in Button("Remove", role: .destructive) { Storage.shared.deleteCertificate(for: cert) }; Button("Cancel", role: .cancel) { } } message: { _ in Text("This removes Sparrow's protected copy and its associated Keychain password.") }
	}
	private func unlock() { session.authorize { success, reason in if !success { error = reason ?? "Authentication failed." } } }
}
