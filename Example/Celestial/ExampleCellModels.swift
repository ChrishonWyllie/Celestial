//
//  ExampleCellModels.swift
//  Celestial
//
//  Created by Chrishon Wyllie on 1/2/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation


protocol ExampleCellModel {
    var urlString: String { get }
}





struct VideoCellModel: ExampleCellModel {
    private(set) var urlString: String
    // Other Video-specific properties TBD
    
    init(urlString: String) {
        self.urlString = urlString
    }
}





struct ImageCellModel: ExampleCellModel {
    private(set) var urlString: String
    // Other Image-specific properties TBD
    
    init(urlString: String) {
        self.urlString = urlString
    }
}

