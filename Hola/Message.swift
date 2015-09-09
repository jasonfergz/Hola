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

class Message : NSObject, JSQMessageData {
    
    let underlyingMessage: MMXMessage
    
    init(message: MMXMessage) {
        self.underlyingMessage = message
    }
    
    func senderId() -> String! {
        return underlyingMessage.sender.username
    }
    
    func senderDisplayName() -> String! {
        return underlyingMessage.sender.displayName
    }
    
    func date() -> NSDate! {
        if let date = underlyingMessage.timestamp {
            return date
        }
        
        return NSDate()
    }
    
    func isMediaMessage() -> Bool {
        return false
    }
    
    func messageHash() -> UInt {
        // FIXME:
        let contentHash = isMediaMessage() ? media().hash : text().hash;
        return UInt(senderId().hash ^ date().hash ^ contentHash);
    }
    
    func text() -> String! {
        return underlyingMessage.messageContent["message"] as! String
    }
    
    func media() -> JSQMessageMediaData! {
        return nil
    }
    
//    optional func media() -> JSQMessageMediaData!
    
}
