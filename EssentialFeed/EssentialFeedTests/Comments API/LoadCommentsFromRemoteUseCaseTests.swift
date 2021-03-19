//
//  LoadCommentsFromRemoteUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Tulio Parreiras on 24/02/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest

import EssentialFeed

struct FeedImageComment {
	let id: UUID
	let message: String
	let createdAt: Date
	let author: CommentAuthor
}

struct CommentAuthor {
	let username: String
}

final class RemoteCommentsLoader {
	private let url: URL
	private let client: HTTPClient
	
	enum Error: Swift.Error {
		case connectivity
		case invalidData
	}
	
	init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}
	
	func load(completion: @escaping (Result<[FeedImageComment], Swift.Error>) -> Void) {
		client.get(from: url) { result in
			switch result {
			case let .success(data, response): completion(.failure(RemoteCommentsLoader.Error.invalidData))
			case .failure: completion(.failure(RemoteCommentsLoader.Error.connectivity))
			}
		}
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
		
		let exp = expectation(description: "Wait for load completion")
		let clientError = RemoteCommentsLoader.Error.connectivity
		sut.load { receivedResult in
			switch receivedResult {
			case .success:
				XCTFail("Expected error \(clientError), got success instead")
			case let .failure(receivedError):
				XCTAssertEqual(clientError, receivedError as! RemoteCommentsLoader.Error, "Expected error \(clientError), got \(receivedError) instead")
			}
			exp.fulfill()
		}
		
		client.complete(with: clientError)
		wait(for: [exp], timeout: 1.0)
	}
	
	func test_load_deliversErrorOnNon200HTTPResponse() {
		let (sut, client) = makeSUT()
		
		let exp = expectation(description: "Wait for load completion")
		let clientError = RemoteCommentsLoader.Error.invalidData
		sut.load { receivedResult in
			switch receivedResult {
			case .success:
				XCTFail("Expected error \(clientError), got success instead")
			case let .failure(receivedError):
				XCTAssertEqual(clientError, receivedError as! RemoteCommentsLoader.Error, "Expected error \(clientError), got \(receivedError) instead")
			}
			exp.fulfill()
		}
		
		let json = makeItemsJSON([])
		client.complete(withStatusCode: 201, data: json)
		wait(for: [exp], timeout: 1.0)
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

}
