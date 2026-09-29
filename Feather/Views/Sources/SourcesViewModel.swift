//
//  SourcesViewModel.swift
//  Feather
//
//  Created by samara on 30.04.2025.
//

import Foundation
import AltSourceKit
import SwiftUI
import NimbleJSON

// MARK: - Class
@MainActor
final class SourcesViewModel: ObservableObject {
	static let shared = SourcesViewModel()
	
	typealias RepositoryDataHandler = Result<ASRepository, Error>
	
	@Published var isFinished = true
	@Published var sources: [AltSource: ASRepository] = [:]
	
	func fetchSources(_ sources: FetchedResults<AltSource>, refresh: Bool = false, batchSize: Int = 4) async {
		guard isFinished else { return }
		
		// check if sources to be fetched are the same as before, if yes, return
		// also skip check if refresh is true
		if !refresh, sources.allSatisfy({ self.sources[$0] != nil }) { return }
		
		// isfinished is used to prevent multiple fetches at the same time
		isFinished = false
		defer { isFinished = true }
		
		let sourcesArray = Array(sources)
		let sourceURLs = sourcesArray.compactMap { source -> (URL, String)? in
			guard let url = source.sourceURL else { return nil }
			return (url, source.identifier ?? url.absoluteString)
		}
		// Show the last successful catalog immediately; fresh network data replaces
		// it as each repository returns.
		let cached = await withTaskGroup(of: (URL, ASRepository?).self, returning: [(URL, ASRepository)].self) { group in
			for (url, _) in sourceURLs {
				group.addTask { (url, await RepositoryCache.repositoryAsync(for: url)) }
			}
			var values = [(URL, ASRepository)]()
			for await (url, repository) in group { if let repository { values.append((url, repository)) } }
			return values
		}
		for (url, repository) in cached {
			if let source = sourcesArray.first(where: { $0.sourceURL == url }) { self.sources[source] = repository }
		}
		
		for startIndex in stride(from: 0, to: sourceURLs.count, by: batchSize) {
			if Task.isCancelled { return }
			let endIndex = min(startIndex + batchSize, sourcesArray.count)
			let batch = sourceURLs[startIndex..<min(endIndex, sourceURLs.count)]
			
			let batchResults = await withTaskGroup(of: (URL, ASRepository?).self, returning: [(URL, ASRepository)].self) { group in
				for (url, _) in batch {
					group.addTask {
						do {
							var request = URLRequest(url: url)
							request.timeoutInterval = 15
							let (data, response) = try await URLSession.shared.data(for: request)
							guard (response as? HTTPURLResponse)?.statusCode == 200 else { return (url, nil) }
							let repo = try JSONDecoder().decode(ASRepository.self, from: data)
							RepositoryCache.save(data, for: url)
							return (url, repo)
						} catch { return (url, nil) }
					}
				}
				
				var results = [(URL, ASRepository)]()
				for await (url, repo) in group { if let repo { results.append((url, repo)) } }
				return results
			}
			
			await MainActor.run {
				for (url, repo) in batchResults {
					if let source = sourcesArray.first(where: { $0.sourceURL == url }) { self.sources[source] = repo }
				}
			}
		}
	}
}
