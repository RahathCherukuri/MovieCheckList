//
//  Result.swift
//  MovieCheckList
//
//  Created by Rahath cherukuri on 7/9/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import Foundation

enum Result<T, E> {
    case success(T: AnyObject)
    case failure(E: AppError)
}
