//
//  ProfileViewController.swift
//  MovieCheckList
//
//  Created by Rahath cherukuri on 8/2/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import UIKit
import CoreData

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var greetings: UILabel!
    
    @IBOutlet weak var toWatchMoviesCount: UILabel!
    
    @IBOutlet weak var watchedMoviesCount: UILabel!
    
    @IBOutlet weak var signOutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        signOutButton.layer.cornerRadius = 10
        signOutButton.clipsToBounds = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        greetings.text = "Greetings "
        let toWatchMovies = MVClient.sharedInstance.fetchMovies(false)
        let watchedMovies = MVClient.sharedInstance.fetchMovies(true)
        toWatchMoviesCount.text = String(toWatchMovies.count)
        setLabel(toWatchMoviesCount)
        watchedMoviesCount.text = String(watchedMovies.count)
        setLabel(watchedMoviesCount)
    }
    
    @IBAction func signOut(_ sender: UIButton) {
        clearCoreData("Movie")
        setNilValuesForUserDefaults()
        dismiss(animated: true, completion: nil)
    }
    
    func setNilValuesForUserDefaults() {
        let sessionID : String? = nil
        let userID : Int = 0
        UserDefaults.standard.setValue(sessionID, forKey: MVClient.UserDefaults.SessionID)
        UserDefaults.standard.set(userID, forKey: MVClient.UserDefaults.UserID)
    }
    
    func clearCoreData(_ entity:String) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        fetchRequest.includesPropertyValues = false
        do {
            if let results = try MVClient.sharedInstance.sharedContext.fetch(fetchRequest) as? [NSManagedObject] {
                for result in results {
                    MVClient.sharedInstance.sharedContext.delete(result)
                }
                
                MVClient.sharedInstance.saveContext()
            }
        } catch {
            print("failed to clear core data")
        }
    }

    
    func setLabel(_ label: UILabel) {
        let size:CGFloat = 60.0
        label.textColor = .green
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 20.0)
        label.bounds = CGRect(x: 0.0, y: 0.0, width: size, height: size)
        label.layer.cornerRadius = size / 2
        label.layer.borderWidth = 3.0
        label.layer.backgroundColor = UIColor.clear.cgColor
        label.layer.borderColor = UIColor.green.cgColor
    }
}
