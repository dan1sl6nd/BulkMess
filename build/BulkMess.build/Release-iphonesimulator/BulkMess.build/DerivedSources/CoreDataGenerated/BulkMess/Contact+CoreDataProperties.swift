//
//  Contact+CoreDataProperties.swift
//  
//
//  Created by Daniil Mukashev on 26/09/2025.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias ContactCoreDataPropertiesSet = NSSet

extension Contact {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Contact> {
        return NSFetchRequest<Contact>(entityName: "Contact")
    }

    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
    @NSManaged public var phoneNumber: String?
    @NSManaged public var email: String?
    @NSManaged public var dateCreated: Date?
    @NSManaged public var isFromDeviceContacts: Bool
    @NSManaged public var deviceContactIdentifier: String?
    @NSManaged public var notes: String?
    @NSManaged public var groups: NSSet?
    @NSManaged public var messages: NSSet?

}

// MARK: Generated accessors for groups
extension Contact {

    @objc(addGroupsObject:)
    @NSManaged public func addToGroups(_ value: ContactGroup)

    @objc(removeGroupsObject:)
    @NSManaged public func removeFromGroups(_ value: ContactGroup)

    @objc(addGroups:)
    @NSManaged public func addToGroups(_ values: NSSet)

    @objc(removeGroups:)
    @NSManaged public func removeFromGroups(_ values: NSSet)

}

// MARK: Generated accessors for messages
extension Contact {

    @objc(addMessagesObject:)
    @NSManaged public func addToMessages(_ value: Message)

    @objc(removeMessagesObject:)
    @NSManaged public func removeFromMessages(_ value: Message)

    @objc(addMessages:)
    @NSManaged public func addToMessages(_ values: NSSet)

    @objc(removeMessages:)
    @NSManaged public func removeFromMessages(_ values: NSSet)

}

extension Contact : Identifiable {

}
