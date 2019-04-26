//
//  RoundedLocationForm.swift
//  erkeb
//
//  Created by Ismail on 26/04/2019.
//  Copyright © 2019 Ismail Abes. All rights reserved.
//

import UIKit

class RoundedLocationForm: UIView {
    
    override func awakeFromNib() {
        setupView()
    }
    
    func setupView(){
        self.layer.cornerRadius = 5.0
        self.layer.shadowOpacity = 0.1
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowRadius = 5.0
        self.layer.shadowOffset = CGSize(width: 0, height: 7)
    }

}
