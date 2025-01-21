//
//  CameraPoseHelperApp.swift
//  CameraPoseHelper
//
//  Created by Denis Kotelnikov on 22.12.2023.
//

import SwiftUI
import BoilerCore

let PRIVACY_POLICY_LINK =  "https://principled-crustacean-be6.notion.site/PRIVACY-POLICY-OverCam-c92c0c3c4aee469ebea2e79900464bcd"
let TERMS_CONDITIONS_LINK = "https://principled-crustacean-be6.notion.site/TERMS-CONDITIONS-OverCam-c37710b9b5b445dd9195c4ca024371aa"
let END_USER_LICENSE_AGREEMENT_URL = "https://principled-crustacean-be6.notion.site/END-USER-LICENSE-AGREEMENT-OverCam-917c34e1ed5b4f9ba040fcfd844ff573?pvs=74"

let APPSTORE_URL = "https://apps.apple.com/ge/app/overcam-overlay/id6514316633"

let oldOnboarding: [OnBoardingModel] = [
    .init(image: "Onboarding1", title: "Reference image", subTitle: "Choose a reference image and adjust transparency on the screen."),
    .init(image: "Onboarding2", title: "Photo settings", subTitle: "Customize settings for your convenience."),
    .init(image: "Onboarding3", title: "Take a Photo", subTitle: "Match the angle with the reference and snap the photo!"),
    .init(image: "", title: "Take a Photo", subTitle: "Just one step away from flawless photos!")
]

let oldBenefits: [PaywallBenefitItem] = [
    .init(systemIcon: "wand.and.stars.inverse",
          image: "",
          title: "Select any photos from your gallery without restrictions",
          subtitle: "Without a subscription, you can only choose from built-in images.")
]

struct MainView: View {
    var body: some View {
        NavigationView {
            CameraView()
        }
    }
}

@main
struct CameraPoseHelperApp: App {
    var body = BoilerWrapper {
        MainView()
    }
    
    settings: {
        AppName("OverCam")
        
        MixpanelSetting(api: "e044f04033305b1e0769baf8a8352d54")
        RevenueCatSetting(api: "appl_thIrkgBUQwivPahAOljITArarsW")
        AdaptySetting(api: "public_live_GnRScY5V.XAvF1jejJTjHJsFvVNwr")
        FirebaseAnalytics()
        
        OnboardingData(data: oldOnboarding)
        PaywallBenefits(data: oldBenefits)
        ColorThemeSetting(.dark)

        Terms(URL: TERMS_CONDITIONS_LINK)
        Privacy(URL: PRIVACY_POLICY_LINK)
        AppStore(URL: APPSTORE_URL)
        FAQ(URL: "https://t.me/imbalanceFighter")
        SupportEmail(email: "udevwork@gmail.com")
        MySetting(test: "Denys")
        DevScreenSetting() /// DEV
    }
    
    additionalSetup: {
        AdaptySubscriptionService(placementId: "", accessLevel: "")
    }
}
