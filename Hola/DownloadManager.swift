//
//  DownloadManager.swift
//  Hola
//
//  Created by Pritesh Shah on 9/14/15.
//  Copyright © 2015 Magnet Systems, Inc. All rights reserved.
//

import Foundation
import AFNetworking

class DownloadManager {
    
    static let sharedInstance: DownloadManager = {
        return DownloadManager()
    }()
    
    func downloadImage(url: NSURL!, completionHandler: ((UIImage?, NSError?) -> Void)) {

        let requestOperation = AFHTTPRequestOperation(request: NSURLRequest(URL: url))
        let responseSerializer = AFImageResponseSerializer()
        // FIXME: We should set the correct Content-Type header during upload, but can't seem to figure it out.
        // https://github.com/AFNetworking/AFAmazonS3Manager/issues/91
        responseSerializer.acceptableContentTypes?.insert("binary/octet-stream")
        requestOperation.responseSerializer = responseSerializer
        requestOperation.setCompletionBlockWithSuccess({ (operation, responseObject) -> Void in
            completionHandler(responseObject as? UIImage, nil)
        }, failure: { (operation, error) -> Void in
            print("error = \(error)")
            completionHandler(nil, error)
        })
        requestOperation.start()
    }
}
