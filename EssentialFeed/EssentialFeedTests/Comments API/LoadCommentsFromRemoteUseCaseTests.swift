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
		
		expect(sut, toCompleteWith: .failure(RemoteCommentsLoader.Error.connectivity), when: {
			let clientError = NSError(domain: "Test", code: 0)
			client.complete(with: clientError)
		})
	}
	
	func test_load_deliversErrorOnNon200HTTPResponse() {
		let (sut, client) = makeSUT()
		
		expect(sut, toCompleteWith: .failure(RemoteCommentsLoader.Error.invalidData), when: {
			let json = makeItemsJSON([])
			client.complete(withStatusCode: 201, data: json)
		})
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
	
	private func expect(_ sut: RemoteCommentsLoader, toCompleteWith expectedResult: RemoteCommentsLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
		let exp = expectation(description: "Wait for load completion")
		
		sut.load { receivedResult in
			switch (receivedResult, expectedResult) {
			case let (.success(receivedItems), .success(expectedItems)):
				XCTAssertEqual(receivedItems, expectedItems, "Expected items \(expectedItems), got \(receivedItems) instead", file: file, line: line)
			case let (.failure(receivedError as RemoteCommentsLoader.Error), .failure(expectedError as RemoteCommentsLoader.Error)):
				XCTAssertEqual(receivedError, expectedError, "Expected error \(expectedError), got \(receivedError) instead", file: file, line: line)
			default:
				XCTFail("Expected result \(expectedResult) got \(receivedResult) instead", file: file, line: line)
			}
			exp.fulfill()
		}
		
		action()
		wait(for: [exp], timeout: 1.0)
	}

}
