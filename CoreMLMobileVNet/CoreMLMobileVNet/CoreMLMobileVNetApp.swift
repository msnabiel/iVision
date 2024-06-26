//
//  CoreMLMobileVNetApp.swift
//  CoreMLMobileVNet
//
//  Created by Syed Nabiel Hasaan M on 26/06/24.
//

import SwiftUI

@main
struct CoreMLMobileVNetApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
