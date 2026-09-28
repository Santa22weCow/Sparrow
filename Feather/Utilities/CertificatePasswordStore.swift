import Foundation
import Security

enum CertificatePasswordStore {
	private static let service = "thewonderofyou.Feather.certificate-password"

	static func save(_ password: String, certificateID: String) throws {
		let account = certificateID.data(using: .utf8)!
		let value = password.data(using: .utf8)!
		let query: [CFString: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: account]
		let attributes: [CFString: Any] = [kSecValueData: value, kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
		let update = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
		if update == errSecItemNotFound {
			var add = query
			attributes.forEach { add[$0.key] = $0.value }
			let status = SecItemAdd(add as CFDictionary, nil)
			guard status == errSecSuccess else { throw KeychainError(status: status) }
		} else if update != errSecSuccess {
			throw KeychainError(status: update)
		}
	}

	static func password(certificateID: String) -> String? {
		let query: [CFString: Any] = [
			kSecClass: kSecClassGenericPassword,
			kSecAttrService: service,
			kSecAttrAccount: certificateID.data(using: .utf8)!,
			kSecReturnData: true,
			kSecMatchLimit: kSecMatchLimitOne,
		]
		var result: CFTypeRef?
		guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
			let data = result as? Data else { return nil }
		return String(data: data, encoding: .utf8)
	}

	static func delete(certificateID: String) {
		SecItemDelete([kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: certificateID.data(using: .utf8)!] as CFDictionary)
	}
}

private struct KeychainError: LocalizedError {
	let status: OSStatus
	var errorDescription: String? { "Unable to store certificate password in the Keychain (OSStatus \(status))." }
}
