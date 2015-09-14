//
//  MessagesViewController.swift
//  Hola
//
//  Created by Pritesh Shah on 9/8/15.
//  Copyright (c) 2015 Magnet Systems, Inc. All rights reserved.
//

import Foundation
import JSQMessagesViewController
import MMX
import AFNetworking

class MessagesViewController : JSQMessagesViewController, UIActionSheetDelegate {
    
    var messages = [JSQMessageData]()
    var avatars = Dictionary<String, UIImage>()
    var outgoingBubbleImageView = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
    var incomingBubbleImageView = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleBlueColor())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        senderId = MMXUser.currentUser().username
        senderDisplayName = MMXUser.currentUser().displayName
        
        showLoadEarlierMessagesHeader = true
        
//        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage.jsq_defaultTypingIndicatorImage(), style: .Bordered, target: self, action: "receiveMessagePressed:")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // 8. Receive the message
        // Indicate that you are ready to receive messages now!
        MMX.enableIncomingMessages()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didReceiveMessage:", name: MMXDidReceiveMessageNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func didReceiveMessage(notification: NSNotification) {

        /**
         *  Show the typing indicator to be shown
         */
        showTypingIndicator = !self.showTypingIndicator
        
        /**
         *  Scroll to actually view the indicator
         */
        scrollToBottomAnimated(true)
        
        /**
         *  Upon receiving a message, you should:
         *
         *  1. Play sound (optional)
         *  2. Add new id<JSQMessageData> object to your data source
         *  3. Call `finishReceivingMessage`
         */
        let tmp : [NSObject : AnyObject] = notification.userInfo!
        let mmxMessage = tmp[MMXMessageKey] as! MMXMessage
        
        /**
         *  Allow typing indicator to show
         */
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(1.0 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
            let message = Message(message: mmxMessage) {
                self.collectionView!.reloadData()
            }
            self.messages.append(message)
            JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
            self.finishReceivingMessageAnimated(true)
            
            if message.isMediaMessage() {
                
                switch message.type {
                case .Text:
                    //return nil
                    print("Text")
                case .Location:
                    let location = CLLocation(latitude: (mmxMessage.messageContent["latitude"] as! NSString).doubleValue, longitude: (mmxMessage.messageContent["longitude"] as! NSString).doubleValue)
                    let locationMediaItem = JSQLocationMediaItem()
                    locationMediaItem.setLocation(location) {
                        self.collectionView?.reloadData()
                    }
                    message.mediaContent = locationMediaItem
                case .Photo:
                    let photoURL = NSURL(string: mmxMessage.messageContent["url"] as! String)
                    let requestOperation = AFHTTPRequestOperation(request: NSURLRequest(URL: photoURL!))
                    let responseSerializer = AFImageResponseSerializer()
                    // FIXME: We should set the correct Content-Type header during upload, but can't seem to figure it out.
                    // https://github.com/AFNetworking/AFAmazonS3Manager/issues/91
                    responseSerializer.acceptableContentTypes = ["binary/octet-stream"]
                    requestOperation.responseSerializer = responseSerializer
                    requestOperation.setCompletionBlockWithSuccess({ (operation, responseObject) -> Void in
                        let photo = JSQPhotoMediaItem(image: responseObject as! UIImage)
                        message.mediaContent = photo
                        self.collectionView?.reloadData()
                    }, failure: { (operation, error) -> Void in
                        print("error = \(error)")
                    })
                    requestOperation.start()
                    
                case .Video:
//                    return nil
                    print("Video")
                }
            }
        })
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        
        /**
         *  Sending a message. Your implementation of this method should do *at least* the following:
         *
         *  1. Play sound (optional)
         *  2. Add new id<JSQMessageData> object to your data source
         *  3. Call `finishSendingMessage`
         */
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        let messageContent = [
            "type": MessageType.Text.rawValue,
            "message": text,
        ]
        let mmxMessage = MMXMessage(toRecipients: Set([currentRecipient()]), messageContent: messageContent)
        mmxMessage.sendWithSuccess( { () -> Void in
            let message = Message(message: mmxMessage)
            self.messages.append(message)
            self.finishSendingMessageAnimated(true)
        }) { (error) -> Void in
            print(error)
        }
    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
        
        let sheet = UIActionSheet(title: "Media messages", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Send photo", "Send location", "Send video")
        
        sheet.showFromToolbar(inputToolbar!)
    }
    
    // MARK: UIActionSheetDelegate methods
    
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        if buttonIndex == actionSheet.cancelButtonIndex {
            return;
        }
        
        switch buttonIndex {
        case 1:
            addPhotoMediaMessage()
            print("addPhotoMediaMessage")
        case 2:
            addLocationMediaMessageCompletion {
                self.collectionView!.reloadData()
            }
        case 3:
            // addVideoMediaMessage
            print("addVideoMediaMessage")
        default:
            print("default")
        }
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didDeleteMessageAtIndexPath indexPath: NSIndexPath!) {
        messages.removeAtIndex(indexPath.item)
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        let message = messages[indexPath.item]
        
        if message.senderId() == senderId {
            return outgoingBubbleImageView
        }
        
        return incomingBubbleImageView
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = messages[indexPath.item]
        if let avatar = avatars[message.senderId()] {
            return JSQMessagesAvatarImageFactory.avatarImageWithImage(avatar, diameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
        } else {
            let avatarURL = NSURL(string: "https://graph.facebook.com/v2.2/10153012454715971/picture?type=large")
            let avatarDownloadTask = NSURLSession.sharedSession().downloadTaskWithURL(avatarURL!, completionHandler: { (location, _, error) -> Void in
                dispatch_async(dispatch_get_main_queue()) {
                    let avatarData = NSData(contentsOfURL: location!)
                    if let _ = avatarData {
                        let avatarImage = UIImage(data: avatarData!)
                        self.avatars[message.senderId()] = avatarImage
                        collectionView.reloadItemsAtIndexPaths([indexPath])
                    }
                }
            })
            
            avatarDownloadTask.resume()
        }
        
//        let nameParts = split(message.senderDisplayName().characters){$0 == " "}.map{$0.prefix(1)}
//        let initials = ("".join(nameParts) as NSString).substringToIndex(min(nameParts.count, 2)).uppercaseString
        
        let initials = "PS"
        
        return JSQMessagesAvatarImageFactory.avatarImageWithUserInitials(initials, backgroundColor: UIColor(white: 0.85, alpha: 1.0), textColor: UIColor(white: 0.65, alpha: 1.0), font: UIFont.systemFontOfSize(14.0), diameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        if indexPath.item % 3 == 0 {
            let message = messages[indexPath.item]
            return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(message.date())
        }
        
        return nil
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item]
        
        /**
         *  iOS7-style sender name labels
         */
        if message.senderId() == senderId {
            return nil
        }
        
        if indexPath.item - 1 > 0 {
            let previousMessage = messages[indexPath.item - 1]
            if previousMessage.senderId()  == message.senderId() {
                return nil
            }
        }
        
        /**
         *  Don't specify attributes to use the defaults.
         */
        return NSAttributedString(string: message.senderDisplayName())
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        return nil
    }
    
    // MARK: UICollectionView DataSource
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        
        if !message.isMediaMessage() {
            if message.senderId() == senderId {
                cell.textView!.textColor = UIColor.blackColor()
            } else {
                cell.textView!.textColor = UIColor.whiteColor()
            }
            
            // FIXME: 1
            cell.textView!.linkTextAttributes = [
                NSForegroundColorAttributeName : cell.textView?.textColor as! AnyObject,
                NSUnderlineStyleAttributeName : NSUnderlineStyle.StyleSingle.rawValue | NSUnderlineStyle.PatternSolid.rawValue
            ]
        }
        
        return cell
    }
    
    // MARK: JSQMessagesCollectionViewDelegateFlowLayout methods
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        /**
         *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
         */
        
        /**
         *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
         *  The other label height delegate methods should follow similarly
         *
         *  Show a timestamp for every 3rd message
         */
        if indexPath.item % 3 == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
        return 0.0
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        /**
         *  iOS7-style sender name labels
         */
        let currentMessage = messages[indexPath.item]
        if currentMessage.senderId() == senderId {
            return 0.0
        }
        
        if indexPath.item - 1 > 0 {
            let previousMessage = messages[indexPath.item - 1]
            if previousMessage.senderId() == currentMessage.senderId() {
                return 0.0
            }
        }
        
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 0.0
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        print("Load earlier messages!")
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, atIndexPath indexPath: NSIndexPath!) {
        print("Tapped avatar!")
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAtIndexPath indexPath: NSIndexPath!) {
        print("Tapped message bubble!")
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapCellAtIndexPath indexPath: NSIndexPath!, touchLocation: CGPoint) {
        print("Tapped cell at \(touchLocation)")
    }
    
    // MARK: Helper methods
    
    func currentRecipient() -> MMXUser {
        let currentRecipient = MMXUser()
        currentRecipient.username = "echo_bot"
        
        return currentRecipient
    }
    
    func addLocationMediaMessageCompletion(completion: JSQLocationMediaItemCompletionBlock) {
        let ferryBuildingInSF = CLLocation(latitude: 37.795313, longitude: -122.393757)

        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        let messageContent = [
            "type": MessageType.Location.rawValue,
            "latitude": "\(ferryBuildingInSF.coordinate.latitude)",
            "longitude": "\(ferryBuildingInSF.coordinate.longitude)"
        ]
        let mmxMessage = MMXMessage(toRecipients: Set([currentRecipient()]), messageContent: messageContent)
        mmxMessage.sendWithSuccess( { () -> Void in
            let message = Message(message: mmxMessage)
            let locationMediaItem = JSQLocationMediaItem()
            locationMediaItem.setLocation(ferryBuildingInSF) {
            }
            message.mediaContent = locationMediaItem
            self.messages.append(message)
            self.finishSendingMessageAnimated(true)
            }) { (error) -> Void in
                print(error)
        }
    }
    
    func addPhotoMediaMessage() {
        let imageName = "goldengate"
        let imageType = "png"
        let image = UIImage(named: imageName)
        _ = JSQPhotoMediaItem(image: image)
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        let messageContent = [
            "type": MessageType.Photo.rawValue,
//            "url": photoURL
        ]
        let mmxMessage = MMXMessage(toRecipients: Set([currentRecipient()]), messageContent: messageContent)
        let imagePath = fileInDocumentsDirectory("\(imageName).\(imageType)")
        mmxMessage.sendWithFileAttachment(imagePath, saveToS3Path: "/magnet_test/\(imageName).\(imageType)", progress: { (progress) -> Void in
            //
        }, success: { (url) -> Void in
            print(url)
            let message = Message(message: mmxMessage)
            let photo = JSQPhotoMediaItem(image: UIImage(data: NSData(contentsOfFile: imagePath)!))
            message.mediaContent = photo
            self.messages.append(message)
            self.finishSendingMessageAnimated(true)
        }) { (error) -> Void in
            print(error)
        }
    }
    
    func documentsDirectory() -> String {
        let documentsFolderPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] 
        return documentsFolderPath
    }
    
    func fileInDocumentsDirectory(filename: String) -> String {
        return (NSURL(string: documentsDirectory())?.URLByAppendingPathComponent(filename).absoluteString)!
    }
}
