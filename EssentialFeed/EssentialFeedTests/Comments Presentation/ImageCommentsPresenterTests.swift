//
//  ImageCommentsPresenterTests.swift
//  EssentialFeedTests
//
//  Created by Tulio Parreiras on 21/03/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest

import EssentialFeed

protocol ImageCommentsErrorView {
	func display(_ errorMessage: String?)
}

protocol ImageCommentsLoadingView {
	func display(_ isLoading: Bool)
}

protocol ImageCommentsView {
	func display(_ comments: [FeedImageComment])
}

final class ImageCommentsPresenter {
	static var title: String { "Comments" }
	private var commentsLoadError: String { "Couldn't connect to server" }
	
	private let commentsView: ImageCommentsView
	private let loadingView: ImageCommentsLoadingView
	private let errorView: ImageCommentsErrorView
	
	init(commentsView: ImageCommentsView, loadingView: ImageCommentsLoadingView, errorView: ImageCommentsErrorView) {
		self.commentsView = commentsView
		self.loadingView = loadingView
		self.errorView = errorView
	}
	
	func didStartLoadingComments() {
		errorView.display(nil)
		loadingView.display(true)
	}
	
	func didFinishLoadingComments(with imageComments: [FeedImageComment]) {
		commentsView.display(imageComments)
		loadingView.display(false)
	}
	
	func didFinishLoadingComments(with error: Error) {
		errorView.display(commentsLoadError)
		loadingView.display(false)
	}
}

class ImageCommentsPresenterTests: XCTestCase {

	func test_title_isLocalized() {
		XCTAssertEqual(ImageCommentsPresenter.title, localized("IMAGE_COMMENTS_VIEW_TITLE"))
	}
	
	func test_init_doesNotSendMessagesToView() {
		let (_, view) = makeSUT()
		
		XCTAssertTrue(view.messages.isEmpty)
	}
	
	func test_didStartLoadingComments_displaysNoErrorMessageAndStartsLoading() {
		let (sut, view) = makeSUT()
		
		sut.didStartLoadingComments()
		
		XCTAssertEqual(view.messages, [
			.display(errorMessage: nil),
			.display(isLoading: true)
		])
	}
	
	func test_didFinishLoadingComments_displaysCommentsAndStopsLoading() {
		let (sut, view) = makeSUT()
		let comments = uniqueImageComments()
		
		sut.didFinishLoadingComments(with: comments)
		
		XCTAssertEqual(view.messages, [
			.display(comments: comments),
			.display(isLoading: false)
		])
	}
	
	func test_didFinishLoadingCommentsWithError_displaysLocalizedErrorMessageAndStopsLoading() {
		let (sut, view) = makeSUT()
		
		sut.didFinishLoadingComments(with: anyNSError())
		
		XCTAssertEqual(view.messages, [
			.display(errorMessage: localized("IMAGE_COMMENTS_LOAD_ERROR")),
			.display(isLoading: false)
		])
	}
	
	// MARK: - Helpers
	
	private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: ImageCommentsPresenter, view: ViewSpy) {
		let view = ViewSpy()
		let sut = ImageCommentsPresenter(commentsView: view, loadingView: view, errorView: view)
		trackForMemoryLeaks(view, file: file, line: line)
		trackForMemoryLeaks(sut, file: file, line: line)
		return (sut, view)
	}
	
	func localized(_ key: String, file: StaticString = #file, line: UInt = #line) -> String {
		let bundle = Bundle(for: ImageCommentsPresenter.self)
		let table = "ImageComments"
		let localizedString = bundle.localizedString(forKey: key, value: nil, table: table)
		if localizedString == key {
			XCTFail("Missing localized string for key: \(key) in table: \(table)", file: file, line: line)
		}
		return localizedString
	}
	
	func uniqueImageComment() -> FeedImageComment {
		return FeedImageComment(id: UUID(), message: "any message", createdAt: Date(), author: CommentAuthor(username: "any username"))
	}
	
	func uniqueImageComments() -> [FeedImageComment] {
		return [uniqueImageComment(), uniqueImageComment()]
	}
	
	final class ViewSpy: ImageCommentsView, ImageCommentsLoadingView, ImageCommentsErrorView {
		enum Message: Hashable {
			case display(errorMessage: String?)
			case display(isLoading: Bool)
			case display(comments: [FeedImageComment])
		}
		
		private(set) var messages = Set<Message>()
		
		func display(_ comments: [FeedImageComment]) {
			messages.insert(.display(comments: comments))
		}
		
		func display(_ isLoading: Bool) {
			messages.insert(.display(isLoading: isLoading))
		}
		
		func display(_ errorMessage: String?) {
			messages.insert(.display(errorMessage: errorMessage))
		}
	}

}
