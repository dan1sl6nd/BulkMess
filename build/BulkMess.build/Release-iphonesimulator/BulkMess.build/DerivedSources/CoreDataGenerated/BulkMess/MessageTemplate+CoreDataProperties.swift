//
//  MessageTemplate+CoreDataProperties.swift
//  
//
//  Created by Daniil Mukashev on 26/09/2025.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias MessageTemplateCoreDataPropertiesSet = NSSet

extension MessageTemplate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MessageTemplate> {
        return NSFetchRequest<MessageTemplate>(entityName: "MessageTemplate")
    }

    @NSManaged public var name: String?
    @NSManaged public var content: String?
    @NSManaged public var dateCreated: Date?
    @NSManaged public var dateModified: Date?
    @NSManaged public var isFavorite: Bool
    @NSManaged public var usageCount: Int32
    @NSManaged public var campaigns: NSSet?
    @NSManaged public var followUpSequences: NSSet?

}

// MARK: Generated accessors for campaigns
extension MessageTemplate {

    @objc(addCampaignsObject:)
    @NSManaged public func addToCampaigns(_ value: Campaign)

    @objc(removeCampaignsObject:)
    @NSManaged public func removeFromCampaigns(_ value: Campaign)

    @objc(addCampaigns:)
    @NSManaged public func addToCampaigns(_ values: NSSet)

    @objc(removeCampaigns:)
    @NSManaged public func removeFromCampaigns(_ values: NSSet)

}

// MARK: Generated accessors for followUpSequences
extension MessageTemplate {

    @objc(addFollowUpSequencesObject:)
    @NSManaged public func addToFollowUpSequences(_ value: FollowUpMessage)

    @objc(removeFollowUpSequencesObject:)
    @NSManaged public func removeFromFollowUpSequences(_ value: FollowUpMessage)

    @objc(addFollowUpSequences:)
    @NSManaged public func addToFollowUpSequences(_ values: NSSet)

    @objc(removeFollowUpSequences:)
    @NSManaged public func removeFromFollowUpSequences(_ values: NSSet)

}

extension MessageTemplate : Identifiable {

}
