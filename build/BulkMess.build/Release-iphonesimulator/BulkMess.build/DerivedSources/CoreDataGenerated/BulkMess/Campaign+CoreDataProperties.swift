//
//  Campaign+CoreDataProperties.swift
//  
//
//  Created by Daniil Mukashev on 26/09/2025.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias CampaignCoreDataPropertiesSet = NSSet

extension Campaign {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Campaign> {
        return NSFetchRequest<Campaign>(entityName: "Campaign")
    }

    @NSManaged public var name: String?
    @NSManaged public var dateCreated: Date?
    @NSManaged public var scheduledDate: Date?
    @NSManaged public var status: String?
    @NSManaged public var totalRecipients: Int32
    @NSManaged public var sentCount: Int32
    @NSManaged public var failedCount: Int32
    @NSManaged public var isFollowUpEnabled: Bool
    @NSManaged public var template: MessageTemplate?
    @NSManaged public var messages: NSSet?
    @NSManaged public var targetGroups: NSSet?
    @NSManaged public var followUpSequence: FollowUpSequence?

}

// MARK: Generated accessors for messages
extension Campaign {

    @objc(addMessagesObject:)
    @NSManaged public func addToMessages(_ value: Message)

    @objc(removeMessagesObject:)
    @NSManaged public func removeFromMessages(_ value: Message)

    @objc(addMessages:)
    @NSManaged public func addToMessages(_ values: NSSet)

    @objc(removeMessages:)
    @NSManaged public func removeFromMessages(_ values: NSSet)

}

// MARK: Generated accessors for targetGroups
extension Campaign {

    @objc(addTargetGroupsObject:)
    @NSManaged public func addToTargetGroups(_ value: ContactGroup)

    @objc(removeTargetGroupsObject:)
    @NSManaged public func removeFromTargetGroups(_ value: ContactGroup)

    @objc(addTargetGroups:)
    @NSManaged public func addToTargetGroups(_ values: NSSet)

    @objc(removeTargetGroups:)
    @NSManaged public func removeFromTargetGroups(_ values: NSSet)

}

extension Campaign : Identifiable {

}
