//
//  ImageCommentsPresenterTests.swift
//  EssentialFeedTests
//
//  Created by Tulio Parreiras on 21/03/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest

final class ImageCommentsPresenter {
	static var title: String { "Comments" }
}

class ImageCommentsPresenterTests: XCTestCase {

	func test_title_isLocalized() {
		let bundle = Bundle(for: ImageCommentsPresenter.self)
		let table = "ImageComments"
		let title = bundle.localizedString(forKey: "IMAGE_COMMENTS_VIEW_TITLE", value: nil, table: table)
		XCTAssertEqual(ImageCommentsPresenter.title, title)
	}

}
