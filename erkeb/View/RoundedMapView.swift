//
//  RoundedMapView.swift
//  erkeb
//
//  Created by Ismail on 11/05/2019.
//  Copyright © 2019 Ismail Abes. All rights reserved.
//

import UIKit
import MapKit

class RoundedMapView: MKMapView {
    
    override func awakeFromNib() {
        setupView()
    }

    func setupView() {
        self.layer.cornerRadius = self.frame.width / 2
        self.layer.borderColor = UIColor.init(red: 47, green: 40, blue: 1.0, alpha: 1.0).cgColor
        self.layer.borderWidth = 10.0
    }

}
