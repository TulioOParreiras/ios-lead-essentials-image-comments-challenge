//
//  ImageCommentsPresenterTests.swift
//  EssentialFeedTests
//
//  Created by Tulio Parreiras on 21/03/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest

protocol ImageCommentsErrorView {
	func display(_ errorMessage: String?)
}

protocol ImageCommentsLoadingView {
	func display(_ isLoading: Bool)
}

final class ImageCommentsPresenter {
	static var title: String { "Comments" }
	
	private let loadingView: ImageCommentsLoadingView
	private let errorView: ImageCommentsErrorView
	
	init(loadingView: ImageCommentsLoadingView, errorView: ImageCommentsErrorView) {
		self.loadingView = loadingView
		self.errorView = errorView
	}
	
	func didStartLoadingComments() {
		errorView.display(nil)
		loadingView.display(true)
	}
}

class ImageCommentsPresenterTests: XCTestCase {

	func test_title_isLocalized() {
		let bundle = Bundle(for: ImageCommentsPresenter.self)
		let table = "ImageComments"
		let title = bundle.localizedString(forKey: "IMAGE_COMMENTS_VIEW_TITLE", value: nil, table: table)
		XCTAssertEqual(ImageCommentsPresenter.title, title)
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
	
	// MARK: - Helpers
	
	private func makeSUT() -> (sut: ImageCommentsPresenter, view: ViewSpy) {
		let view = ViewSpy()
		let sut = ImageCommentsPresenter(loadingView: view, errorView: view)
		return (sut, view)
	}
	
	final class ViewSpy: ImageCommentsLoadingView, ImageCommentsErrorView {
		enum Message: Hashable {
			case display(errorMessage: String?)
			case display(isLoading: Bool)
		}
		
		private(set) var messages = Set<Message>()
		
		func display(_ isLoading: Bool) {
			messages.insert(.display(isLoading: isLoading))
		}
		
		func display(_ errorMessage: String?) {
			messages.insert(.display(errorMessage: errorMessage))
		}
	}

}
