//
//  UIViewExt.swift
//  erkeb
//
//  Created by Ismail on 27/04/2019.
//  Copyright © 2019 Ismail Abes. All rights reserved.
//

import UIKit

extension UIView{
    func fadeTo(alphaValue: CGFloat, withDuration duration: TimeInterval){
        UIView.animate(withDuration: duration) {
            self.alpha = alphaValue
        }
    }
}
