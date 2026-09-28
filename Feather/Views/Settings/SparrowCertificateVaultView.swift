import SwiftUI
import LocalAuthentication

struct SparrowCertificateVaultView: View {
	@FetchRequest(entity: CertificatePair.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)]) private var certificates: FetchedResults<CertificatePair>
	@AppStorage("Sparrow.certificateVault.biometricProtection") private var biometricProtection = false
	@State private var unlocked = false
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
			Section { Button(unlocked ? "Vault Unlocked" : "Unlock Vault") { unlock() }.disabled(unlocked || !biometricProtection) } footer: { Text(biometricProtection ? "Authentication is required before using remembered certificate passwords." : "Enable protection to require device authentication before sensitive signing operations.") }
			if let error { Text(error).foregroundStyle(.red) }
		}
		.navigationTitle("Certificate Vault")
		.confirmationDialog("Remove Signing Identity?", item: $deleting) { cert in Button("Remove", role: .destructive) { Storage.shared.deleteCertificate(for: cert) }; Button("Cancel", role: .cancel) { } } message: { _ in Text("This removes Sparrow's protected copy and its associated Keychain password.") }
	}
	private func unlock() { let context = LAContext(); var authError: NSError?; guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) else { error = authError?.localizedDescription ?? "Device authentication is unavailable."; return }; context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock Sparrow Certificate Vault") { success, authError in DispatchQueue.main.async { unlocked = success; if !success { error = authError?.localizedDescription ?? "Authentication failed." } } } }
}
