//
//  ServerConfiguration.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 17.05.2022.
//

import Foundation
import CSSystemInfoHelper




//let ChromeCastImageURL = URL(string: "http://localhost:\(Port.app.rawValue)/image")

class ServerConfiguration {
    
    static let shared = ServerConfiguration()
    
    
    private init(){}
    
    func deviceIPAddress() -> String {
        guard let networkInterfaces = CSSystemInfoHelper.shared.networkInterfaces else { return ""}
        guard let interface = networkInterfaces.filter({ $0.name == "en0" && $0.familyName == "AF_INET" }).first else { return ""}
        return interface.address
    }
    
}


