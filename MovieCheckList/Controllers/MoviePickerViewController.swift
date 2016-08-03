//
//  MoviePickerViewController.swift
//  MovieCheckList
//
//  Created by Rahath cherukuri on 7/16/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import UIKit

protocol MoviePickerViewControllerDelegate {
    func moviePicker(moviePicker: MoviePickerViewController, didPickMovie movie: Movie?)
}

class MoviePickerViewController: UIViewController {
    
    @IBOutlet weak var movieSearchBar: UISearchBar!
    @IBOutlet weak var movieTableView: UITableView!

    // The data for the table
    var movies = [Movie]()
    
    // The delegate will typically be a view controller, waiting for the Movie Picker
    // to return an movie
    var delegate: MoviePickerViewControllerDelegate?
    
    // The most recent data download task. We keep a reference to it so that it can
    // be canceled every time the search text changes
    var searchTask: NSURLSessionDataTask?
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        movieSearchBar.delegate = self
        
        /* Configure tap recognizer */
//        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(MoviePickerViewController.handleSingleTap(_:)))
//        tapRecognizer.numberOfTapsRequired = 1
//        tapRecognizer.delegate = self
//        view.addGestureRecognizer(tapRecognizer)
    }
    
    // MARK: Dismissals
    
//    func handleSingleTap(recognizer: UITapGestureRecognizer) {
//        view.endEditing(true)
//    }
//    
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        delegate?.moviePicker(self, didPickMovie: nil)
        dismissViewControllerAnimated(true, completion: nil)
    }
}

// MARK: - MoviePickerViewController: UIGestureRecognizerDelegate

extension MoviePickerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        return movieSearchBar.isFirstResponder()
    }
}

// MARK: - MoviePickerViewController: UISearchBarDelegate

extension MoviePickerViewController: UISearchBarDelegate {
    
    /* Each time the search text changes we want to cancel any current download and start a new one */
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        /* Cancel the last task */
        if let task = searchTask {
            task.cancel()
        }
        
        /* If the text is empty we are done */
        if searchText == "" {
            movies = [Movie]()
            movieTableView?.reloadData()
            return
        }
        
        /* New search */
        searchTask = MVClient.sharedInstance.getMoviesForSearchString(searchText, completionHandler: { (movies, error) -> Void in
            self.searchTask = nil
            if let movies = movies {
                self.movies = movies
                dispatch_async(dispatch_get_main_queue()) {
                    self.movieTableView!.reloadData()
                }
            }
        })
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func showAlertView(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let dismiss = UIAlertAction (title: "OK", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(dismiss)
        presentViewController(alert, animated: true, completion: nil)
    }
}

// MARK: - MoviePickerViewController: UITableViewDelegate, UITableViewDataSource

extension MoviePickerViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let CellReuseId = "MovieSearchCell"
        let movie = movies[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(CellReuseId) as UITableViewCell!
        
        if let releaseYear = movie.releaseYear {
            cell.textLabel!.text = "\(movie.title) (\(releaseYear))"
        } else {
            cell.textLabel!.text = "\(movie.title)"
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let movie = movies[indexPath.row]
        var movieAlreadySaved: Bool = false
        _ = MVClient.sharedInstance.fetchMovies(false).map({
            if ($0.id == movie.id) {
                print("Movie already in watchList")
                movieAlreadySaved = true
                return
            }
        })
        if (movieAlreadySaved) {
            showAlertView("Movie already in watchList")
        }
        
        if(!movieAlreadySaved) {
            _ = MVClient.sharedInstance.fetchMovies(true).map({
                if ($0.id == movie.id) {
                    print("Movie already in watchedList")
                    movieAlreadySaved = true
                    return
                }
            })
        }
        
        if (movieAlreadySaved) {
            showAlertView("Movie already in watchedList")
        }
        
        if (!movieAlreadySaved) {
            MVClient.sharedInstance.postToWatchlist(movie, watchlist: true) { status_code, error in
                if let err = error {
                    print(err)
                } else {
                    if status_code == 1 || status_code == 12 {
//                        print("Success status code \(status_code)")
                        dispatch_async(dispatch_get_main_queue()) {
                            self.delegate?.moviePicker(self, didPickMovie: movie)
                            self.dismissViewControllerAnimated(true, completion: nil)
                        }
                    } else {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.showAlertView("Sorry, couldn't add the movie. Try again later!")
                        }
                        print("Unexpected status code \(status_code)")
                    }
                }
            }
        }
        //        let controller = self.storyboard!.instantiateViewControllerWithIdentifier("MovieDetailViewController") as! MovieDetailViewController
//        controller.movie = movie
//        self.navigationController!.pushViewController(controller, animated: true)
    }
}


