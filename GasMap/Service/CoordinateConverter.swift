//
//  CoordinateConverter.swift
//  GasMap
//
//  Created by 박윤수 on 4/23/26.
//

import Foundation
import CoreLocation

enum CoordinateConverter {
    static func katecToWGS84(x: Double, y: Double) -> CLLocationCoordinate2D {
        let d2r = Double.pi / 180.0
        let r2d = 180.0 / Double.pi
        let k0 = 0.9996
        let a = 6378137.0
        let f = 1 / 298.257223563
        let b = a * (1 - f)
        let e2 = (a*a - b*b) / (a*a)
        let x0 = 400000.0; let y0 = 600000.0
        let lon0 = 128.0 * d2r; let lat0 = 38.0 * d2r
        let e1 = (1 - sqrt(1 - e2)) / (1 + sqrt(1 - e2))
        let m0 = a * ((1 - e2/4 - 3*e2*e2/64) * lat0 - (3*e2/8 + 3*e2*e2/32) * sin(2*lat0) + (15*e2*e2/256) * sin(4*lat0))
        let m = m0 + (y - y0) / k0
        let mu = m / (a * (1 - e2/4 - 3*e2*e2/64))
        let phi1 = mu + (3*e1/2 - 27*pow(e1,3)/32) * sin(2*mu) + (21*e1*e1/16) * sin(4*mu)
        let n1 = a / sqrt(1 - e2 * sin(phi1) * sin(phi1))
        let t1 = tan(phi1) * tan(phi1)
        let c1 = e2 / (1 - e2) * cos(phi1) * cos(phi1)
        let r1 = a * (1 - e2) / pow(1 - e2 * sin(phi1) * sin(phi1), 1.5)
        let d = (x - x0) / (n1 * k0)
        let lat = phi1 - (n1 * tan(phi1) / r1) * (d*d/2 - (5 + 3*t1 + 10*c1 - 4*c1*c1) * pow(d,4)/24)
        let lon = lon0 + (d - (1 + 2*t1 + c1) * pow(d,3)/6) / cos(phi1)
        
        return CLLocationCoordinate2D(latitude: lat * r2d, longitude: lon * r2d)
    }
    
    static func convertWGS84ToKATEC(lat: Double, lon: Double) -> (x: Double, y: Double) {
        let d2r = Double.pi / 180.0
        let lat_rad = lat * d2r
        let lon_rad = lon * d2r
        
        let k0 = 0.9996
        let a = 6378137.0
        let f = 1 / 298.257223563
        let b = a * (1 - f)
        let e2 = (a*a - b*b) / (a*a)
        
        let lon0 = 128.0 * d2r
        let lat0 = 38.0 * d2r
        let x0 = 400000.0
        let y0 = 600000.0
        
        let n = a / sqrt(1 - e2 * sin(lat_rad) * sin(lat_rad))
        let t = tan(lat_rad) * tan(lat_rad)
        let c = e2 / (1 - e2) * cos(lat_rad) * cos(lat_rad)
        let m = a * ((1 - e2/4 - 3*e2*e2/64) * lat_rad - (3*e2/8 + 3*e2*e2/32) * sin(2*lat_rad) + (15*e2*e2/256) * sin(4*lat_rad))
        let m0 = a * ((1 - e2/4 - 3*e2*e2/64) * lat0 - (3*e2/8 + 3*e2*e2/32) * sin(2*lat0) + (15*e2*e2/256) * sin(4*lat0))
        
        let a_val = (lon_rad - lon0) * cos(lat_rad)
        let x = x0 + k0 * n * (a_val + (1-t+c) * a_val*a_val*a_val/6 + (5-18*t+t*t+72*c) * a_val*a_val*a_val*a_val*a_val/120)
        let y = y0 + k0 * (m - m0 + n * tan(lat_rad) * (a_val*a_val/2 + (5-t+9*c+4*c*c) * a_val*a_val*a_val*a_val/24 + (61-58*t+t*t+600*c) * a_val*a_val*a_val*a_val*a_val*a_val/720))
        
        return (x, y)
    }
}
