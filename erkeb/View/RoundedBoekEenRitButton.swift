//
//  RoundedBoekEenRitButton.swift
//  erkeb
//
//  Created by Ismail on 26/04/2019.
//  Copyright © 2019 Ismail Abes. All rights reserved.
//

import UIKit

class RoundedBoekEenRitButton: UIButton {
    
    //huidige button grootte
    var originalSize: CGRect?
    
    override func awakeFromNib() {
        setupView()
    }
    
    func setupView(){
        originalSize = self.frame
        self.layer.cornerRadius = 5.0
        self.layer.shadowOpacity = 0.2
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowRadius = 5.0
        self.layer.shadowOffset = CGSize(width: 0, height: 5)
    }
    
    func animateButton(shouldLoad: Bool, withMessage message: String?){
        
        let spinner = UIActivityIndicatorView()
        spinner.style = .whiteLarge
        spinner.color = UIColor.white
        spinner.alpha = 0.0
        spinner.hidesWhenStopped = true
        spinner.tag = 21
        
        if shouldLoad{
            self.addSubview(spinner)
            self.setTitle("", for: .normal)
            UIView.animate(withDuration: 0.2, animations: {
                self.layer.cornerRadius = self.frame.height / 2
                self.frame = CGRect(x: self.frame.midX - (self.frame.height / 2), y: self.frame.origin.y, width: self.frame.height, height: self.frame.height)
            }, completion: {(finished) in
                if finished == true {
                    spinner.startAnimating()
                    spinner.center = CGPoint(x: self.frame.width / 2 + 1, y: self.frame.width / 2 + 1)
                    UIView.animate(withDuration: 0.2, animations: {
                        spinner.alpha = 1.0
                    })
                }
            })
            self.isUserInteractionEnabled = false
        }else{
            self.isUserInteractionEnabled = true
            for subview in self.subviews{
                if subview.tag == 21{
                  subview.removeFromSuperview()
                }
            }
            UIView.animate(withDuration: 0.2, animations: {
                self.layer.cornerRadius = 5.0
                self.frame = self.originalSize!
                self.setTitle(message, for: .normal)
            })
        }
    }

}
