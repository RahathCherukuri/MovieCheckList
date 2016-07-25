//
//  WatchListViewController.swift
//  MovieCheckList
//
//  Created by Rahath cherukuri on 7/11/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import UIKit

class WatchListViewController: UIViewController, MoviePickerViewControllerDelegate {
    
    @IBOutlet weak var watchListTableView: UITableView!
    
    // Add Didset method so that when ever this is set it can invoke allMovies sharedObject
    var watchMoviesList: [Movie] = [Movie]()
    
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        MVClient.sharedInstance.getWatchlistMovies() {(success, errorString, movies) in
            if success {
                self.watchMoviesList = movies!
                dispatch_async(dispatch_get_main_queue()) {
                    self.watchListTableView.reloadData()
                }
            } else {
                self.displayError(errorString)
            }
        }
    }
    
    func setUpUI() {
        parentViewController?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: #selector(WatchListViewController.addActor))
    }
    
    func displayError(errorString: String?) {
        print("errorString: \(errorString)")
    }
    
    // MARK: - Actions
    
    func addActor() {
        let controller = self.storyboard!.instantiateViewControllerWithIdentifier("MoviePickerViewController") as! MoviePickerViewController
        
        controller.delegate = self
        
        self.presentViewController(controller, animated: true, completion: nil)
    }
    
    // MARK: - Actor Picker Delegate
    
    func moviePicker(moviePicker: MoviePickerViewController, didPickMovie movie: Movie?) {
        if let newMovie = movie {
            
            MVClient.sharedInstance.getMovieInfo(newMovie.id) { dataResult in
                switch dataResult {
                case .Success(let mov):
                    var movieDictionary: [String: AnyObject] = mov as! [String : AnyObject]
                    movieDictionary[MVClient.JSONResponseKeys.MovieWatched] = false
                    let movie = Movie(dictionary: movieDictionary)
                    self.watchMoviesList.append(movie)
                    dispatch_async(dispatch_get_main_queue()) {
                        self.watchListTableView.reloadData()
                    }
                case .Failure(let error):
                    self.displayError(MVClient.sharedInstance.getErrorString(error))
                }
            }
        }
    }
    
    func deleteWatchedListMovies(movie: Movie, indexPath: NSIndexPath) {
        MVClient.sharedInstance.postToWatchlist(movie, watchlist: false) { status_code, error in
            if let err = error {
                print(err)
            } else{
                if status_code == 13 {
                    self.delete(movie)
                    dispatch_async(dispatch_get_main_queue()) {
                        self.watchListTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                    }
                }else {
                    print("Unexpected status code \(status_code)")
                }
            }
        }

    }
    
    func delete(movie: Movie) {
        watchMoviesList = watchMoviesList.filter({
            $0.id != movie.id
        })
        MVClient.sharedInstance.allMovies = MVClient.sharedInstance.allMovies.filter({
            $0.id != movie.id
        })
    }
}

extension WatchListViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return watchMoviesList.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        /* Get cell type */
        let cellReuseIdentifier = "WatchlistCell"
        let movie = watchMoviesList[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(cellReuseIdentifier) as! WatchListTableViewCell!
        
        /* Set cell defaults */
        if ((movie.releaseYear) != nil) {
            cell.movieTitle.text = "\(movie.title) (\(movie.releaseYear!))"
        }
        cell.movieTime.text = "Time: " + movie.getHoursAndMinutes(movie.runTime!)
        cell.movieGenre.text = movie.getCommaSeperatedGenres(movie.genres)
        
        cell.moviePoster.image = UIImage(named: "Film")
        cell.moviePoster.contentMode = UIViewContentMode.ScaleAspectFit
        var posterSizes = ["w92", "w154", "w185", "w342", "w500", "w780", "original"]
        
        
        if let posterPath = movie.posterPath {
            MVClient.sharedInstance.taskForGETImage(posterSizes[2], filePath: posterPath, completionHandler: { (imageData, error) in
                if let image = UIImage(data: imageData!) {
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.moviePoster!.image = image
                    }
                } else {
                    print(error)
                }
            })
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch (editingStyle) {
        case .Delete:
            let movie = watchMoviesList[indexPath.row]
            deleteWatchedListMovies(movie, indexPath: indexPath)
        default:
            break
        }
    }
    
}