//
//  EVglobal.swift
//
//  Created by Edwin Vermeer on 4/29/15.
//  Copyright (c) 2015. All rights reserved.
//

import SwiftTryCatch

/**
Bridge function to the SwiftTryCatch
:param: try The code that you want to try
:param: catch(exception) The optional code that will be executed in case of an exception
:param: finally The optional code that always will be executed
*/
public func EVtry(try:()->(), catch:((exception:NSException)->())? = nil, finally:(()->())? = nil) {
    SwiftTryCatch.try({
        try()
    }, catch: {error in
        if catch != nil {
            catch!(exception: error)
        }
    }, finally: {
        if finally != nil {
            finally!()
        }
    })
}

/**
Replacement function for NSLog that will also output the filename, linenumber and function name.

:param: object What you want to log
:param: filename Will be auto populated by the name of the file from where this function is called
:param: line Will be auto populated by the line number in the file from where this function is called
:param: funcname Will be auto populated by the function name from where this function is called
*/
public func EVLog<T>(object: T, filename: String = __FILE__, line: Int = __LINE__, funcname: String = __FUNCTION__) {
    var dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "MM/dd/yyyy HH:mm:ss:SSS"
    var process = NSProcessInfo.processInfo()
    var threadId = "." //NSThread.currentThread().threadDictionary
    println("\(dateFormatter.stringFromDate(NSDate())) \(process.processName))[\(process.processIdentifier):\(threadId)] \(filename.lastPathComponent)(\(line)) \(funcname):\r\t\(object)\n")
}
