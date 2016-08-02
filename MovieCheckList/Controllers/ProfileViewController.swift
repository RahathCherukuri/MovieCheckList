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
        toWatchMoviesCount.text = String(toWatchMovies.count)
        setLabel(toWatchMoviesCount)
        watchedMoviesCount.text = String(watchedMovies.count)
        setLabel(watchedMoviesCount)
    }
    
    @IBAction func signOut(sender: UIButton) {
        print("SignOut Clikced")
    }
    
    func setLabel(label: UILabel) {
        let size:CGFloat = 60.0
        label.textColor = .greenColor()
        label.textAlignment = .Center
        label.font = UIFont.systemFontOfSize(20.0)
        label.bounds = CGRectMake(0.0, 0.0, size, size)
        label.layer.cornerRadius = size / 2
        label.layer.borderWidth = 3.0
        label.layer.backgroundColor = UIColor.clearColor().CGColor
        label.layer.borderColor = UIColor.greenColor().CGColor
    }
}
