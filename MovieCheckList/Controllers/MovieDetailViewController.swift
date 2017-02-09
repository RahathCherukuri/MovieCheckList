//
//  MovieDetailViewController.swift
//  MovieCheckList
//
//  Created by Rahath cherukuri on 8/1/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import UIKit

class MovieDetailViewController: UIViewController {
    
    @IBOutlet weak var posterImage: UIImageView!
        
    @IBOutlet weak var movieGenre: UILabel!
    
    @IBOutlet weak var movieTime: UILabel!
    
    @IBOutlet weak var movieRating: UILabel!

    @IBOutlet weak var movieOverview: UITextView!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    var movie: Movie?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let movie = movie {
            navigationItem.title = "\(movie.title)"
            
            if (movie.runTime != nil) {
                movieTime.text = "Time: " + movie.getHoursAndMinutes(Float(movie.runTime!))
            }
            
            if (movie.genres != nil) {
                movieGenre.text = movie.genres
            }
            
            if (movie.rating != nil) {
                movieRating.text = "Rating: " + String(format: "%.2f", Double(movie.rating!)) + "/10"
            }
            
            if (movie.overview != nil) {
                movieOverview.text = movie.overview
            }
            
            var posterSizes = ["w92", "w154", "w185", "w342", "w500", "w780", "original"]
            
            spinner.isHidden = false
            spinner.startAnimating()
            
            if let localImage = movie.detailImage {
                posterImage.image = localImage
                stopAndHideSpinner()
            } else if movie.posterPath == nil || movie.posterPath == "" {
                stopAndHideSpinner()
                posterImage.image = UIImage(named: "Film")
            } else {
                if let posterPath = movie.posterPath {
                    MVClient.sharedInstance.taskForGETImage(posterSizes[5], filePath: posterPath, completionHandler: { (imageData, error) in
                        if let image = UIImage(data: imageData!) {
                            movie.detailImage = image
                            DispatchQueue.main.async {
                                self.posterImage.image = image
                                self.stopAndHideSpinner()
                            }
                        } else {
                            print(error)
                            DispatchQueue.main.async {
                                self.showAlertView((error?.description)!)
                                self.stopAndHideSpinner()
                            }
                        }
                    })
                }
            }
        }
    }
    
    func stopAndHideSpinner() {
        spinner.stopAnimating()
        spinner.isHidden = true
    }
}
