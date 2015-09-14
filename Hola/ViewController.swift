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
}

