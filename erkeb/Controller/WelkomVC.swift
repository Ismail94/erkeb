//
//  WelkomVC.swift
//  erkeb
//
//  Created by Ismail on 25/05/2019.
//  Copyright © 2019 Ismail Abes. All rights reserved.
//

import UIKit

class WelkomVC: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var welkomBtn: UIButton!
    
    
    var images: [String] = ["ErkebTuto1", "ErkebTuto2", "ErkebTuto3"]
    var frame = CGRect(x: 0, y: 0, width: 0, height: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pageControl.numberOfPages = images.count
        
        for index in 0..<images.count {
            frame.origin.x = scrollView.frame.size.width * CGFloat(index)
            frame.size = scrollView.frame.size
            
            let imageView = UIImageView(frame: frame)
            imageView.image = UIImage(named: images[index])
            self.scrollView.addSubview(imageView)
        }
        
        scrollView.contentSize = CGSize(width: (scrollView.frame.size.width * CGFloat(images.count)), height: scrollView.frame.size.height)
        
        scrollView.delegate = self
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        var pageNummer = scrollView.contentOffset.x / scrollView.frame.size.width
        pageControl.currentPage = Int(pageNummer)
    }
    
    @IBAction func getBegin(_ sender: Any) {
        
        let userDefaults = UserDefaults.standard
        
        userDefaults.set(true, forKey: "WelkomIntroIsOk")
        userDefaults.synchronize()

    }
}



