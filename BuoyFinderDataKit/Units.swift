//
//  Units.swift
//  BuoyFinder
//
//  Created by Matthew Iannucci on 12/10/16.
//  Copyright © 2016 Matthew Iannucci. All rights reserved.
//

import Foundation

public enum Measurement: String {
    case length = "length"
    case speed = "speed"
    case temperature = "temperature"
    case pressure = "pressure"
    case visibility = "visibility"
    case degrees = "degrees"
}

public enum Units: String {
    case metric = "metric"
    case english = "english"
    
    public func string(meas: Measurement) -> String {
        switch self {
        case .metric:
            switch meas {
            case .length:
                return "m"
            case .speed:
                return "m/s"
            case .temperature:
                return "°c"
            case .pressure:
                return "hPa"
            case .visibility:
                return "nmi"
            case .degrees:
                return "°"
            }
        case .english:
            switch meas {
            case .length:
                return "ft"
            case .speed:
                return "mph"
            case .temperature:
                return "°F"
            case .pressure:
                return "inHG"
            case .visibility:
                return "nmi"
            case .degrees:
                return "°"
            }
        }
    }
    
    public func earthRadius() -> Double {
        switch self {
        case .metric:
            return 6373
        case .english:
            return 3961
        }
    }
    
    static public func convert(meas: Measurement, sourceUnit: Units, destUnit: Units, value: Double) -> Double {
        if sourceUnit == destUnit {
            return value
        }
        
        switch meas {
        case .length:
            switch sourceUnit {
            case .metric:
                switch destUnit {
                case .english:
                    return value * 3.28
                default:
                    return value
                }
            case .english:
                switch destUnit {
                case .metric:
                    return value / 3.28
                default:
                    return value
                }
            }
        case .speed:
            switch sourceUnit {
            case .metric:
                switch destUnit {
                case .english:
                    return value * 2.237
                default:
                    return value
                }
            case .english:
                switch destUnit {
                case .metric:
                    return value / 2.237
                default:
                    return value
                }
            }
        case .temperature:
            switch sourceUnit {
            case .metric:
                switch destUnit {
                case .english:
                    return (value * (9.0/5.0)) + 32.0
                default:
                    return value
                }
            case .english:
                switch destUnit {
                case .metric:
                    return (value - 32.0) * (5.0/9.0)
                default:
                    return value
                }
            }
        case .pressure:
            switch sourceUnit {
            case .metric:
                switch destUnit {
                case .english:
                    return value / 33.8638
                default:
                    return value
                }
            case .english:
                switch destUnit {
                case .metric:
                    return value * 33.8638
                default:
                    return value
                }
            }
        default:
            return value
        }
    }
    
    static public func degreesToDirection(deg: Double) -> String {
        let wind_directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "S", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        if deg > 360 || deg < 0 {
            return "NULL"
        }
        
        var wind_index: Int = Int((deg+11.25)/22.5 - 0.02)
        if wind_index >= wind_directions.count {
            wind_index = 0
        }
        return wind_directions[wind_index%wind_directions.count]
    }
}

protocol UnitsProtocol {
    mutating func convert(sourceUnits: Units, destUnits: Units)
}
