//
//  Movie.swift
//  MovieCheckList
//
//  Created by Rahath cherukuri on 7/11/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import UIKit
import CoreData

class Movie: NSManagedObject {
    
    // MARK: Properties
    
    @NSManaged var title:String
    @NSManaged var id: NSNumber // Int
    @NSManaged var watched: NSNumber? //Bool
    @NSManaged var posterPath: String?
    @NSManaged var releaseYear: String?
    @NSManaged var originalLanguage: String?
    @NSManaged var overview: String?
    @NSManaged var tagline: String?
    @NSManaged var rating: NSNumber? // Float
    @NSManaged var runTime: NSNumber? // Float
    @NSManaged var genres: String?
    
    // MARK: Initializers
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    /* Construct a TMDBMovie from a dictionary */
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Movie", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
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
    
    var detailImage: UIImage? {
        get {return MVClient.Caches.imageCache.imageWithIdentifier((String(id) + "detail"))}
        set { MVClient.Caches.imageCache.storeImage(newValue, withIdentifier: (String(id) + "detail")) }
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


