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
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        MVClient.sharedInstance.authenticateWithViewController(self) { (success, errorString) in
            print("success: ", success)
            print("errorString: ", errorString)
            if success {
                self.completeLogin()
            } else {
                self.displayError(errorString)
            }
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

