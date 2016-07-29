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
    
    override func viewWillAppear(animated: Bool) {
        let movies = MVClient.sharedInstance.getToWatchMoviesList()
        if (!movies.isEmpty) {
            watchMoviesList = movies
        } else {
            MVClient.sharedInstance.getWatchlistMovies() {(success, errorString, movies) in
                if success {
                    self.watchMoviesList = movies!
//                    print("allMovies in viewDidLoad getWatchlistMovies: ", MVClient.sharedInstance.allMovies)
                    dispatch_async(dispatch_get_main_queue()) {
                        self.watchListTableView.reloadData()
                    }
                } else {
                    self.displayError(errorString)
                }
            }
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        loadWatchedListMovies()
    }
    
    func loadWatchedListMovies() {
        let watchedMovies = MVClient.sharedInstance.getWatchedMoviesList()
        if watchedMovies.isEmpty {
            MVClient.sharedInstance.getFavoriteMovies() {(success, errorString, movies) in
            }
        }
    }
    
    func setUpUI() {
        parentViewController?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: #selector(WatchListViewController.addActor))
    }
    
    func displayError(errorString: String?) {
        print("errorString: \(errorString)")
    }
    
    func watchedMovie(sender: UIButton) {
        let movie = watchMoviesList[sender.tag]
        let indexPath: NSIndexPath = NSIndexPath(forRow: sender.tag, inSection: 0)
        deleteWatchedListMovies(movie, indexPath: indexPath, deleteFromAllMovies: false)
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
                    MVClient.sharedInstance.allMovies.append(movie)
//                    print("allMovies in after adding movie: ", MVClient.sharedInstance.allMovies)
                    dispatch_async(dispatch_get_main_queue()) {
                        self.watchListTableView.reloadData()
                    }
                case .Failure(let error):
                    self.displayError(MVClient.sharedInstance.getErrorString(error))
                }
            }
        }
    }
    
    func deleteWatchedListMovies(movie: Movie, indexPath: NSIndexPath, deleteFromAllMovies: Bool) {
        MVClient.sharedInstance.postToWatchlist(movie, watchlist: false) { status_code, error in
            if let err = error {
                print(err)
            } else{
                if status_code == 13 {
                    if (deleteFromAllMovies == true) {
                        self.delete(movie, deleteFromAllMovies: deleteFromAllMovies)
                        dispatch_async(dispatch_get_main_queue()) {
                            self.watchListTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                        }
                    } else {
                        MVClient.sharedInstance.postToFavorites(movie, favorite: true) {status_code, error in
                            if let err = error {
                                print(err)
                            } else {
                                if status_code == 1 || status_code == 12 {
                                    self.delete(movie, deleteFromAllMovies: deleteFromAllMovies)
                                    dispatch_async(dispatch_get_main_queue()) {
                                        self.watchListTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                                    }
                                } else {
                                    print("Unexpected status code \(status_code)")
                                }
                            }
                        }
                    }
                    
                }else {
                    print("Unexpected status code \(status_code)")
                }
            }
        }
    }
    
    func delete(movie: Movie, deleteFromAllMovies: Bool) {
        watchMoviesList = watchMoviesList.filter({
            $0.id != movie.id
        })
        if (deleteFromAllMovies) {
            MVClient.sharedInstance.allMovies = MVClient.sharedInstance.allMovies.filter({
                $0.id != movie.id
            })
        } else {
            var index = 0
            for mov in MVClient.sharedInstance.allMovies {
                if (mov.id == movie.id) {
                    break
                } else {
                    index = index + 1
                }
            }
            MVClient.sharedInstance.allMovies[index].watched = true
        }
//        print("allMovies in delete : ", MVClient.sharedInstance.allMovies)
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
        var movie = watchMoviesList[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(cellReuseIdentifier) as! WatchListTableViewCell!
        
        /* Set cell defaults */
        if ((movie.releaseYear) != nil) {
            cell.movieTitle.text = "\(movie.title) (\(movie.releaseYear!))"
        }
        
        cell.movieWatched.tag = indexPath.row
        cell.movieWatched.addTarget(self, action: #selector(WatchListViewController.watchedMovie(_:)), forControlEvents: .TouchUpInside)
        
        cell.movieTime.text = "Time: " + movie.getHoursAndMinutes(movie.runTime!)
        cell.movieGenre.text = movie.getCommaSeperatedGenres(movie.genres)
        
        cell.moviePoster.image = UIImage(named: "Film")
        cell.moviePoster.contentMode = UIViewContentMode.ScaleAspectFit
        var posterSizes = ["w92", "w154", "w185", "w342", "w500", "w780", "original"]
        
        if let localImage = movie.image {
            cell.moviePoster.image = localImage
        } else if movie.posterPath == nil || movie.posterPath == "" {
            cell.moviePoster.image = UIImage(named: "noImage")
        } else {
            if let posterPath = movie.posterPath {
                MVClient.sharedInstance.taskForGETImage(posterSizes[2], filePath: posterPath, completionHandler: { (imageData, error) in
                    if let image = UIImage(data: imageData!) {
                        movie.image = image
                        dispatch_async(dispatch_get_main_queue()) {
                            cell.moviePoster!.image = image
                        }
                    } else {
                        print(error)
                    }
                })
            }
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch (editingStyle) {
        case .Delete:
            let movie = watchMoviesList[indexPath.row]
            deleteWatchedListMovies(movie, indexPath: indexPath, deleteFromAllMovies: true)
        default:
            break
        }
    }
    
//    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        let movie = watchMoviesList[indexPath.row]
//        print("Movie: ", movie)
//        deleteWatchedListMovies(movie, indexPath: indexPath, deleteFromAllMovies: false)
//    }
    
}