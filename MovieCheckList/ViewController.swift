//
//  ViewController.swift
//  MovieCheckList
//
//  Created by Rahath cherukuri on 6/16/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        MVClient.sharedInstance.authenticateWithViewController(self) { (success, errorString) in
            print("success: ", success)
            print("errorString: ", errorString)
            if success {
//                self.completeLogin()
            } else {
//                self.displayError(errorString)
            }
        }
    }
}

