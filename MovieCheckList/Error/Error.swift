//
//  Error.swift
//  MovieCheckList
//
//  Created by Rahath cherukuri on 7/9/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import Foundation

enum AppError: Error {
    case network(String)
    case parser(ParserData)
}

enum ParserData: String {
    case BadData = "Recieved BadData"
}
