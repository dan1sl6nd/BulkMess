//
//  ContactGroup+CoreDataProperties.swift
//  
//
//  Created by Daniil Mukashev on 26/09/2025.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias ContactGroupCoreDataPropertiesSet = NSSet

extension ContactGroup {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ContactGroup> {
        return NSFetchRequest<ContactGroup>(entityName: "ContactGroup")
    }

    @NSManaged public var name: String?
    @NSManaged public var dateCreated: Date?
    @NSManaged public var colorHex: String?
    @NSManaged public var contacts: NSSet?
    @NSManaged public var campaigns: NSSet?

}

// MARK: Generated accessors for contacts
extension ContactGroup {

    @objc(addContactsObject:)
    @NSManaged public func addToContacts(_ value: Contact)

    @objc(removeContactsObject:)
    @NSManaged public func removeFromContacts(_ value: Contact)

    @objc(addContacts:)
    @NSManaged public func addToContacts(_ values: NSSet)

    @objc(removeContacts:)
    @NSManaged public func removeFromContacts(_ values: NSSet)

}

// MARK: Generated accessors for campaigns
extension ContactGroup {

    @objc(addCampaignsObject:)
    @NSManaged public func addToCampaigns(_ value: Campaign)

    @objc(removeCampaignsObject:)
    @NSManaged public func removeFromCampaigns(_ value: Campaign)

    @objc(addCampaigns:)
    @NSManaged public func addToCampaigns(_ values: NSSet)

    @objc(removeCampaigns:)
    @NSManaged public func removeFromCampaigns(_ values: NSSet)

}

extension ContactGroup : Identifiable {

}
