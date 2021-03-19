//
//  CommentAuthor.swift
//  EssentialFeed
//
//  Created by Tulio Parreiras on 19/03/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation

public struct CommentAuthor: Hashable {
	public let username: String
	
	public init(username: String) {
		self.username = username
	}
}
