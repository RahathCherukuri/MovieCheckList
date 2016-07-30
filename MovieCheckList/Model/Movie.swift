//
//  Movie.swift
//  MovieCheckList
//
//  Created by Rahath cherukuri on 7/11/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import Foundation
import UIKit

struct Movie {
    
    // MARK: Properties
    
    var title = ""
    var id = 0
    var watched: Bool? = nil
    var posterPath: String? = nil
    var releaseYear: String? = nil
    var originalLanguage: String? = nil
    var overview: String? = nil
    var tagline: String? = nil
    var rating: Float? = nil
    var runTime: Float? = nil
    var genres: String? = nil

    
    // MARK: Initializers
    
    /* Construct a TMDBMovie from a dictionary */
    init(dictionary: [String : AnyObject]) {
        
        title = dictionary[MVClient.JSONResponseKeys.MovieTitle] as! String
        id = dictionary[MVClient.JSONResponseKeys.MovieID] as! Int
        watched = dictionary[MVClient.JSONResponseKeys.MovieWatched] as? Bool
        posterPath = dictionary[MVClient.JSONResponseKeys.MoviePosterPath] as? String
        
        if let releaseDateString = dictionary[MVClient.JSONResponseKeys.MovieReleaseDate] as? String {
            
            if releaseDateString.isEmpty == false {
                releaseYear = releaseDateString.substringToIndex(releaseDateString.startIndex.advancedBy(4))
            } else {
                releaseYear = ""
            }
        }
        var genresArray: [String] = []
        
        if let movieGenres = dictionary["genres"] as? NSArray{
            _ = movieGenres.map({
                let name = $0["name"] as? String
                genresArray.append(name!)
            })
            genres = getCommaSeperatedGenres(genresArray)
        }
        
        originalLanguage = dictionary[MVClient.JSONResponseKeys.MovieOriginalLanguage] as? String
        overview = dictionary[MVClient.JSONResponseKeys.MovieOverview] as? String
        tagline = dictionary["tagline"] as? String
        rating = dictionary[MVClient.JSONResponseKeys.MovieRating] as? Float
        runTime = dictionary["runtime"] as? Float
    }
    
    var image: UIImage? {
        get { return MVClient.Caches.imageCache.imageWithIdentifier(String(id)) }
        set { MVClient.Caches.imageCache.storeImage(newValue, withIdentifier: String(id)) }
    }

//  Helper Functions
    
    func getHoursAndMinutes(runTime: Float)-> String {
        let hours: Int = Int(runTime)/60
        let minutes: Int = Int(runTime)%60
        let hoursAndMinutes: String = (minutes == 0) ? "\(hours) hours" : "\(hours)h \(minutes)m"
        return hoursAndMinutes
    }
    
    func getCommaSeperatedGenres(movieGenres: [String])-> String {
        return movieGenres.joinWithSeparator(",")
    }
    
}


