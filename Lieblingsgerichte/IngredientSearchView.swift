import SwiftUI
import CoreData

struct IngredientSearchView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var ingredientText: String = "" // Eingabefeld für Zutaten
    @State private var ingredients: [String] = [] // Gesuchte Zutatenliste
    @State private var searchResults: [Recipe] = [] // Ergebnisse basierend auf den Zutaten
    @State private var showHelpView = false // Zeigt die Hilfeseite an

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                VStack {
                    // Toolbar Bereich mit Titel
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Zutaten")
                                .font(.largeTitle)
                                .bold()
                            Spacer()
                            // Fragezeichen-Button
                            Button(action: {
                                showHelpView = true
                            }) {
                                Image(systemName: "questionmark.circle")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .padding(4)
                                    .background(Color.black)
                                    .clipShape(Circle())
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal)

                        Spacer()
                            .frame(height: 20)
                    }
                    .padding(.top)

                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                        TextField("Zutat suchen", text: $ingredientText, onCommit: {
                            addIngredient()
                        })
                            .foregroundColor(.white)
                        if !ingredientText.isEmpty {
                            Button(action: {
                                ingredientText = "" // Löscht den Text
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(13)
                    .background(Color(.darkGray).opacity(0.2)) // Dunkelgrauer Hintergrund
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)

                    // Ergebnisse als Zutatenliste mit Zurücksetzen-Button
                    if !ingredients.isEmpty {
                        HStack(alignment: .center) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(ingredients, id: \.self) { ingredient in
                                        Text(ingredient)
                                            .font(.subheadline)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 12)
                                            .frame(height: 35)
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(5)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .padding(.horizontal)

                            // Zurücksetzen-Button
                            Button(action: resetSearch) {
                                Text("Zurücksetzen")
                                    .font(.subheadline)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .frame(height: 35)
                                    .background(Color.red.opacity(0.7))
                                    .foregroundColor(.white)
                                    .cornerRadius(5)
                            }
                            .padding(.trailing)
                        }
                        .padding(.top, 10)
                    }

                    List {
                        ForEach(searchResults, id: \.self) { recipe in
                            ZStack(alignment: .leading) {
                                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                    EmptyView()
                                }
                                .opacity(0)

                                RecipeRow(recipe: recipe)
                                    .listRowSeparator(.hidden)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .sheet(isPresented: $showHelpView) {
                HelpView()
            }
        }
    }

    private func addIngredient() {
        let trimmedIngredient = ingredientText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedIngredient.isEmpty && !ingredients.contains(trimmedIngredient) {
            ingredients.append(trimmedIngredient)
            searchRecipes()
        }

        DispatchQueue.main.async {
            ingredientText = ""
        }
    }

    private func searchRecipes() {
        let predicates = ingredients.map { ingredient in
            NSPredicate(format: "ANY ingredients.name CONTAINS[cd] %@", ingredient)
        }
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        let fetchRequest: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        fetchRequest.predicate = compoundPredicate

        do {
            searchResults = try viewContext.fetch(fetchRequest)
        } catch {
            print("Fehler beim Suchen nach Rezepten: \(error.localizedDescription)")
        }
    }

    private func resetSearch() {
        ingredients.removeAll()
        searchResults.removeAll()
        ingredientText = ""
    }
}

struct HelpView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea() // Schwarzer Hintergrund, der die gesamte Ansicht abdeckt
            
            VStack {
                Spacer().frame(height: 30) // Platz oben
                Text("Im Zutaten-Bereich kannst du bequem die Zutaten hinzufügen, die du noch verwenden möchtest oder die du loswerden musst. Gib jede Zutat einzeln ein und bestätige mit Enter. Anschließend werden dir alle Rezepte angezeigt, die diese Zutaten enthalten.")
                    .font(.headline)
                    .padding(.horizontal, 35) // Platz links und rechts
                    .multilineTextAlignment(.center)
                Spacer() // Platz unten
            }
            .foregroundColor(.white) // Weißer Text
        }
    }
}

