//
//  ViewController.swift
//  Hola
//
//  Created by Pritesh Shah on 9/8/15.
//  Copyright (c) 2015 Magnet Systems, Inc. All rights reserved.
//

import UIKit
import MMX
import FBSDKCoreKit
import FBSDKLoginKit

class ViewController: UIViewController, FBSDKLoginButtonDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
		
		//Setup Facebook button
		setupFacebook()
		//If have valid facebook session token just login to MMX
		if (FBSDKAccessToken.currentAccessToken() != nil) {
			fetchUserFacebookDataAndLogin()
		}
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
            print(error)
        }

        
        // 4. Login using your username (the one you just created)
        MMXUser.logInWithCredential(credential, success: { (user) -> Void in

            self.performSegueWithIdentifier("showMessagesSegue", sender: self)
            
        }) { (error) -> Void in
            print(error)
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
                print(error)
            }
            
        }) { (error) -> Void in
                print(error)
        }
    }

	//Facebook
	
	func setupFacebook() {
		FBSDKProfile.enableUpdatesOnAccessTokenChange(true)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "onProfileUpdated:", name:FBSDKProfileDidChangeNotification, object: nil)
		// Do any additional setup after loading the view, typically from a nib.
		var loginButton = FBSDKLoginButton()
		loginButton.delegate = self
		let buttonWidth = 150.0
		let buttonXPos: Float = Float(self.view.frame.size.width)/2.0 - Float(buttonWidth/2.0)
		loginButton.frame = CGRectMake(CGFloat(buttonXPos), CGFloat(buttonWidth), 150, 40)
		loginButton.readPermissions = ["email","user_friends","user_birthday"]
		self.view.addSubview(loginButton)
		
	}

	func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
		print("\n\nloginButton didCompleteWithResult token \(result.token.tokenString) \n userID  \(result.token.userID) \ngrantedPermissions = \(result.grantedPermissions) \nerror \(error)")
		fetchUserFacebookDataAndLogin()
	}
	
	func fetchUserFacebookDataAndLogin() {
		if (FBSDKAccessToken.currentAccessToken() != nil) {
			let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath:  "me", parameters: ["fields":"id,name,email,birthday"])
			graphRequest.startWithCompletionHandler({ (connection: FBSDKGraphRequestConnection!, requestResult: AnyObject!, requestError: NSError!) -> Void in
				let name: AnyObject? = requestResult.valueForKey("name")
				let email: AnyObject? = requestResult.valueForKey("email")
				let userID: AnyObject? = requestResult.valueForKey("id")
				
				self.registerAndLoginToMMX(name as! String, email: email as! String, userID: userID as! String)
				print("\n\ngraphRequest startWithCompletionHandler: \nname \(name) \n email  \(email) \nuserID = \(userID) \nerror \(requestError)\n\nAll Values \(requestResult.allValues)")
			})
		}
	}
	
	func registerAndLoginToMMX(name: String, email: String, userID: String) {
		let user = MMXUser()
		user.username = userID
		user.displayName = name
		let credential = NSURLCredential(user: user.username, password: userID, persistence: .None)
		user.registerWithCredential(credential, success: { () -> Void in
			MMXUser.logInWithCredential(credential, success: { (user) -> Void in
				print("\n\nlogInWithCredential success!!!\n\n")
				self.performSegueWithIdentifier("showMessagesSegue", sender: self)
				}, failure: { (error) -> Void in
					print("logInWithCredential error = \(error)")
			})
			}) { (error) -> Void in
				if error.code == 409 {
					MMXUser.logInWithCredential(credential, success: { (user) -> Void in
						print("\n\nlogInWithCredential success!!!\n\n")
						self.performSegueWithIdentifier("showMessagesSegue", sender: self)
						}, failure: { (error) -> Void in
							print("logInWithCredential error = \(error)")
					})
				} else {
					print("logInWithCredential error = \(error)")
				}
		}
	}
	
	func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
		
	}
	
	func onProfileUpdated(notification: NSNotification) {
		print("\n\nonProfileUpdated notification \(FBSDKProfile.currentProfile())\n")
	}

}

