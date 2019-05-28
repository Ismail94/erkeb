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
//        self.layer.shadowOpacity = 1
//        self.layer.shadowColor = UIColor.black.cgColor
//        self.layer.shadowRadius = 10.0
//        self.layer.shadowOffset = CGSize(width: 1, height: 10)
//        self.layer.borderColor = UIColor.init(red:0.95, green:0.95, blue:0.95, alpha:1.0).cgColor
//        self.layer.borderWidth = 5.0
    }

}
