import SwiftUI

struct ContentView: View {
    // Zugriff auf den Managed Object Context (Core Data) in der gesamten App
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        TabView {
            HomeView() // Der Startbildschirm
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }

            RecipeListView() // Die Rezeptliste
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Rezepte")
                }

            IngredientSearchView() // Zutaten-Suche
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Zutaten")
                }

            TagListView() // Die Tag-Liste
                .tabItem {
                    Image(systemName: "tag")
                    Text("Tags")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        // Core Data Umgebung für das Preview setzen
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

