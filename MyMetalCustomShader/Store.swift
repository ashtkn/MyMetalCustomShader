//
//  Data.swift
//  MyMetalCustomShader
//
//  Created by 竹ノ内朝陽 on 2020/04/09.
//  Copyright © 2020 竹ノ内朝陽. All rights reserved.
//

import UIKit

class Store {
    
    private init() {}
    static let `default` = Store()
    
    let vertexData: [Float] = [
        -1, -1, 0, 1,
         1, -1, 0, 1,
        -1,  1, 0, 1,
         1,  1, 0, 1
    ]
    
    let resolutionData: [Float] = [
        Float(UIScreen.main.nativeBounds.size.width),
        Float(UIScreen.main.nativeBounds.size.height)
    ]
}
