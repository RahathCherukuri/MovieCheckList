//
//  ViewController.swift
//  MovieCheckList
//
//  Created by Rahath cherukuri on 6/16/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    override func viewDidLoad() {
        print("In ViewDidLoad")
        super.viewDidLoad()
        getUserAndSessionID()
    }
    
    override func viewWillAppear(animated: Bool) {
        print("In ViewWillAppear")
        super.viewWillAppear(animated)
    }
    
    @IBAction func login(sender: UIButton) {
        MVClient.sharedInstance.authenticateWithViewController(self) { (success, errorString) in
            print("success: ", success)
            print("errorString: ", errorString)
            if success {
                self.completeLogin()
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    self.showAlertView("Sorry, couldn't login. Try again later!")
                }
                self.displayError(errorString)
            }
        }
    }
    
    func getUserAndSessionID() {
        guard let sessionID = NSUserDefaults.standardUserDefaults().stringForKey(MVClient.UserDefaults.SessionID) else {
            return
        }
        let userID = NSUserDefaults.standardUserDefaults().integerForKey(MVClient.UserDefaults.UserID)
        
        if (userID != 0) {
            MVClient.sharedInstance.userID = userID
            MVClient.sharedInstance.sessionID = sessionID
            print("userID: ", userID)
            print("sessionID: ", sessionID)
            completeLogin()
        }
    }
    
    func completeLogin() {
        dispatch_async(dispatch_get_main_queue(), {
            let controller = self.storyboard!.instantiateViewControllerWithIdentifier("ManagerNavigationController") as! UINavigationController
            self.presentViewController(controller, animated: true, completion: nil)
        })
    }
    
    func displayError(errorString: String?) {
        print("errorString: \(errorString)")
    }
    
    func showAlertView(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let dismiss = UIAlertAction (title: "OK", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(dismiss)
        presentViewController(alert, animated: true, completion: nil)
    }
    
}

