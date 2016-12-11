//
//  Units.swift
//  BuoyFinder
//
//  Created by Matthew Iannucci on 12/10/16.
//  Copyright © 2016 Matthew Iannucci. All rights reserved.
//

import Foundation

enum Units: String {
    case Metric = "metric"
    case English = "english"
}

protocol UnitsProtocol {
    var units: Units { get set }
    mutating func convertToMetric()
    mutating func convertToEnglish()
}
