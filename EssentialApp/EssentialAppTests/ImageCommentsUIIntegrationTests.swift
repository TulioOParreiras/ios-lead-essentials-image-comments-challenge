//
//  ImageCommentsUIIntegrationTests.swift
//  EssentialAppTests
//
//  Created by Tulio de Oliveira Parreiras on 23/03/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest
import EssentialFeed

final class ImageCommentsUIComposer {
	private init() { }
	
	static func imageComments() -> ImageCommentsViewController {
		let controller = ImageCommentsViewController()
		controller.title = ImageCommentsPresenter.title
		return controller
	}
}

final class ImageCommentsViewController: UIViewController {
	
}

final class ImageCommentsUIIntegrationTests: XCTestCase {
	
	func test_imageCommentsView_hasTitle() {
		let sut = ImageCommentsUIComposer.imageComments()
		
		sut.loadViewIfNeeded()
		
		let key = "IMAGE_COMMENTS_VIEW_TITLE"
		let table = "ImageComments"
		let bundle = Bundle(for: ImageCommentsPresenter.self)
		let title = bundle.localizedString(forKey: key, value: nil, table: table)
		
		XCTAssertEqual(sut.title, title)
	}


}
