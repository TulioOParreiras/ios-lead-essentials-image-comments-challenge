//
//  LoadCommentsFromRemoteUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Tulio Parreiras on 24/02/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest

import EssentialFeed

struct FeedImageComment: Hashable {
	let id: UUID
	let message: String
	let createdAt: Date
	let author: CommentAuthor
}

struct CommentAuthor: Hashable {
	let username: String
}

final class RemoteCommentsLoader {
	private let url: URL
	private let client: HTTPClient
	
	enum Error: Swift.Error {
		case connectivity
		case invalidData
	}
	
	typealias Result = Swift.Result<[FeedImageComment], Swift.Error>
	
	init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}
	
	func load(completion: @escaping (Result) -> Void) {
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

class LoadCommentsFromRemoteUseCaseTests: XCTestCase {
	
	func test_init_doesNotRequestDataFromURL() {
		let (_, client) = makeSUT()
		
		XCTAssertTrue(client.requestedURLs.isEmpty)
	}
	
	func test_load_requestsDataFromURL() {
		let url = URL(string: "https://a-given-url.com")!
		let (sut, client) = makeSUT(url: url)
		
		sut.load { _ in }
		
		XCTAssertEqual(client.requestedURLs, [url])
	}
	
	func test_loadTwice_requestsDataFromURLTwice() {
		let url = URL(string: "https://a-given-url.com")!
		let (sut, client) = makeSUT(url: url)
		
		sut.load { _ in }
		sut.load { _ in }
		
		XCTAssertEqual(client.requestedURLs, [url, url])
	}
	
	func test_load_deliversErrorOnClientError() {
		let (sut, client) = makeSUT()
		
		expect(sut, toCompleteWith: .failure(RemoteCommentsLoader.Error.connectivity), when: {
			let clientError = NSError(domain: "Test", code: 0)
			client.complete(with: clientError)
		})
	}
	
	func test_load_deliversErrorOnNon200HTTPResponse() {
		let (sut, client) = makeSUT()
		
		let statusCodes = [199, 201, 300, 400, 500]
		
		statusCodes.enumerated().forEach { index, statusCode in
			expect(sut, toCompleteWith: .failure(RemoteCommentsLoader.Error.invalidData), when: {
				let json = makeItemsJSON([])
				client.complete(withStatusCode: statusCode, data: json, at: index)
			})
		}
	}
	
	func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
		let (sut, client) = makeSUT()
		
		expect(sut, toCompleteWith: .failure(RemoteCommentsLoader.Error.invalidData), when: {
			let invalidData = Data("invalid data".utf8)
			client.complete(withStatusCode: 200, data: invalidData)
		})
	}
	
	func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
		let (sut, client) = makeSUT()
		
		expect(sut, toCompleteWith: .success([]), when: {
			let json = makeItemsJSON([])
			client.complete(withStatusCode: 200, data: json)
		})
	}
	
	func test_load_deliversItemsOn200HTTPResponseWithJSONItems() {
		let (sut, client) = makeSUT()
		
		let item1 = makeItem(
			id: UUID(),
			message: "a message",
			createdAt: (Date(timeIntervalSince1970: 1598627222), "2020-08-28T15:07:02+00:00"),
			author_name: "a username"
		)
		let item2 = makeItem(
			id: UUID(),
			message: "another name",
			createdAt: (Date(timeIntervalSince1970: 1577881882), "2020-01-01T12:31:22+00:00"),
			author_name: "another username"
		)
		
		let items = [item1.model, item2.model]
		expect(sut, toCompleteWith: .success(items), when: {
			let json = makeItemsJSON([item1.json, item2.json])
			client.complete(withStatusCode: 200, data: json)
		})
	}
	
	func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
		let client = HTTPClientSpy()
		let url = URL(string: "https://any-url.com")!
		var sut: RemoteCommentsLoader? = RemoteCommentsLoader(url: url, client: client)
		
		var expectedResult: RemoteCommentsLoader.Result?
		sut?.load { expectedResult = $0 }
		
		sut = nil
		client.complete(withStatusCode: 200, data: makeItemsJSON([]))
		XCTAssertNil(expectedResult)
	}
	
	// MARK: - Helpers
	
	private func makeSUT(url: URL = URL(string: "https://any-url.com")!) -> (sut: RemoteCommentsLoader, client: HTTPClientSpy) {
		let client = HTTPClientSpy()
		let sut = RemoteCommentsLoader(url: url, client: client)
		
		return (sut, client)
	}
	
	private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
		let json = ["items": items]
		return try! JSONSerialization.data(withJSONObject: json)
	}
	
	private func makeItem(id: UUID, message: String, createdAt: (date: Date, iso8601String: String), author_name: String) -> (model: FeedImageComment, json: [String: Any]) {
		let item = FeedImageComment(id: id, message: message, createdAt: createdAt.date, author: CommentAuthor(username: author_name))
		
		let json: [String: Any] = [
			"id": id.uuidString,
			"message": message,
			"created_at": createdAt.iso8601String,
			"author": [
				"username": author_name
			]
		]
		
		return (item, json)
	}
	
	private func expect(_ sut: RemoteCommentsLoader, toCompleteWith expectedResult: RemoteCommentsLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
		let exp = expectation(description: "Wait for load completion")
		
		sut.load { receivedResult in
			switch (receivedResult, expectedResult) {
			case let (.success(receivedItems), .success(expectedItems)):
				XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
			case let (.failure(receivedError as RemoteCommentsLoader.Error), .failure(expectedError as RemoteCommentsLoader.Error)):
				XCTAssertEqual(receivedError, expectedError, file: file, line: line)
			default:
				XCTFail("Expected result \(expectedResult) got \(receivedResult) instead", file: file, line: line)
			}
			exp.fulfill()
		}
		
		action()
		wait(for: [exp], timeout: 1.0)
	}
	
}
