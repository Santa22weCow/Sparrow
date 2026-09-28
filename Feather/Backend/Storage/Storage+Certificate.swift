//
//  Storage+Certificate.swift
//  Feather
//
//  Created by samara on 16.04.2025.
//

import CoreData
import UIKit.UIImpactFeedbackGenerator
import Zsign

// MARK: - Class extension: certificate
extension Storage {
	func addCertificate(
		uuid: String,
		password: String? = nil,
		nickname: String? = nil,
		ppq: Bool = false,
		expiration: Date,
		isDefault: Bool = false,
		completion: @escaping (Error?) -> Void
	) {
		let generator = UIImpactFeedbackGenerator(style: .light)
		
		let new = CertificatePair(context: context)
		new.uuid = uuid
		new.date = Date()
		// New imports keep their password in the device-only Keychain. Existing
		// Core Data passwords are migrated on first use for backwards compatibility.
		new.password = nil
		new.ppQCheck = ppq
		new.expiration = expiration
		new.nickname = nickname
		new.isDefault = isDefault
		if let password {
			do { try CertificatePasswordStore.save(password, certificateID: uuid) }
			catch { context.delete(new); saveContext(); completion(error); return }
		}
		Storage.shared.revokagedCertificate(for: new)
		saveContext()
		generator.impactOccurred()
		completion(nil)
	}
	
	func deleteCertificate(for cert: CertificatePair) {
		if let uuid = cert.uuid { CertificatePasswordStore.delete(certificateID: uuid) }
		if let url = getUuidDirectory(for: cert) {
			try? FileManager.default.removeItem(at: url)
		}
		context.delete(cert)
		saveContext()
	}
	
	func getCertificate(for index: Int) -> CertificatePair? {
		let fetchRequest: NSFetchRequest<CertificatePair> = CertificatePair.fetchRequest()
		fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)]

		guard
			let results = try? context.fetch(fetchRequest),
			index >= 0 && index < results.count
		else {
			return nil
		}
		
		return results[index]
	}
	
	func revokagedCertificate(for cert: CertificatePair) {
		guard !cert.revoked else { return }
		guard let provision = getFile(.provision, from: cert), let p12 = getFile(.certificate, from: cert),
			FileManager.default.isReadableFile(atPath: provision.path), FileManager.default.isReadableFile(atPath: p12.path) else { return }
		let certificateID = cert.objectID
		Zsign.checkRevokage(
			provisionPath: provision.path,
			p12Path: p12.path,
			p12Password: password(for: cert) ?? ""
		) { [weak self] status, _, _ in
			DispatchQueue.main.async {
				guard let self, let object = try? self.context.existingObject(with: certificateID), let certificate = object as? CertificatePair else { return }
				if status == 1 { certificate.revoked = true; self.saveContext() }
			}
		}
	}
	
	enum FileRequest: String {
		case certificate = "p12"
		case provision = "mobileprovision"
	}
	
	func getFile(_ type: FileRequest, from cert: CertificatePair) -> URL? {
		guard let url = getUuidDirectory(for: cert) else {
			return nil
		}
		
		return FileManager.default.getPath(in: url, for: type.rawValue)
	}
	
	func getProvisionFileDecoded(for cert: CertificatePair) -> Certificate? {
		guard let url = getFile(.provision, from: cert) else {
			return nil
		}
		
		let read = CertificateReader(url)
		return read.decoded
	}
	
	func getUuidDirectory(for cert: CertificatePair) -> URL? {
		guard let uuid = cert.uuid else {
			return nil
		}
		
		return FileManager.default.certificates(uuid)
	}

	func password(for cert: CertificatePair) -> String? {
		guard let uuid = cert.uuid else { return cert.password }
		if let password = CertificatePasswordStore.password(certificateID: uuid) { return password }
		// Migrate installations created before passwords were moved to Keychain.
		if let legacy = cert.password {
			do {
				try CertificatePasswordStore.save(legacy, certificateID: uuid)
				cert.password = nil
				saveContext()
			} catch { return legacy }
		}
		return cert.password
	}
	
	func getAllCertificates() -> [CertificatePair] {
		let fetchRequest: NSFetchRequest<CertificatePair> = CertificatePair.fetchRequest()
		fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)]
		return (try? context.fetch(fetchRequest)) ?? []
	}
}
