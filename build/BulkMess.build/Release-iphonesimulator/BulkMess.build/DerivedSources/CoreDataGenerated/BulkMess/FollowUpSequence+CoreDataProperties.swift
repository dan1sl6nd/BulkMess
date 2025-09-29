//
//  FollowUpSequence+CoreDataProperties.swift
//  
//
//  Created by Daniil Mukashev on 26/09/2025.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias FollowUpSequenceCoreDataPropertiesSet = NSSet

extension FollowUpSequence {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FollowUpSequence> {
        return NSFetchRequest<FollowUpSequence>(entityName: "FollowUpSequence")
    }

    @NSManaged public var name: String?
    @NSManaged public var isActive: Bool
    @NSManaged public var campaign: Campaign?
    @NSManaged public var followUpMessages: NSSet?

}

// MARK: Generated accessors for followUpMessages
extension FollowUpSequence {

    @objc(addFollowUpMessagesObject:)
    @NSManaged public func addToFollowUpMessages(_ value: FollowUpMessage)

    @objc(removeFollowUpMessagesObject:)
    @NSManaged public func removeFromFollowUpMessages(_ value: FollowUpMessage)

    @objc(addFollowUpMessages:)
    @NSManaged public func addToFollowUpMessages(_ values: NSSet)

    @objc(removeFollowUpMessages:)
    @NSManaged public func removeFromFollowUpMessages(_ values: NSSet)

}

extension FollowUpSequence : Identifiable {

}
