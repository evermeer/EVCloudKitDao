//
//  EVReflection.swift
//
//  Created by Edwin Vermeer on 28-09-14.
//  Copyright (c) 2014 EVICT BV. All rights reserved.
//

import Foundation

/**
Reflection methods
*/
public class EVReflection {
    /**
    Create an object from a dictionary
    
    :param: dictionary The dictionary that will be converted to an object
    :param: anyobjectTypeString The string representation of the object type that will be created
    :return: The object that is created from the dictionary
    */
    public class func fromDictionary(dictionary:Dictionary<String, AnyObject?>, anyobjectTypeString: String) -> NSObject {
        var anyobjectype : AnyObject.Type = swiftClassFromString(anyobjectTypeString)
        var nsobjectype : NSObject.Type = anyobjectype as NSObject.Type
        var nsobject: NSObject = nsobjectype()
        for (key: String, value: AnyObject?) in dictionary {
            if (dictionary[key] != nil) {
                nsobject.setValue(dictionary[key]!, forKey: key)
            }
        }
        return nsobject
    }
    
    /**
    Convert an object to a dictionary
    
    :param: theObject The object that will be converted to a dictionary
    :return: The dictionary that is created from theObject
    */
    public class func toDictionary(theObject: NSObject) -> Dictionary<String, AnyObject?> {
        var propertiesDictionary : Dictionary<String, AnyObject?> = Dictionary<String, AnyObject?>()
        for i in 0..<reflect(theObject).count {
            let key : String = reflect(theObject)[i].0
            let value = reflect(theObject)[i].1.value
            if key != "super" {
                var v : AnyObject? = valueForAny(value)
                propertiesDictionary.updateValue(v, forKey: key)
            }
        }
        return propertiesDictionary
    }
    
    /**
    Dump the content of this object
    
    :param: theObject The object that will be loged
    :return: No return value
    */
    public class func logObject(theObject: NSObject) {
        for (key: String, value: AnyObject?) in toDictionary(theObject) {
            NSLog("key = \(key), value = \(value)")
        }
    }
    
    /**
    Get the swift Class from a string
    
    :param: className The string representation of the class (name of the bundle dot name of the class)
    :return: The Class type
    */
    public class func swiftClassFromString(className: String) -> AnyClass! {
        if  var appName: String = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleName") as String? {
            let classStringName = "\(appName).\(className)"
            return NSClassFromString(classStringName)
        }
        return nil;
    }
    
    /**
    Get the class name as a string from a swift class
    
    :param: theObject An object for whitch the string representation of the class will be returned
    :return: The string representation of the class (name of the bundle dot name of the class)
    */
    public class func swiftStringFromClass(theObject: NSObject) -> String! {
        if  var appName: String = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleName") as String? {
            let classStringName: String = NSStringFromClass(theObject.dynamicType)
            return classStringName.stringByReplacingOccurrencesOfString(appName + ".", withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        }
        return nil;
    }
    
    //TODO: Make this work with nulable types
    /**
    Helper function to convert an Any to AnyObject
    
    :param: anyValue Something of type Any is converted to a type NSObject
    :return: The NSOBject that is created from the Any value
    */
    public class func valueForAny(anyValue:Any) -> NSObject? {
        switch(anyValue) {
        case let intValue as Int:
            return NSNumber(int: CInt(intValue))
        case let doubleValue as Double:
            return NSNumber(double: CDouble(doubleValue))
        case let stringValue as String:
            return stringValue as NSString
        case let boolValue as Bool:
            return NSNumber(bool: boolValue)
        case let anyvalue as NSObject:
            return anyvalue as NSObject
        default:
            return nil
        }
    }
}