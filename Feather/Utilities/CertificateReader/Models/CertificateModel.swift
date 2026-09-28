//
//  Certificate.swift
//  feather
//
//  Created by samara on 5/18/24.
//  Copyright (c) 2024 Samara M (khcrysalis)
//

import Foundation

// MARK: - Certificate (Mobileprovision file)
struct Certificate: Codable {
	var AppIDName: String
	var ApplicationIdentifierPrefix: [String]?
	var CreationDate: Date
	var Platform: [String]
	var IsXcodeManaged: Bool?
	var DeveloperCertificates: [Data]?
	var derEncodedProfile: Data
	var PPQCheck: Bool?
	var Entitlements: [String: AnyCodable]?
	var ExpirationDate: Date
	var Name: String
	var ProvisionsAllDevices: Bool?
	var ProvisionedDevices: [String]?
	var TeamIdentifier: [String]
	var TeamName: String
	var TimeToLive: Int
	var UUID: String
	var Version: Int

	enum CodingKeys: String, CodingKey {
		case AppIDName,
		     CreationDate,
		     Platform,
		     IsXcodeManaged,
		     DeveloperCertificates,
		     PPQCheck,
		     Entitlements,
		     ExpirationDate,
		     Name,
		     ProvisionedDevices,
		     TeamIdentifier,
		     TeamName,
		     TimeToLive,
		     UUID,
		     Version
		case derEncodedProfile = "DER-Encoded-Profile"
	}
}

extension Certificate {
	struct CompatibilityIssue { let entitlement: String; let severity: String; let message: String }
	struct ProfileCompatibilityResult { let compatible: Bool; let issues: [CompatibilityIssue] }
	var applicationIdentifier: String? { Entitlements?["application-identifier"]?.value as? String }
	var isWildcard: Bool { applicationIdentifier?.hasSuffix(".*") == true }
	func compatibility(for bundleIdentifier: String) -> (compatible: Bool, message: String, suggestion: String?) {
		guard !bundleIdentifier.isEmpty else { return (false, "Bundle identifier is empty.", nil) }
		guard let applicationIdentifier else { return (false, "Profile is missing application-identifier.", nil) }
		guard let team = TeamIdentifier.first, !team.isEmpty else { return (false, "Profile is missing TeamIdentifier.", nil) }
		let scope = applicationIdentifier.hasPrefix(team + ".") ? String(applicationIdentifier.dropFirst(team.count + 1)) : applicationIdentifier
		if scope == "*" { return (true, "Wildcard profile accepts this bundle identifier.", nil) }
		if scope == bundleIdentifier { return (true, "Explicit profile matches this bundle identifier.", nil) }
		return (false, "Bundle identifier does not match this profile.", isWildcard ? team + "." + bundleIdentifier : nil)
	}
	func detailedCompatibility(for bundleIdentifier: String, appEntitlements: [String: Any]? = nil) -> ProfileCompatibilityResult {
		var issues: [CompatibilityIssue] = []
		let base = compatibility(for: bundleIdentifier)
		if !base.compatible { issues.append(.init(entitlement: "application-identifier", severity: "error", message: base.message)) }
		if TeamIdentifier.first == nil { issues.append(.init(entitlement: "TeamIdentifier", severity: "error", message: "Profile is missing TeamIdentifier.")) }
		if let appEntitlements, let profileEntitlements = Entitlements {
			for key in ["keychain-access-groups", "com.apple.security.application-groups", "com.apple.developer.associated-domains", "aps-environment", "get-task-allow"] {
				if appEntitlements[key] != nil && profileEntitlements[key] == nil { issues.append(.init(entitlement: key, severity: "warning", message: "This entitlement is present in the app but is not allowed by the selected profile.")) }
			}
		}
		return .init(compatible: !issues.contains { $0.severity == "error" }, issues: issues)
	}
}
