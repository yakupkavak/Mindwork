//
//  MindworkApp.swift
//  Mindwork
//
//  Created by Yakup Kavak on 2.08.2025.
//

import SwiftUI

@main
struct MindworkApp: App {
    
    //MARK: - Properties
    
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @UIApplicationDelegateAdaptor(CustomAppDelegate.self) var delegate
    @StateObject private var routerTask = RouterMemory()
    @StateObject private var routerUser = RouterUserInfo()
    @StateObject private var routerFeed = RouterFeed()
    @StateObject private var authManager = AuthManager.shared

    private var userState = false
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            if authManager.isSigned {
                if hasCompletedOnboarding {
                    BaseTabViewUI().installToast(position: .bottom).environmentObject(routerTask).environmentObject(routerUser).environmentObject(routerFeed).onAppear {
                        UIApplication.shared.addTapGestureRecognizer()
                    }
                }else {
                    OnboardingUI()
                }
            } else {
                SignContainerUI().installToast(position: .bottom).onAppear {
                    UIApplication.shared.addTapGestureRecognizer()
                }
            }
        }
    }
}
