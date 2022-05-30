//
//  GoogleDriveAPI.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 14.05.2022.
//

import Foundation
import GoogleAPIClientForREST
import CryptoKit

class GoogleDriveAPI {
    private let service: GTLRDriveService
    
    init(service: GTLRDriveService) {
        self.service = service
    }
    
    public func search(_ name: String, onCompleted: @escaping (GTLRDrive_File?, Error?) -> ()) {
        let query = GTLRDriveQuery_FilesList.query()
        query.pageSize = 1
        query.q = "name contains '\(name)'"
        self.service.executeQuery(query) { (ticket, results, error) in
            onCompleted((results as? GTLRDrive_FileList)?.files?.first, error)
        }
    }
    
    public func allFilesAndFolders(onCompleted: @escaping (GTLRDrive_FileList?, Error?) -> ()) {
        let query = GTLRDriveQuery_FilesList.query()
        query.fields = "files(id,name,mimeType,modifiedTime,iconLink,thumbnailLink,contentHints,fileExtension,webContentLink,webViewLink,imageMediaMetadata,exportLinks,size),nextPageToken"
        self.service.executeQuery(query) { (ticket, result, error) in
            onCompleted(result as? GTLRDrive_FileList, error)
        }
    }
    
    public func listFiles(_ folderID: String, onCompleted: @escaping (GTLRDrive_FileList?, Error?) -> ()) {
        let query = GTLRDriveQuery_FilesList.query()
        query.pageSize = 100
        query.fields = "files(id,name,mimeType,modifiedTime,iconLink,thumbnailLink,contentHints,fileExtension,webContentLink,webViewLink,imageMediaMetadata,exportLinks,size),nextPageToken"
        query.q = "'\(folderID)' in parents"// and trashed=false" // and mimeType = 'application/vnd.google-apps.folder'"
        query.orderBy = "folder"
        self.service.executeQuery(query) { (ticket, result, error) in
            onCompleted(result as? GTLRDrive_FileList, error)
            
        }
    }
    
    public func download(_ fileItem: GTLRDrive_File, onCompleted: @escaping (Data?, Error?) -> ()) {
        guard let fileID = fileItem.identifier else {
            return onCompleted(nil, nil)
        }
        
        self.service.executeQuery(GTLRDriveQuery_FilesGet.queryForMedia(withFileId: fileID)) { (ticket, file, error) in
            guard let data = (file as? GTLRDataObject)?.data else {
                return onCompleted(nil, nil)
            }
            
            onCompleted(data, nil)
        }
    }
    
    public func shareFile(_ file: GTLRDrive_File, onCompleted: @escaping (Error?) -> ()) {
        guard let fileId = file.identifier else { return }
        let anyOne = GTLRDrive_Permission()
        anyOne.type = "anyone"
        anyOne.role = "reader"
        let query = GTLRDriveQuery_PermissionsCreate.query(withObject: anyOne, fileId: fileId)
        self.service.executeQuery(query) { (ticket, result, error) in
            onCompleted(error)
        }
    }
    
    private func upload(_ folderID: String, fileName: String, data: Data, MIMEType: String, onCompleted: ((String?, Error?) -> ())?) {
        let file = GTLRDrive_File()
        file.name = fileName
        file.parents = [folderID]
        
        let params = GTLRUploadParameters(data: data, mimeType: MIMEType)
        params.shouldUploadWithSingleRequest = true
        
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: params)
        query.fields = "id"
        
        self.service.executeQuery(query, completionHandler: { (ticket, file, error) in
            onCompleted?((file as? GTLRDrive_File)?.identifier, error)
        })
    }
    
    public func delete(_ fileItem: GTLRDrive_File, onCompleted: @escaping ((Error?) -> ())) {
        guard let fileID = fileItem.identifier else {
            return onCompleted(nil)
        }
        
        self.service.executeQuery(GTLRDriveQuery_FilesDelete.query(withFileId: fileID)) { (ticket, nilFile, error) in
            onCompleted(error)
        }
    }
}
