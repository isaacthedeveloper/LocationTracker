//
//  Location+CoreDataProperties.swift
//  Locations
//
//  Created by Isaac Ballas on 2019-09-05.
//  Copyright © 2019 Isaacballas. All rights reserved.
//
//

import Foundation
import CoreData
import CoreLocation

extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged var date: Date
    @NSManaged public var locationDescription: String
    @NSManaged public var category: String
    @NSManaged var placemark: CLPlacemark?

}
