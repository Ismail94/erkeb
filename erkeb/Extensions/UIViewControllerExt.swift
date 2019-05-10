//
//  UIViewControllerExt.swift
//  erkeb
//
//  Created by Ismail on 10/05/2019.
//  Copyright © 2019 Ismail Abes. All rights reserved.
//

import UIKit

extension UIViewController{
    func shouldShowLoadingView(_ status: Bool){
        var fadeView: UIView?
        //Hier maak ik de loading screen aan die te zien zal zijn nadat je een bestemming hebt gekozen
        if status == true{
            fadeView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
            fadeView?.backgroundColor = UIColor(red: 0.47, green: 0.40, blue: 1.0, alpha: 1.0)
            fadeView?.alpha = 0.0
            fadeView?.tag = 08
            
            let spinner = UIActivityIndicatorView()
            spinner.color = UIColor.white
            spinner.style = .whiteLarge
            spinner.center = view.center
            
            view.addSubview(fadeView!)
            fadeView?.addSubview(spinner)
            
            spinner.startAnimating()
            
            fadeView?.fadeTo(alphaValue: 0.7, withDuration: 0.2)
        } else{
            for subview in view.subviews {
                if subview.tag == 08 {
                    UIView.animate(withDuration: 0.2, animations: {
                        subview.alpha = 0.0
                    }) { (finished) in
                        subview.removeFromSuperview()
                    }
                }
            }
        }
    }
}
