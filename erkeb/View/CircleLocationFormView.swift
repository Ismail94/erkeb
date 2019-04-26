//
//  CircleLocationFormView.swift
//  erkeb
//
//  Created by Ismail on 26/04/2019.
//  Copyright © 2019 Ismail Abes. All rights reserved.
//

import UIKit

class CircleLocationFormView: UIView {

    override func awakeFromNib() {
        setupView()
    }
    
    func setupView(){
        self.layer.cornerRadius = self.frame.width / 2
        
    }

}
