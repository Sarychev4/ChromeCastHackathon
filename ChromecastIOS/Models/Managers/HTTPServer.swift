//
//  HTTPServer.swift
//  ScreenMirroring
//
//  Created by Vital on 12.11.21.
//

import Foundation
import Criollo
import UIKit
import GCDWebServer
    
class HTTPServer: NSObject {
    private var htmlServer = CRHTTPServer()
    private var httpServer: GCDWebServer?
    private var responseWaitDataClosure: ((Data) -> Void)?

    func start() {
        GCDWebServer.setLogLevel(4)
        let htmlStreamPort: UInt = Port.htmlStreamPort.rawValue
        httpServer = GCDWebServer()

        httpServer?.addHandler(forMethod: "GET", path: "/screenmirror", request: GCDWebServerRequest.self, asyncProcessBlock: { [weak self] request, completion in
            guard let self = self else { return }
            let semaphore = DispatchSemaphore(value: 0)
            self.responseWaitDataClosure = { data in
                let response = GCDWebServerDataResponse(data: data, contentType: "image/jpeg")
                completion(response)
                semaphore.signal()
            }
            semaphore.wait()
            self.responseWaitDataClosure = nil
        })
        try! httpServer?.start(options:  [GCDWebServerOption_AutomaticallySuspendInBackground: false, GCDWebServerOption_Port: htmlStreamPort])
        print(">>> start on port: \(String(describing: httpServer?.serverURL?.absoluteString))")
    }
    
    func send(_ data: Data) {
        if let responseWaitDataClosure = responseWaitDataClosure {
            responseWaitDataClosure(data)
        }
    }
}
