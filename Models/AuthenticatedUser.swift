//
//  AuthenticatedUser.swift
//  ReadTracker
//
//  Created by Lukas Toliušis   on 02/06/2025.
//

protocol AuthenticatedUser {
    var uid: String { get }
    var email: String? { get }
    var displayName: String? { get }
}
