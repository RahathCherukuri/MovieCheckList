//
//  WatchListViewController.swift
//  MovieCheckList
//
//  Created by Rahath cherukuri on 7/11/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import UIKit
import CoreData

class WatchListViewController: UIViewController, MoviePickerViewControllerDelegate {
    
    @IBOutlet weak var watchListTableView: UITableView!
    
    var watchMoviesList: [Movie] = [Movie]()
    
    // MARK: - Life Cycle
    
    override func viewWillAppear(animated: Bool) {
        let movies = MVClient.sharedInstance.fetchMovies(false)
        if (!movies.isEmpty) {
            print("array in WatchListViewController")
            watchMoviesList = movies
        } else {
            MVClient.sharedInstance.getWatchlistMovies() {(success, errorString, movies) in
                if success {
                    self.watchMoviesList = movies!
                    dispatch_async(dispatch_get_main_queue()) {
                        self.watchListTableView.reloadData()
                    }
                    self.loadWatchedListMovies()
                } else {
                    self.displayError(errorString)
                }
            }
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
    }
    
    func loadWatchedListMovies() {
        let watchedMovies = MVClient.sharedInstance.fetchMovies(true)
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
        deleteWatchedListMovies(movie, indexPath: indexPath, addToWatchedListMovies: true)
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
            
            MVClient.sharedInstance.getMovieInfo(Int(newMovie.id)) { dataResult in
                switch dataResult {
                case .Success(let mov):
                    var movieDictionary: [String: AnyObject] = mov as! [String : AnyObject]
                    movieDictionary[MVClient.JSONResponseKeys.MovieWatched] = false
                    let movie = Movie(dictionary: movieDictionary, context: MVClient.sharedInstance.sharedContext)
                    MVClient.sharedInstance.saveContext()
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
    
    func deleteWatchedListMovies(movie: Movie, indexPath: NSIndexPath, addToWatchedListMovies: Bool) {
        MVClient.sharedInstance.postToWatchlist(movie, watchlist: false) { status_code, error in
            if let err = error {
                print(err)
            } else{
                if status_code == 13 {
                    if (addToWatchedListMovies == false) {
                        self.delete(movie, addToWatchedListMovies: addToWatchedListMovies)
                        dispatch_async(dispatch_get_main_queue()) {
                            self.watchListTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                        }
                    } else {
                        MVClient.sharedInstance.postToFavorites(movie, favorite: true) {status_code, error in
                            if let err = error {
                                print(err)
                            } else {
                                if status_code == 1 || status_code == 12 {
                                    self.delete(movie, addToWatchedListMovies: addToWatchedListMovies)
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
    
    func delete(movie: Movie, addToWatchedListMovies: Bool) {
        if(!addToWatchedListMovies) {
            watchMoviesList = watchMoviesList.filter({
                let bool = ($0.id != movie.id)
                if !bool {
                    MVClient.sharedInstance.sharedContext.deleteObject($0)
                    MVClient.sharedInstance.saveContext()
                }
                return bool
            })
        } else {
            let movies = fetchMovies(movie.id)
            if (!movies.isEmpty) {
                let movieContext: NSManagedObject = movies[0]
                movieContext.setValue(true, forKey: "watched")
                MVClient.sharedInstance.saveContext()
                watchMoviesList = MVClient.sharedInstance.fetchMovies(false)
            }
        }
    }
}

func fetchMovies(id: NSNumber) -> [Movie] {
    
    // Create the Fetch Request
    let fetchRequest = NSFetchRequest(entityName: "Movie")
    fetchRequest.predicate = NSPredicate(format: "id == %@", id);
    
    // Execute the Fetch Request
    do {
        return try MVClient.sharedInstance.sharedContext.executeFetchRequest(fetchRequest) as! [Movie]
    } catch _ {
        return [Movie]()
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
        
        cell.movieWatched.tag = indexPath.row
        cell.movieWatched.addTarget(self, action: #selector(WatchListViewController.watchedMovie(_:)), forControlEvents: .TouchUpInside)
        
        cell.movieTime.text = "Time: " + movie.getHoursAndMinutes(Float(movie.runTime!))
        cell.movieGenre.text = movie.genres
        
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
            deleteWatchedListMovies(movie, indexPath: indexPath, addToWatchedListMovies: false)
        default:
            break
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        /* Push the movie detail view */
        let controller = self.storyboard!.instantiateViewControllerWithIdentifier("MovieDetailViewController") as! MovieDetailViewController
        controller.movie = watchMoviesList[indexPath.row]
        self.navigationController!.pushViewController(controller, animated: true)
    }
    
}