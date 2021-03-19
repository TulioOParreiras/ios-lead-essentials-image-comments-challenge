//
//  RemoteCommentsMapper.swift
//  EssentialFeed
//
//  Created by Tulio Parreiras on 19/03/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation

final class RemoteCommentsMapper {
	private init() { }
	
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
	
	static func map(data: Data, response: HTTPURLResponse) throws -> [FeedImageComment] {
		guard response.statusCode == 200 else { throw RemoteCommentsLoader.Error.invalidData }
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		guard let root = try? decoder.decode(Root.self, from: data) else { throw RemoteCommentsLoader.Error.invalidData }
		return root.items.map { $0.model }
	}
}
