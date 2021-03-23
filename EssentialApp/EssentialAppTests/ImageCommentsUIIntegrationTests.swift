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
	
	static func imageComments(loader: ImageCommentsLoader) -> ImageCommentsViewController {
		let controller = ImageCommentsViewController()
		controller.title = ImageCommentsPresenter.title
		controller.loader = loader
		return controller
	}
}

protocol ImageCommentsLoader {
	func load()
}

final class ImageCommentsViewController: UIViewController {
	
	var loader: ImageCommentsLoader?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		loader?.load()
	}
	
}

final class ImageCommentsUIIntegrationTests: XCTestCase {
	
	func test_imageCommentsView_hasTitle() {
		let loader = LoaderSpy()
		let sut = ImageCommentsUIComposer.imageComments(loader: loader)
		
		sut.loadViewIfNeeded()
		
		let key = "IMAGE_COMMENTS_VIEW_TITLE"
		let table = "ImageComments"
		let bundle = Bundle(for: ImageCommentsPresenter.self)
		let title = bundle.localizedString(forKey: key, value: nil, table: table)
		
		XCTAssertEqual(sut.title, title)
	}

	func test_loadCommentsActions_requestCommentsFromLoader() {
		let loader = LoaderSpy()
		let sut = ImageCommentsUIComposer.imageComments(loader: loader)
		XCTAssertEqual(loader.loadCallCount, 0)
		
		sut.loadViewIfNeeded()
		XCTAssertEqual(loader.loadCallCount, 1)
	}
	
	// MARK: - Helpers
	
	private final class LoaderSpy: ImageCommentsLoader {
		var loadCallCount = 0
		
		func load() {
			loadCallCount += 1
		}
	}

}
