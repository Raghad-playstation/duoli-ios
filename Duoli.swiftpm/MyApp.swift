
import SwiftUI
import CoreText

@main
struct MyApp: App {

    init() {
        registerCustomFont()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    private func registerCustomFont() {
        guard let fontURL = Bundle.main.url(
            forResource: "VaguelyRetroRegular-3zAqM",
            withExtension: "ttf",
            subdirectory: "Resources"
        ) else {
            print("Duoli: Custom font file not found.")
            return
        }

        var error: Unmanaged<CFError>?

        let success = CTFontManagerRegisterFontsForURL(
            fontURL as CFURL,
            .process,
            &error
        )

        if success {
            print("Duoli: Custom font registered successfully!")
        } else {
            print("Duoli: Font registration failed: \(String(describing: error))")
        }
    }
}
