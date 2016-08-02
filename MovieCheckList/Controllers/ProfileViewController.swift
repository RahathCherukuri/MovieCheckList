//
//  ProfileViewController.swift
//  MovieCheckList
//
//  Created by Rahath cherukuri on 8/2/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var greetings: UILabel!
    
    @IBOutlet weak var toWatchMoviesCount: UILabel!
    
    @IBOutlet weak var watchedMoviesCount: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let name = "Rahath"
        greetings.text = "Greetings " + name
        let toWatchMovies = MVClient.sharedInstance.fetchMovies(false)
        let watchedMovies = MVClient.sharedInstance.fetchMovies(true)
        print("toWatchMovies: ",toWatchMovies.count)
        print("watchedMovies: ",watchedMovies.count)
        toWatchMoviesCount.text = String(toWatchMovies.count)
        watchedMoviesCount.text = String(watchedMovies.count)
    }
    
    @IBAction func signOut(sender: UIButton) {
        print("SignOut Clikced")
    }
}
