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
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    /* Construct a Movie from a dictionary */
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entity(forEntityName: "Movie", in: context)!
        super.init(entity: entity, insertInto: context)
        
        title = dictionary[MVClient.JSONResponseKeys.MovieTitle] as! String
        id = NSNumber(value: (dictionary[MVClient.JSONResponseKeys.MovieID] as? Int)!)
        watched = dictionary[MVClient.JSONResponseKeys.MovieWatched] as? Bool as NSNumber?
        posterPath = dictionary[MVClient.JSONResponseKeys.MoviePosterPath] as? String
        
        if let releaseDateString = dictionary[MVClient.JSONResponseKeys.MovieReleaseDate] as? String {
            
            if releaseDateString.isEmpty == false {
                releaseYear = releaseDateString.substring(to: releaseDateString.characters.index(releaseDateString.startIndex, offsetBy: 4))
            } else {
                releaseYear = ""
            }
        }
//        var genresArray: [String] = []
        
//        if let movieGenres = dictionary["genres"] as? NSArray{
//            _ = movieGenres.map({
//                let movieGenre = $0 as? [String:AnyObject]
//                let name = movieGenre.
//                genresArray.append((name! as? String)!)
//            })
//            genres = getCommaSeperatedGenres(genresArray)
//        }
        genres = nil
        originalLanguage = dictionary[MVClient.JSONResponseKeys.MovieOriginalLanguage] as? String
        overview = dictionary[MVClient.JSONResponseKeys.MovieOverview] as? String
        tagline = dictionary["tagline"] as? String
        rating = dictionary[MVClient.JSONResponseKeys.MovieRating] as? Float as NSNumber?
        runTime = dictionary["runtime"] as? Float as NSNumber?
    }
    
    override func prepareForDeletion() {
        image = nil
        detailImage = nil
    }
    
    var image: UIImage? {
        get { return MVClient.Caches.imageCache.imageWithIdentifier(String(describing: id)) }
        set { MVClient.Caches.imageCache.storeImage(newValue, withIdentifier: String(describing: id)) }
    }
    
    var detailImage: UIImage? {
        get {return MVClient.Caches.imageCache.imageWithIdentifier((String(describing: id) + "detail"))}
        set { MVClient.Caches.imageCache.storeImage(newValue, withIdentifier: (String(describing: id) + "detail")) }
    }

//  Helper Functions
    
    func getHoursAndMinutes(_ runTime: Float)-> String {
        let hours: Int = Int(runTime)/60
        let minutes: Int = Int(runTime)%60
        let hoursAndMinutes: String = (minutes == 0) ? "\(hours) hours" : "\(hours)h \(minutes)m"
        return hoursAndMinutes
    }
    
    func getCommaSeperatedGenres(_ movieGenres: [String])-> String {
        return movieGenres.joined(separator: ",")
    }
    
}


