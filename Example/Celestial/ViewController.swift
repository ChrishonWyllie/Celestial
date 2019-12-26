//
//  ViewController.swift
//  Celestial
//
//  Created by ChrishonWyllie on 12/25/2019.
//  Copyright (c) 2019 ChrishonWyllie. All rights reserved.
//

import UIKit
import Celestial

class ViewController: UIViewController {
    
    private lazy var imageView: URLImageView = {
        let img = URLImageView(delegate: self)
        img.translatesAutoresizingMaskIntoConstraints = false
        img.contentMode = .scaleAspectFill
        img.layer.cornerRadius = 10
        img.clipsToBounds = true
        img.backgroundColor = .darkGray
        return img
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        Celestial.shared.store(<#T##image: UIImage?##UIImage?#>, with: <#T##String#>)
        setupUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
    private func setupUI() {
        view.addSubview(imageView)
        
        imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 200).isActive = true
        
        
        let urlString = "https://picsum.photos/400/800/?random"
        imageView.loadImageFrom(urlString: urlString)
    }
}






// MARK: - URLImageView delegate

extension ViewController: URLImageViewDelegate {
    
    func urlImageView(_ view: URLImageView, downloadCompletedAt urlString: String) {
        print("download completed with url string: \(urlString)")
        print("image has been cached?: \(view.cachePolicy == .allow)")
    }
    
    func urlImageView(_ view: URLImageView, downloadFailedWith error: Error) {
        print("downlaod failed with error: \(error)")
    }
    
    func urlImageView(_ view: URLImageView, downloadProgress progress: CGFloat, humanReadableProgress: String) {
        print("download progress: \(progress)")
        print("human readable download progress: \(humanReadableProgress)")
    }
}
