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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        authenticateMovieDB.layer.cornerRadius = 10
        authenticateMovieDB.clipsToBounds = true
    }
    
    @IBAction func login(_ sender: UIButton) {
        MVClient.sharedInstance.authenticateWithViewController(self) { (success, errorString) in
            if success {
                self.completeLogin()
            } else {
                DispatchQueue.main.async {
                    self.showAlertView(errorString!)
                }
                self.displayError(errorString)
            }
        }
    }
    
    func getUserAndSessionID() {
        guard let sessionID = UserDefaults.standard.string(forKey: MVClient.UserDefaults.SessionID) else {
            return
        }
        let userID = UserDefaults.standard.integer(forKey: MVClient.UserDefaults.UserID)
        
        if (userID != 0) {
            MVClient.sharedInstance.userID = userID
            MVClient.sharedInstance.sessionID = sessionID
            completeLogin()
        }
    }
    
    func completeLogin() {
        DispatchQueue.main.async(execute: {
            let controller = self.storyboard!.instantiateViewController(withIdentifier: "ManagerNavigationController") as! UINavigationController
            self.present(controller, animated: true, completion: nil)
        })
    }
    
    func displayError(_ errorString: String?) {
        print("errorString: \(errorString)")
    }
    
}

extension UIViewController {
    func showAlertView(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let dismiss = UIAlertAction (title: "OK", style: UIAlertActionStyle.default, handler: nil)
        alert.addAction(dismiss)
        present(alert, animated: true, completion: nil)
    }
}

