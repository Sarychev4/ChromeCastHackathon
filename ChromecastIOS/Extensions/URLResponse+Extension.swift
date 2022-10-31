//
//  URLResponse+Extension.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 31.10.2022.
//

import Foundation

public extension URLResponse {
 
    var isSuccess: Bool {
        get {
            guard let HTTPURLResponse = self as? HTTPURLResponse else {
                return false
            }
            
            if HTTPURLResponse.statusCode >= 400 && HTTPURLResponse.statusCode < 500 {
                return false
            }
            
            if HTTPURLResponse.statusCode < 200 || HTTPURLResponse.statusCode > 206 {
                return false
            }
            
            return true
        }
    }
}
