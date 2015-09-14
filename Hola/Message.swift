//
//  Message.swift
//  Hola
//
//  Created by Pritesh Shah on 9/9/15.
//  Copyright (c) 2015 Magnet Systems, Inc. All rights reserved.
//

import Foundation
import JSQMessagesViewController
import MMX

extension UIImage {
    class func imageWithColor(color: UIColor) -> UIImage {
        let rect = CGRectMake(0.0, 0.0, 1.0, 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}

class Message : NSObject, JSQMessageData {
    
    let underlyingMessage: MMXMessage
    let completion: JSQLocationMediaItemCompletionBlock
    
    lazy var type: MessageType = {
        return MessageType(rawValue: self.underlyingMessage.messageContent["type"] as! String)
    }()!
    
    lazy var mediaContent: JSQMessageMediaData! = {
        let messageContent = self.underlyingMessage.messageContent
        
        switch self.type {
        case .Text:
            return nil
        case .Location:
            let location = CLLocation(latitude: (messageContent["latitude"] as! NSString).doubleValue, longitude: (messageContent["longitude"] as! NSString).doubleValue)
            let locationMediaItem = JSQLocationMediaItem()
            locationMediaItem.setLocation(location, withCompletionHandler: self.completion)
            return locationMediaItem
        case .Photo:
//            let photoURL = NSURL(string: messageContent["url"] as! String)
//            let avatarDownloadTask = NSURLSession.sharedSession().downloadTaskWithURL(photoURL!, completionHandler: { (location, _, error) -> Void in
//                dispatch_async(dispatch_get_main_queue()) {
//                    let avatarData = NSData(contentsOfURL: location!)
//                    if let _ = avatarData {
//                        
//                        let photo = JSQPhotoMediaItem(image: UIImage(data: avatarData!))
//                        self.completion()
//                    }
//                }
//            })
            let photo = JSQPhotoMediaItem(image: UIImage.imageWithColor(UIColor.redColor()))
            photo.image = nil
            return photo
        case .Video:
            return nil
        }
    }()
    
    init(message: MMXMessage, completion: JSQLocationMediaItemCompletionBlock = {}) {
        self.underlyingMessage = message
        self.completion = completion
    }
    
    func senderId() -> String! {
        return underlyingMessage.sender.username
    }
    
    func senderDisplayName() -> String! {
        return (underlyingMessage.sender.displayName != nil) ? underlyingMessage.sender.displayName : underlyingMessage.sender.username
    }
    
    func date() -> NSDate! {
        if let date = underlyingMessage.timestamp {
            return date
        }
        
        return NSDate()
    }
    
    func isMediaMessage() -> Bool {
        return (type != MessageType.Text)
    }
    
    func messageHash() -> UInt {
        // FIXME:
//        let contentHash = isMediaMessage() ? Int(media().mediaHash()) : text().hash
//        return UInt(senderId().hash ^ date().hash ^ contentHash)
        return UInt(abs(underlyingMessage.messageID.hash))
    }
    
    func text() -> String! {
        return underlyingMessage.messageContent["message"] as! String
    }
    
    func media() -> JSQMessageMediaData! {
        return mediaContent
    }
    
    override var description: String {
        return "senderId is \(senderId()), messageContent is \(underlyingMessage.messageContent)"
    }
    
}
