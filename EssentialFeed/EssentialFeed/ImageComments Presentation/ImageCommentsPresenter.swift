//
//  ImageCommentsPresenter.swift
//  EssentialFeedTests
//
//  Created by Tulio Parreiras on 21/03/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation

public protocol ImageCommentsErrorView {
	func display(_ errorMessage: String?)
}

public protocol ImageCommentsLoadingView {
	func display(_ isLoading: Bool)
}

public protocol ImageCommentsView {
	func display(_ comments: [FeedImageComment])
}

public final class ImageCommentsPresenter {
	public static var title: String {
		NSLocalizedString("IMAGE_COMMENTS_VIEW_TITLE",
						  tableName: "ImageComments",
						  bundle: Bundle(for: ImageCommentsPresenter.self),
						  comment: "Title for comments view")
	}
	private var commentsLoadError: String {
		NSLocalizedString("IMAGE_COMMENTS_LOAD_ERROR",
						  tableName: "ImageComments",
						  bundle: Bundle(for: ImageCommentsPresenter.self),
						  comment: "Error message displayed when we can't load the image comments from the server")
	}
	
	private let commentsView: ImageCommentsView
	private let loadingView: ImageCommentsLoadingView
	private let errorView: ImageCommentsErrorView
	
	public init(commentsView: ImageCommentsView, loadingView: ImageCommentsLoadingView, errorView: ImageCommentsErrorView) {
		self.commentsView = commentsView
		self.loadingView = loadingView
		self.errorView = errorView
	}
	
	public func didStartLoadingComments() {
		errorView.display(nil)
		loadingView.display(true)
	}
	
	public func didFinishLoadingComments(with imageComments: [FeedImageComment]) {
		commentsView.display(imageComments)
		loadingView.display(false)
	}
	
	public func didFinishLoadingComments(with error: Error) {
		errorView.display(commentsLoadError)
		loadingView.display(false)
	}
}
