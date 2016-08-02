//
//  WatchedMoviesViewController.swift
//  MovieCheckList
//
//  Created by Rahath cherukuri on 7/24/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import UIKit

class WatchedListViewController: UIViewController {
    
    @IBOutlet weak var watchedListTableView: UITableView!
    
    var watchedMoviesList: [Movie] = [Movie]()
    
    override func viewWillAppear(animated: Bool) {
        let movies = MVClient.sharedInstance.fetchMovies(true)
        if (!movies.isEmpty) {
            print("array in WatchedListViewController")
            watchedMoviesList = movies
            self.watchedListTableView.reloadData()
        } else {
            MVClient.sharedInstance.getFavoriteMovies() {(success, errorString, movies) in
                if success {
                    self.watchedMoviesList = movies!
                    dispatch_async(dispatch_get_main_queue()) {
                        self.watchedListTableView.reloadData()
                    }
                } else {
                    self.displayError(errorString)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func displayError(errorString: String?) {
        print("errorString: \(errorString)")
    }
    
    func deleteWatchListMovies(movie: Movie, indexPath: NSIndexPath) {
        MVClient.sharedInstance.postToFavorites(movie, favorite: false) { status_code, error in
            if let err = error {
                print(err)
            } else{
                if status_code == 13 {
                    self.deleteMovie(movie)
                    dispatch_async(dispatch_get_main_queue()) {
                        self.watchedListTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                    }
                }else {
                    print("Unexpected status code \(status_code)")
                }
            }
        }
    }
    
    func deleteMovie(movie: Movie) {
        watchedMoviesList = watchedMoviesList.filter({
            let bool = ($0.id != movie.id)
            if !bool {
                MVClient.sharedInstance.sharedContext.deleteObject($0)
                MVClient.sharedInstance.saveContext()
            }
            return bool
        })
    }
}

extension WatchedListViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return watchedMoviesList.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        /* Get cell type */
        let cellReuseIdentifier = "WatchedlistCell"
        let movie = watchedMoviesList[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(cellReuseIdentifier) as! WatchedListTableViewCell!
        
        /* Set cell defaults */
        if ((movie.releaseYear) != nil) {
            cell.movieTitle.text = "\(movie.title) (\(movie.releaseYear!))"
        }
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
            let movie = watchedMoviesList[indexPath.row]
            deleteWatchListMovies(movie, indexPath: indexPath)
        default:
            break
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        /* Push the movie detail view */
        let controller = self.storyboard!.instantiateViewControllerWithIdentifier("MovieDetailViewController") as! MovieDetailViewController
        controller.movie = watchedMoviesList[indexPath.row]
        self.navigationController!.pushViewController(controller, animated: true)
    }
}