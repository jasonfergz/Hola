//
//  ViewController.swift
//  Hola
//
//  Created by Pritesh Shah on 9/8/15.
//  Copyright (c) 2015 Magnet Systems, Inc. All rights reserved.
//

import UIKit
import MMX

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // 8. Receive the message
        // Indicate that you are ready to receive messages now!
        MMX.enableIncomingMessages()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didReceiveMessage:", name: MMXDidReceiveMessageNotification, object: nil)
    }
    
    func didReceiveMessage(notification: NSNotification) {
        let tmp : [NSObject : AnyObject] = notification.userInfo!
        let message : MMXMessage = tmp[MMXMessageKey] as! MMXMessage
        
//        assert(message.messageContent["message"] as! String == "Hello", "Content should match")
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    @IBAction func login(sender: UIButton) {
        
        // 3. Register yourself as a User
        let username = "jane.doe"
        let password = "magnet"

        let credential = NSURLCredential(user: username, password: password, persistence: .None)
        
        let user = MMXUser()
        user.displayName = "Jane Doe"
        user.registerWithCredential(credential, success: { () -> Void in
//            assert(false, "Jane was already registered")
        }) { (error) -> Void in
            println(error)
        }

        
        // 4. Login using your username (the one you just created)
        MMXUser.logInWithCredential(credential, success: { (user) -> Void in

            // 5. Get current user after logging in.
            let loggedInUser = MMXUser.currentUser()
//            assert(loggedInUser.displayName == "Jane Doe")
            
            self.performSegueWithIdentifier("showMessagesSegue", sender: self)
            
        }) { (error) -> Void in
            println(error)
        }
    }

    @IBAction func sendMessage(sender: UIButton) {
        
        // 6. Get Users.
        MMXUser.findByDisplayName("J", limit: 20, success: { (totalCount, users) -> Void in
//            assert(users.count > 0, "Should have at least 1 user")
            
            let janeDoe = users.first as! MMXUser
            
            let message = MMXMessage(toRecipients: Set([janeDoe]), messageContent: ["message": "Hello"])
            message.sendWithSuccess( { () -> Void in
//                assert(message.messageID != nil, "Message send failure")
            }) { (error) -> Void in
                println(error)
            }
            
        }) { (error) -> Void in
                println(error)
        }
    }


}

