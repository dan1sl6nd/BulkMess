//
//  FollowUpMessage+CoreDataProperties.swift
//  
//
//  Created by Daniil Mukashev on 26/09/2025.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias FollowUpMessageCoreDataPropertiesSet = NSSet

extension FollowUpMessage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FollowUpMessage> {
        return NSFetchRequest<FollowUpMessage>(entityName: "FollowUpMessage")
    }

    @NSManaged public var stepNumber: Int16
    @NSManaged public var delayDays: Int16
    @NSManaged public var delayHours: Int16
    @NSManaged public var template: MessageTemplate?
    @NSManaged public var sequence: FollowUpSequence?

}

extension FollowUpMessage : Identifiable {

}
