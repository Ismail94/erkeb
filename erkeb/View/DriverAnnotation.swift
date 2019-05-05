//
//  DriverAnnotation.swift
//  erkeb
//
//  Created by Ismail on 04/05/2019.
//  Copyright © 2019 Ismail Abes. All rights reserved.
//

import Foundation
import MapKit

class DriverAnnotation: NSObject, MKAnnotation{
    dynamic var coordinate: CLLocationCoordinate2D
    var key: String
    
    init(coordinate: CLLocationCoordinate2D, withKey key: String){
        self.coordinate = coordinate
        self.key = key
        super.init()
    }
    
    func update(annotationPostition annotation: DriverAnnotation, withCoordinate coordinate: CLLocationCoordinate2D){
        var location = self.coordinate
        location.latitude = coordinate.latitude
        location.longitude = coordinate.longitude
        UIView.animate(withDuration: 0.2) {
            self.coordinate = location
        }
    }
}
