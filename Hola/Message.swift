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

class Message : NSObject, JSQMessageData, Printable {
    
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
            return nil
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
        let contentHash = isMediaMessage() ? Int(media().mediaHash()) : text().hash
        return UInt(senderId().hash ^ date().hash ^ contentHash)
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
