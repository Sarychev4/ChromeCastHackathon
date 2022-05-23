//
//  HTTPServer.swift
//  ScreenMirroring
//
//  Created by Vital on 12.11.21.
//

import Foundation
import Criollo
import UIKit
    
class HTTPServer: NSObject {
    private var htmlServer = CRHTTPServer()
    private var responseWaitDataClosure: ((Data) -> Void)?
    private var operationsQueue: OperationQueue {
        let queue = OperationQueue()
        queue.qualityOfService = .default
        queue.maxConcurrentOperationCount = 1 // Не менять! Сервер должен выполнять одну операцию иначе постоянно рвется connection c клиентом и из-за реконнектов стрим лагает.
//        let workerQueue = DispatchQueue(label: "com.html.server.broadcast", qos: .userInitiated)
//        queue.underlyingQueue = workerQueue
        return queue
    }

    func start() {
        htmlServer.delegate = self
        htmlServer.workerQueue = operationsQueue
          
        //Отдаём этой html последнюю картинку со стрима
        htmlServer.get("/screenmirror") { [weak self] (req, res, next) in
            guard let self = self else { return }
            let semaphore = DispatchSemaphore(value: 0)
            self.responseWaitDataClosure = { data in
                res.setAllHTTPHeaderFields(["Content-Type": "image/jpeg",
                                            "Content-Length": "\(data.count)"])
                res.send(data)
                semaphore.signal()
            }
            semaphore.wait()
            self.responseWaitDataClosure = nil
        }
         

        var serverError: NSError?
        let htmlStreamPort: UInt = Port.htmlStreamPort.rawValue
        if htmlServer.startListening(&serverError, portNumber: htmlStreamPort) {
            print(">>> run http server")
        } else {
            print(">>> Start server failed!!!!! Error: \(serverError?.localizedDescription ?? "")")
        }
    }
    
    func send(_ data: Data) {
        if let responseWaitDataClosure = responseWaitDataClosure {
            responseWaitDataClosure(data)
        }
    }
}

extension HTTPServer: CRServerDelegate {
    func serverDidStartListening(_ server: CRServer) { }

    func serverDidStopListening(_ server: CRServer) { }

    func server(_ server: CRServer, didAccept connection: CRConnection) {
        print(">>> didAccept connection: \(connection.remoteAddress):\(connection.remotePort)")
    }

    func server(_ server: CRServer, didClose connection: CRConnection) {
        print(">>> didClose connection")
    }

    func server(_ server: CRServer, didReceive request: CRRequest) {
//        print(">>> didReceive request")
    }

    func server(_ server: CRServer, didFinish request: CRRequest) {
//        print(">>> didFinish request")
    }
}
