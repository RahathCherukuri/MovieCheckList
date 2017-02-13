//
//  ImageCache.swift
//  MovieCheckList
//
//  Created by Rahath cherukuri on 5/21/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import UIKit

class ImageCache {

    fileprivate var inMemoryCache = NSCache<AnyObject, AnyObject>()

    // MARK: - Retreiving images

    func imageWithIdentifier(_ identifier: String?) -> UIImage? {

        // If the identifier is nil, or empty, return nil
        if identifier == nil || identifier! == "" {
            return nil
        }

        let path = pathForIdentifier(identifier!)

        // First try the memory cache
        if let image = inMemoryCache.object(forKey: path as AnyObject) as? UIImage {
            return image
        }

        // Next Try the hard drive
        if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            return UIImage(data: data)
        }

        return nil
    }

    // MARK: - Saving images

    func storeImage(_ image: UIImage?, withIdentifier identifier: String) {
        let path = pathForIdentifier(identifier)

        // If the image is nil, remove images from the cache
        if image == nil {
            inMemoryCache.removeObject(forKey: path as AnyObject)

            do {
                try FileManager.default.removeItem(atPath: path)
            } catch _ {}

            return
        }

        // Otherwise, keep the image in memory
        inMemoryCache.setObject(image!, forKey: path as AnyObject)

        // And in documents directory
        let data = UIImagePNGRepresentation(image!)!
        try? data.write(to: URL(fileURLWithPath: path), options: [.atomic])
    }

    // MARK: - Helper

    func pathForIdentifier(_ identifier: String) -> String {
        let documentsDirectoryURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fullURL = documentsDirectoryURL.appendingPathComponent(identifier)

        return fullURL.path
    }
}
