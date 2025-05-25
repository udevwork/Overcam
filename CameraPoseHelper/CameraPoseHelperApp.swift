//
//  CameraPoseHelperApp.swift
//  CameraPoseHelper
//
//  Created by Denis Kotelnikov on 22.12.2023.
//

import SwiftUI

// CONSTANTS
let TG_SUPPORT = "https://t.me/O1lab"
let EMAIL_SUPPORT = "udevwork@gmail.com"
let WEBSITE = "https://denyskotelnykov.com/01/lab"
let PRIVACY_POLICY_LINK =  "https://principled-crustacean-be6.notion.site/PRIVACY-POLICY-OverCam-c92c0c3c4aee469ebea2e79900464bcd"
let TERMS_CONDITIONS_LINK = "https://principled-crustacean-be6.notion.site/TERMS-CONDITIONS-OverCam-c37710b9b5b445dd9195c4ca024371aa"
let APPSTORE_URL = "https://apps.apple.com/ge/app/overcam-overlay/id6514316633"
let REVENUECAT_KEY = "appl_thIrkgBUQwivPahAOljITArarsW"


@main
struct CameraPoseHelperApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                CustomCameraView()
            }.onAppear {
#if RELEASE
                TelegramBot.shared.sendMessage("Open_App")
#endif
                SubscriptionManager.shared.configure(apiKey: REVENUECAT_KEY)
            }
        }
    }
}
