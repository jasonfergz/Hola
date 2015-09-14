//
//  FileManager.swift
//  Hola
//
//  Created by Pritesh Shah on 9/14/15.
//  Copyright © 2015 Magnet Systems, Inc. All rights reserved.
//

import Foundation

class FileManager {
    
    static let sharedInstance: FileManager = {
        return FileManager()
    }()
    
    func documentsDirectory() -> String {
        let documentsFolderPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]
        return documentsFolderPath
    }
    
    func fileInDocumentsDirectory(filename: String) -> String {
        return (NSURL(string: documentsDirectory())?.URLByAppendingPathComponent(filename).absoluteString)!
    }
}
