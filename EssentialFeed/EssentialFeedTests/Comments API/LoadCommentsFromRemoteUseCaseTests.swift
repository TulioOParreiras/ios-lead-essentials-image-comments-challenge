//
//  LoadCommentsFromRemoteUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Tulio Parreiras on 24/02/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest

final class RemoteCommentsLoader {
	
}

class LoadCommentsFromRemoteUseCaseTests: XCTestCase {
	
	func test_init_doesNotRequestDataFromURL() {
		let (_, client) = makeSUT()
		
		XCTAssertTrue(client.requestedURLs.isEmpty)
	}
	
	private func makeSUT() -> (sut: RemoteCommentsLoader, client: HTTPClientSpy) {
		let sut = RemoteCommentsLoader()
		let client = HTTPClientSpy()
		
		return (sut, client)
	}

}
