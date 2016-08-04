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
                    dispatch_async(dispatch_get_main_queue()) {
                        self.showAlertView(errorString!)
                    }
                    self.displayError(errorString)
                }
            }
        }
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
                    dispatch_async(dispatch_get_main_queue()) {
                        self.showAlertView("Sorry, couldn't delete the movie. Try again later!")
                    }
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
    
    func showAlertView(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let dismiss = UIAlertAction (title: "OK", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(dismiss)
        presentViewController(alert, animated: true, completion: nil)
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
        
        cell.spinner.hidden = false
        cell.spinner.startAnimating()
        
        if let localImage = movie.image {
            cell.moviePoster.image = localImage
            stopAndHideSpinner(cell)
        } else if movie.posterPath == nil || movie.posterPath == "" {
            cell.moviePoster.image = UIImage(named: "noImage")
            stopAndHideSpinner(cell)
        } else {
            if let posterPath = movie.posterPath {
                MVClient.sharedInstance.taskForGETImage(posterSizes[2], filePath: posterPath, completionHandler: { (imageData, error) in
                    if let image = UIImage(data: imageData!) {
                        movie.image = image
                        dispatch_async(dispatch_get_main_queue()) {
                            self.stopAndHideSpinner(cell)
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
    
    func stopAndHideSpinner(cell: WatchedListTableViewCell) {
        cell.spinner.stopAnimating()
        cell.spinner.hidden = true
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
        let controller = storyboard!.instantiateViewControllerWithIdentifier("MovieDetailViewController") as! MovieDetailViewController
        controller.movie = watchedMoviesList[indexPath.row]
        navigationController!.pushViewController(controller, animated: true)
    }
}