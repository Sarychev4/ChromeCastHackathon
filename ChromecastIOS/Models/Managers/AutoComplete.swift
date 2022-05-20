//
//  AutoComplete.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 20.05.2022.
//

import Foundation

public enum AutoCompleteError: Error {
    case invalidURL(String)
    case invalidData(String)
    case failedToRetrieveData(String)
    case failToDecodeData(String)
    case serializationError(String)
}

public class AutoComplete {
    
    static let baseURL = "http://suggestqueries.google.com/complete/search?client=youtube&ds=yt&alt=json&q="
 
    public static func getQuerySuggestions(_ term: String, completionHandler: @escaping ([String]?, Error?) -> Void) -> Void {
        DispatchQueue.global().async {
            let URLString = baseURL + term
            
            guard let url = URL(string: URLString) else {
                DispatchQueue.main.async {
                    completionHandler(nil, AutoCompleteError.invalidURL(URLString))
                }
                return
            }
            
            let sessionConfiguration = URLSessionConfiguration.default
            sessionConfiguration.urlCache = nil
            sessionConfiguration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            let session = URLSession(configuration: sessionConfiguration)
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "GET"
//            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let task = session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
                guard let data = data, let response = String(data: data, encoding: String.Encoding.ascii) else {
                    DispatchQueue.main.async {
                        completionHandler(nil, AutoCompleteError.failToDecodeData(URLString))
                    }
                    return
                }
                
                var JSON: NSString?
                let scanner = Scanner(string: response)
                
                scanner.scanUpTo("[[", into: nil) // Scan to where the JSON begins
                scanner.scanUpTo(",{", into:  &JSON)
                
                guard JSON != nil else {
                    DispatchQueue.main.async {
                        completionHandler(nil, AutoCompleteError.failedToRetrieveData(URLString))
                    }
                    return
                }
                
                //The idea is to identify where the "real" JSON begins and ends.
                JSON = NSString(format: "%@", JSON!)
                
                do {
                    let array = try JSONSerialization.jsonObject(with: JSON!.data(using: String.Encoding.utf8.rawValue) ?? Data(), options: .allowFragments)
                    var result = [String]()
                    
                    for i in 0 ..< (array as AnyObject).count {
                        for j in 0 ..< 1 {
                            let suggestion = ((array as AnyObject).object(at: i) as AnyObject).object(at: j)
                            if let str = suggestion as? String {
                                result.append(str)
                            }
                        }
                    }
                    DispatchQueue.main.async(execute: {
                        completionHandler(result,nil)
                    })
                }
                catch {
                    DispatchQueue.main.async(execute: {
                        completionHandler(nil, AutoCompleteError.serializationError(URLString))
                    })
                }
            })
            task.resume()
            session.finishTasksAndInvalidate()
        }
    }
}
