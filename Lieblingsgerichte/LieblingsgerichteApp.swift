import SwiftUI

@main
struct LieblingsgerichteApp: App {
    let persistenceController = PersistenceController.shared

    // AppDelegate für die Rotationseinschränkung
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Navigation Bar Appearance für UIKit
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground() // Macht den Hintergrund transparent
        appearance.backgroundColor = UIColor.clear // Keine Hintergrundfarbe
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor.gray // Back-Button und Navigation-Buttons grau

        // Dark Mode global erzwingen
        UIView.appearance().overrideUserInterfaceStyle = .dark
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .tint(.gray) // Standardfarbe für Buttons
        }
    }
}

// AppDelegate zur Steuerung der Geräteeinstellungen
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        // Nur Hochformat erlauben
        return .portrait
    }
}
