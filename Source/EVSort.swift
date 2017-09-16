//
//  EVSort.swift
//
//  Created by Edwin Vermeer on 2/7/16.
//  Copyright © 2016 mirabeau. All rights reserved.
//

import Foundation
import CoreLocation
import CloudKit

/**
 Enum that will be used to specify the order
 
 - Ascending: Sort in ascending order
 - Descending: Sort in descending order
 */
public enum SortDirection {
    case ascending,
    descending
}

/// Base class for the sort object
open class OrderBy {
    var field: String = ""
    var direction: SortDirection = .descending
    var parent: OrderBy?
    var sortDescriptor: NSSortDescriptor? = nil
    
    /**
     Convenience init for creating an order object with all the parameters
     
     - parameter field:     Sort on what field
     - parameter parent:    When we sort on multiple fields then we need a chaing of OrderBy objects
     - parameter direction: Do we sort ascending or descending
     */
    public convenience init(field: String, parent: OrderBy? = nil, direction: SortDirection) {
        self.init()
        self.field = field
        self.direction = direction
        self.parent = parent
        self.sortDescriptor = NSSortDescriptor(key: field, ascending: (direction == .ascending))
    }
    
    public convenience init(sortDescriptor: NSSortDescriptor, parent: OrderBy? = nil) {
        self.init()
        self.sortDescriptor = sortDescriptor
    }
    
    /**
     Chain a second sort in ascending order
     
     - parameter field: The field that we want to sort on
     
     - returns: An OrderBy object
     */
    open func Ascending(_ field: String) -> OrderBy {
        return OrderBy(field: field, parent: self, direction: .ascending)
    }
    
    /**
     Chain a second sort in descending order
     
     - parameter field: The field that we want to sort on
     
     - returns: An OrderBy object
     */
    open func Descending(_ field: String) -> OrderBy {
        return OrderBy(field: field, parent: self, direction: .descending)
    }
    
    open func Distance(_ field: String, relativeLocation: CLLocation) -> OrderBy {
        return OrderBy(sortDescriptor: CKLocationSortDescriptor(key: field, relativeLocation: relativeLocation), parent: self)
    }
    
    /**
     Build up an array of sortDescriptors
     
     - returns: The array of sortDescriptors
     */
    open func sortDescriptors() -> [NSSortDescriptor] {
        var result: [NSSortDescriptor] = parent?.sortDescriptors() ?? []
        if let sort = self.sortDescriptor {
            result.append(sort)
        }
        return result
    }
}

/// The initial OrderBy class for an ascending order
open class Ascending: OrderBy {
    /**
     Initialise an ascending OrderBy object
     
     - parameter field:  The field where to sort on
     */
    public convenience required init(field: String) {
        self.init(field: field, parent: nil, direction: .ascending)
    }
}

// The initial OrderBy class for a descending order
open class Descending: OrderBy {
    /**
     Initialise an descending OrderBy object
     
     - parameter field:  The field where to sort on
     */
    public convenience required init(field: String) {
        self.init(field: field, parent: nil, direction: .descending)
    }
}

// Just here so that we can use a nice name while ordering.
open class Distance: OrderBy {
    public convenience required init(field: String, relativeLocation: CLLocation) {
        self.init(sortDescriptor: CKLocationSortDescriptor(key: field, relativeLocation: relativeLocation), parent: nil)
    }
}
