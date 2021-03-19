//
//  RemoteCommentsLoader.swift
//  EssentialFeed
//
//  Created by Tulio Parreiras on 19/03/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteCommentsLoader {
	private let url: URL
	private let client: HTTPClient
	
	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}
	
	public typealias Result = Swift.Result<[FeedImageComment], Swift.Error>
	
	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}
	
	public func load(completion: @escaping (Result) -> Void) {
		client.get(from: url) { [weak self] result in
			guard self != nil else { return }
			switch result {
			case let .success((data, response)):
				let decoder = JSONDecoder()
				decoder.dateDecodingStrategy = .iso8601
				if response.statusCode == 200 {
					do {
						let root = try decoder.decode(Root.self, from: data)
						completion(.success(root.items.map { $0.model }))
					} catch {
						completion(.failure(RemoteCommentsLoader.Error.invalidData))
					}
				} else {
					completion(.failure(RemoteCommentsLoader.Error.invalidData))
				}
			case .failure: completion(.failure(RemoteCommentsLoader.Error.connectivity))
			}
		}
	}
	
	private struct Root: Decodable {
		let items: [RemoteCommentItem]
	}
	
	private struct RemoteCommentItem: Decodable {
		let id: UUID
		let message: String
		let created_at: Date
		let author: RemoteAuthorItem
		
		var model: FeedImageComment {
			FeedImageComment(id: id, message: message, createdAt: created_at, author: CommentAuthor(username: author.username))
		}
	}
	
	private struct RemoteAuthorItem: Decodable {
		let username: String
	}
}
