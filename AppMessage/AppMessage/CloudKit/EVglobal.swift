//
//  EVglobal.swift
//
//  Created by Edwin Vermeer on 4/29/15.
//  Copyright (c) 2015. All rights reserved.
//

import Foundation

/**
Replacement function for NSLog that will also output the filename, linenumber and function name.

- parameter object: What you want to log
- parameter filename: Will be auto populated by the name of the file from where this function is called
- parameter line: Will be auto populated by the line number in the file from where this function is called
- parameter funcname: Will be auto populated by the function name from where this function is called
*/
public func EVLog<T>(_ object: T, filename: String = #file, line: Int = #line, funcname: String = #function) {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MM/dd/yyyy HH:mm:ss:SSS"
    let process = ProcessInfo.processInfo
    let threadId = "." //NSThread.currentThread().threadDictionary
    print("\(dateFormatter.string(from: Date())) \(process.processName))[\(process.processIdentifier):\(threadId)] \((filename as NSString).lastPathComponent)(\(line)) \(funcname):\r\t\(object)\n")
}

/**
Make sure the file is not backed up to iCloud

- parameter filePath: the url of the file we want to set the attribute for
*/
public func addSkipBackupAttributeToItemAtPath(_ filePath:String) {
    let url:URL = URL(fileURLWithPath: filePath)
    do {
        try (url as NSURL).setResourceValue(NSNumber(value: true as Bool), forKey: URLResourceKey.isExcludedFromBackupKey)
    } catch {
        EVLog("ERROR: Could not set 'exclude from backup' attribute for file \(filePath)\n\\tERROR:(error?.description)")
    }
}

