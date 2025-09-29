//
//  Message+CoreDataProperties.swift
//  
//
//  Created by Daniil Mukashev on 26/09/2025.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias MessageCoreDataPropertiesSet = NSSet

extension Message {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Message> {
        return NSFetchRequest<Message>(entityName: "Message")
    }

    @NSManaged public var content: String?
    @NSManaged public var status: String?
    @NSManaged public var dateSent: Date?
    @NSManaged public var errorMessage: String?
    @NSManaged public var isFollowUp: Bool
    @NSManaged public var followUpStep: Int16
    @NSManaged public var isIncoming: Bool
    @NSManaged public var dateReceived: Date?
    @NSManaged public var contact: Contact?
    @NSManaged public var campaign: Campaign?

}

extension Message : Identifiable {

}
