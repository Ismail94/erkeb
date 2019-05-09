//
//  PassengerAnnotation.swift
//  erkeb
//
//  Created by Ismail on 09/05/2019.
//  Copyright © 2019 Ismail Abes. All rights reserved.
//

import Foundation
import MapKit

class PassengerAnnotation: NSObject, MKAnnotation{
    //MKAnnotation eist dat dit dynamic is
    dynamic var coordinate: CLLocationCoordinate2D
    var key: String
    
    
    init(coordinate: CLLocationCoordinate2D, key: String){
        self.coordinate = coordinate
        self.key = key
        super.init()
    }
    
}
