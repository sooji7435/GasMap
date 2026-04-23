//
//  StationSearchResult.swift
//  GasMap
//
//  Created by 박윤수 on 4/23/26.
//

// StationSearchResult.swift
import Foundation

struct StationSearchResponse: Codable {
    let result: StationSearchResult2

    enum CodingKeys: String, CodingKey {
        case result = "RESULT"
    }

    struct StationSearchResult2: Codable {
        let stations: [StationSearchResult]

        enum CodingKeys: String, CodingKey {
            case stations = "OIL"
        }
    }
}

struct StationSearchResult: Codable, Identifiable {
    let id: String
    let name: String
    let address: String
    let katecX: Double
    let katecY: Double
    
    enum CodingKeys: String, CodingKey {
        case id = "UNI_ID"
        case name = "OS_NM"
        case address = "NEW_ADR"
        case katecX = "GIS_X_COOR"
        case katecY = "GIS_Y_COOR"
    }
}
