//
//  ViewController.swift
//  MovieCheckList
//
//  Created by Rahath cherukuri on 6/16/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var authenticateMovieDB: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        getUserAndSessionID()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        authenticateMovieDB.layer.cornerRadius = 10
        authenticateMovieDB.clipsToBounds = true
    }
    
    @IBAction func login(sender: UIButton) {
        MVClient.sharedInstance.authenticateWithViewController(self) { (success, errorString) in
            if success {
                self.completeLogin()
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    self.showAlertView(errorString!)
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
    
}

extension UIViewController {
    func showAlertView(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let dismiss = UIAlertAction (title: "OK", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(dismiss)
        presentViewController(alert, animated: true, completion: nil)
    }
}

