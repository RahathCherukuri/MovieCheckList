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
    
    override func viewWillAppear(_ animated: Bool) {
        let movies = MVClient.sharedInstance.fetchMovies(true)
        if (!movies.isEmpty) {
            watchedMoviesList = movies
            self.watchedListTableView.reloadData()
        } else {
            MVClient.sharedInstance.getFavoriteMovies() {(success, errorString, movies) in
                if success {
                    self.watchedMoviesList = movies!
                    DispatchQueue.main.async {
                        self.watchedListTableView.reloadData()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.showAlertView(errorString!)
                    }
                    self.displayError(errorString)
                }
            }
        }
    }
    
    func displayError(_ errorString: String?) {
        print("errorString: \(errorString)")
    }
    
    func deleteWatchListMovies(_ movie: Movie, indexPath: IndexPath) {
        MVClient.sharedInstance.postToFavorites(movie, favorite: false) { status_code, error in
            if let err = error {
                DispatchQueue.main.async {
                    self.showAlertView("Sorry, couldn't delete the movie. Try again later!")
                }
                print(err)
            } else{
                if status_code == 13 {
                    self.deleteMovie(movie)
                    DispatchQueue.main.async {
                        self.watchedListTableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
                    }
                }else {
                    DispatchQueue.main.async {
                        self.showAlertView("Sorry, couldn't delete the movie. Try again later!")
                    }
                    print("Unexpected status code \(status_code)")
                }
            }
        }
    }
    
    func deleteMovie(_ movie: Movie) {
        watchedMoviesList = watchedMoviesList.filter({
            let bool = ($0.id != movie.id)
            if !bool {
                MVClient.sharedInstance.sharedContext.delete($0)
                MVClient.sharedInstance.saveContext()
            }
            return bool
        })
    }

}

extension WatchedListViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return watchedMoviesList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        /* Get cell type */
        let cellReuseIdentifier = "WatchedlistCell"
        let movie = watchedMoviesList[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! WatchedListTableViewCell!
        
        /* Set cell defaults */
        if ((movie.releaseYear) != nil) {
            cell?.movieTitle.text = "\(movie.title) (\(movie.releaseYear!))"
        }
        if (movie.runTime != nil) {
            cell?.movieTime.text = "Time: " + movie.getHoursAndMinutes(Float(movie.runTime!))
        }
        if (movie.genres != nil) {
            cell?.movieGenre.text = movie.genres
        }
        
        cell?.moviePoster.image = UIImage(named: "Film")
        cell?.moviePoster.contentMode = UIViewContentMode.scaleAspectFit
        var posterSizes = ["w92", "w154", "w185", "w342", "w500", "w780", "original"]
        
        cell?.spinner.isHidden = false
        cell?.spinner.startAnimating()
        
        if let localImage = movie.image {
            cell?.moviePoster.image = localImage
            stopAndHideSpinner(cell!)
        } else if movie.posterPath == nil || movie.posterPath == "" {
            cell?.moviePoster.image = UIImage(named: "Film")
            stopAndHideSpinner(cell!)
        } else {
            if let posterPath = movie.posterPath {
                _ = MVClient.sharedInstance.taskForGETImage(posterSizes[2], filePath: posterPath, completionHandler: { (imageData, error) in
                    if let image = UIImage(data: imageData!) {
                        movie.image = image
                        DispatchQueue.main.async {
                            self.stopAndHideSpinner(cell!)
                            cell?.moviePoster!.image = image
                        }
                    } else {
                        print(error ?? "Image poster errored")
                    }
                })
            }
        }
        return cell!
    }
    
    func stopAndHideSpinner(_ cell: WatchedListTableViewCell) {
        cell.spinner.stopAnimating()
        cell.spinner.isHidden = true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch (editingStyle) {
        case .delete:
            let movie = watchedMoviesList[indexPath.row]
            deleteWatchListMovies(movie, indexPath: indexPath)
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /* Push the movie detail view */
        let controller = storyboard!.instantiateViewController(withIdentifier: "MovieDetailViewController") as! MovieDetailViewController
        controller.movie = watchedMoviesList[indexPath.row]
        navigationController!.pushViewController(controller, animated: true)
    }
}
