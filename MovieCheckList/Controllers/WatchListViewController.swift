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
    
    override func viewWillAppear(_ animated: Bool) {
        setUpUI()
        let movies = MVClient.sharedInstance.fetchMovies(false)
        if (!movies.isEmpty) {
            watchMoviesList = movies
        } else {
            MVClient.sharedInstance.getWatchlistMovies() {(success, errorString, movies) in
                if success {
                    self.watchMoviesList = movies!
                    DispatchQueue.main.async {
                        self.watchListTableView.reloadData()
                    }
                    self.loadWatchedListMovies()
                } else {
                    DispatchQueue.main.async {
                        self.showAlertView(errorString!)
                    }
                    self.displayError(errorString)
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.navigationItem.rightBarButtonItem = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func loadWatchedListMovies() {
        let watchedMovies = MVClient.sharedInstance.fetchMovies(true)
        if watchedMovies.isEmpty {
            MVClient.sharedInstance.getFavoriteMovies() {(success, errorString, movies) in
            }
        }
    }
    
    func setUpUI() {
        tabBarController?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.add, target: self, action: #selector(WatchListViewController.addActor))
    }
    
    func displayError(_ errorString: String?) {
        print("errorString: \(errorString)")
    }
    
    func watchedMovie(_ sender: UIButton) {
        sender.setImage(UIImage(named: "SelectedCheckMark")!, for: UIControlState())
        let movie = watchMoviesList[sender.tag]
        let indexPath: IndexPath = IndexPath(row: sender.tag, section: 0)
        deleteWatchedListMovies(movie, indexPath: indexPath, addToWatchedListMovies: true, sender: sender)
    }
    
    // MARK: - Actions
    
    func addActor() {
        let controller = storyboard!.instantiateViewController(withIdentifier: "MoviePickerViewController") as! MoviePickerViewController
        
        controller.delegate = self
        
        present(controller, animated: true, completion: nil)
    }
    
    // MARK: - Actor Picker Delegate
    
    func moviePicker(_ moviePicker: MoviePickerViewController, didPickMovie movie: Movie?) {
        if let newMovie = movie {
            
            MVClient.sharedInstance.getMovieInfo(Int(newMovie.id)) { dataResult in
                switch dataResult {
                case .success(let mov):
                    var movieDictionary: [String: AnyObject] = mov as! [String : AnyObject]
                    movieDictionary[MVClient.JSONResponseKeys.MovieWatched] = false as AnyObject?
                    _ = Movie(dictionary: movieDictionary, context: MVClient.sharedInstance.sharedContext)
                    MVClient.sharedInstance.saveContext()
                    self.watchMoviesList = MVClient.sharedInstance.fetchMovies(false)
                    DispatchQueue.main.async {
                        self.watchListTableView.reloadData()
                    }
                case .failure(let error):
                    self.showAlertView(MVClient.sharedInstance.getErrorString(error))
                    self.displayError(MVClient.sharedInstance.getErrorString(error))
                }
            }
        }
    }
    
    func deleteWatchedListMovies(_ movie: Movie, indexPath: IndexPath, addToWatchedListMovies: Bool, sender: UIButton?) {
        MVClient.sharedInstance.postToWatchlist(movie, watchlist: false) { status_code, error in
            if let err = error {
                self.setButtonToInitialState(addToWatchedListMovies, sender: sender)
                DispatchQueue.main.async {
                    self.showAlertView("Sorry, couldn't delete the movie. Try again later!")
                }
                print(err)
            } else{
                if status_code == 13 {
                    if (addToWatchedListMovies == false) {
                        self.delete(movie, addToWatchedListMovies: addToWatchedListMovies)
                        DispatchQueue.main.async {
                            self.watchListTableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
                        }
                    } else {
                        MVClient.sharedInstance.postToFavorites(movie, favorite: true) {status_code, error in
                            if let err = error {
                                self.setButtonToInitialState(addToWatchedListMovies, sender: sender)
                                print(err)
                            } else {
                                if status_code == 1 || status_code == 12 {
                                    self.delete(movie, addToWatchedListMovies: addToWatchedListMovies)
                                    DispatchQueue.main.async {
                                        self.watchListTableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
                                    }
                                } else {
                                    self.setButtonToInitialState(addToWatchedListMovies, sender: sender)
                                    DispatchQueue.main.async {
                                        self.showAlertView("Sorry, couldn't delete the movie. Try again later!")
                                    }
                                    print("Unexpected status code \(status_code)")
                                }
                            }
                        }
                    }
                    
                }else {
                    self.setButtonToInitialState(addToWatchedListMovies, sender: sender)
                    DispatchQueue.main.async {
                        self.showAlertView("Sorry, couldn't delete the movie. Try again later!")
                    }
                    print("Unexpected status code \(status_code)")
                }
            }
        }
    }
    
    func setButtonToInitialState(_ addToWatchedListMovies: Bool, sender: UIButton?) {
        if (addToWatchedListMovies) {
            DispatchQueue.main.async {
                sender!.setImage(UIImage(named: "CheckMark")!, for: UIControlState())
            }
        }
    }
    
    func delete(_ movie: Movie, addToWatchedListMovies: Bool) {
        if(!addToWatchedListMovies) {
            watchMoviesList = watchMoviesList.filter({
                let bool = ($0.id != movie.id)
                if !bool {
                    MVClient.sharedInstance.sharedContext.delete($0)
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
    
    func fetchMovies(_ id: NSNumber) -> [Movie] {
        
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Movie")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id);
        
        // Execute the Fetch Request
        do {
            return try MVClient.sharedInstance.sharedContext.fetch(fetchRequest) as! [Movie]
        } catch _ {
            return [Movie]()
        }
    }

}

extension WatchListViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return watchMoviesList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        /* Get cell type */
        let cellReuseIdentifier = "WatchlistCell"
        let movie = watchMoviesList[indexPath.row]
        print("movie: ", movie)
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! WatchListTableViewCell!
        
        /* Set cell defaults */
        if ((movie.releaseYear) != nil) {
            cell?.movieTitle.text = "\(movie.title) (\(movie.releaseYear!))"
        }
        
        cell?.movieWatched.tag = indexPath.row
        cell?.movieWatched.addTarget(self, action: #selector(WatchListViewController.watchedMovie(_:)), for: .touchUpInside)
        
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
            stopAndHideSpinner(cell!)
            cell?.moviePoster.image = localImage
        } else if movie.posterPath == nil || movie.posterPath == "" {
            cell?.moviePoster.image = UIImage(named: "Film")
            stopAndHideSpinner(cell!)
        } else {
            if let posterPath = movie.posterPath {
                MVClient.sharedInstance.taskForGETImage(posterSizes[2], filePath: posterPath, completionHandler: { (imageData, error) in
                    if let image = UIImage(data: imageData!) {
                        movie.image = image
                        DispatchQueue.main.async {
                            self.stopAndHideSpinner(cell!)
                            cell?.moviePoster!.image = image
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.stopAndHideSpinner(cell!)
                            self.showAlertView((error?.description)!)
                        }
                        print(error)
                    }
                })
            }
        }
        
        return cell!
    }
    
    func stopAndHideSpinner(_ cell: WatchListTableViewCell) {
        cell.spinner.stopAnimating()
        cell.spinner.isHidden = true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch (editingStyle) {
        case .delete:
            let movie = watchMoviesList[indexPath.row]
            deleteWatchedListMovies(movie, indexPath: indexPath, addToWatchedListMovies: false, sender: nil)
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /* Push the movie detail view */
        watchListTableView.deselectRow(at: indexPath, animated: true)
        let controller = storyboard!.instantiateViewController(withIdentifier: "MovieDetailViewController") as! MovieDetailViewController
        controller.movie = watchMoviesList[indexPath.row]
        navigationController!.pushViewController(controller, animated: true)
    }
    
}
