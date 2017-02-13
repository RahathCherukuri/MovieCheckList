//
//  MoviePickerViewController.swift
//  MovieCheckList
//
//  Created by Rahath cherukuri on 7/16/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import UIKit

protocol MoviePickerViewControllerDelegate {
    func moviePicker(_ moviePicker: MoviePickerViewController, didPickMovie movie: Movie?)
}

class MoviePickerViewController: UIViewController {
    
    @IBOutlet weak var movieSearchBar: UISearchBar!
    @IBOutlet weak var movieTableView: UITableView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!

    // The data for the table
    var movies = [Movie]()
    
    // The delegate will typically be a view controller, waiting for the Movie Picker
    // to return an movie
    var delegate: MoviePickerViewControllerDelegate?
    
    // The most recent data download task. We keep a reference to it so that it can
    // be canceled every time the search text changes
    var searchTask: URLSessionDataTask?
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        stopAndHideSpinner()
        movieSearchBar.delegate = self
        
        /* Configure tap recognizer */
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(MoviePickerViewController.handleSingleTap(_:)))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.delegate = self
        view.addGestureRecognizer(tapRecognizer)
    }
    
//     MARK: Dismissals
    
    func handleSingleTap(_ recognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }

    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        delegate?.moviePicker(self, didPickMovie: nil)
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - MoviePickerViewController: UIGestureRecognizerDelegate

extension MoviePickerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return movieSearchBar.isFirstResponder
    }
}

// MARK: - MoviePickerViewController: UISearchBarDelegate

extension MoviePickerViewController: UISearchBarDelegate {
    
    /* Each time the search text changes we want to cancel any current download and start a new one */
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        spinner.isHidden = false
        spinner.startAnimating()
        /* Cancel the last task */
        if let task = searchTask {
            stopAndHideSpinner()
            task.cancel()
        }
        
        /* If the text is empty we are done */
        if searchText == "" {
            movies = [Movie]()
            stopAndHideSpinner()
            movieTableView?.reloadData()
            return
        }
        
        /* New search */
        searchTask = MVClient.sharedInstance.getMoviesForSearchString(searchText, completionHandler: { (movies, error) -> Void in
            self.searchTask = nil
            if let movies = movies {
                self.movies = movies
                self.stopAndHideSpinner()
                DispatchQueue.main.async {
                    self.movieTableView!.reloadData()
                }
            } else if let err = error {
                DispatchQueue.main.async {
                    self.stopAndHideSpinner()
                    if (err != "cancelled") {
                        self.showAlertView(err)
                    }

                }
                print(err)
            }
        })
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func stopAndHideSpinner() {
        spinner.stopAnimating()
        spinner.isHidden = true
    }
}

// MARK: - MoviePickerViewController: UITableViewDelegate, UITableViewDataSource

extension MoviePickerViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let CellReuseId = "MovieSearchCell"
        let movie = movies[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: CellReuseId) as UITableViewCell!
        
        if let releaseYear = movie.releaseYear {
            cell?.textLabel!.text = "\(movie.title) (\(releaseYear))"
        } else {
            cell?.textLabel!.text = "\(movie.title)"
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
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
                    DispatchQueue.main.async {
                        self.showAlertView(err)
                    }
                    print(err)
                } else {
                    if status_code == 1 || status_code == 12 {
                        DispatchQueue.main.async {
                            self.delegate?.moviePicker(self, didPickMovie: movie)
                            self.dismiss(animated: true, completion: nil)
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.showAlertView("Sorry, couldn't add the movie. Try again later!")
                        }
                        print("Unexpected status code \(status_code)")
                    }
                }
            }
        }
    }
}


