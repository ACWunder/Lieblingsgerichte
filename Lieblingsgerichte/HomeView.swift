import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Recipe.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Recipe.title, ascending: true)]
    ) var recipes: FetchedResults<Recipe>
    
    @State private var displayedRecipes: [Recipe] = [] // Rezepte in zufälliger Reihenfolge
    @State private var topRecipeIndex = 0 // Index des aktuellen obersten Rezepts
    @State private var translation: CGSize = .zero
    @State private var showDetailView = false // Zeigt an, ob die Detailansicht angezeigt wird
    @State private var showExcludeTagsView = false // Zeigt die Tag-Ausschlussansicht
    @AppStorage("excludedTags") private var excludedTagsStorage: String = "" // Gespeicherte ausgeschlossene Tags als String
    @State private var isDeckInitialized = false // Zustandsvariable für die Initialisierung

    
    private var excludedTags: [String] {
        get {
            excludedTagsStorage.split(separator: ",").map { String($0) }
        }
        set {
            excludedTagsStorage = newValue.joined(separator: ",")
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                ZStack {
                    if displayedRecipes.isEmpty {
                        Text("Keine Rezepte verfügbar")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ForEach(Array(displayedRecipes.enumerated()).reversed(), id: \.1) { index, recipe in
                            if index >= topRecipeIndex && index < topRecipeIndex + 3 {
                                RecipeCardView(recipe: recipe, excludedTags: excludedTags)
                                    .offset(x: index == topRecipeIndex ? translation.width : 0,
                                            y: CGFloat(index - topRecipeIndex) * 10)
                                    .rotationEffect(index == topRecipeIndex ? .degrees(Double(translation.width / 20)) : .zero)
                                    .animation(.easeInOut(duration: 0.3), value: translation)
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                if index == topRecipeIndex {
                                                    translation = value.translation
                                                }
                                            }
                                            .onEnded { value in
                                                if value.translation.height < -100 {
                                                    showDetailView = true
                                                } else if abs(value.translation.width) > 100 {
                                                    swipeCard()
                                                } else {
                                                    translation = .zero
                                                }
                                            }
                                    )
                            }
                        }

                    }
                }
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline) // Macht den Titel schlanker
            .toolbar {
                ToolbarItem(placement: .principal) { // Titel zentriert platzieren
                    VStack {
                        Spacer() // Lücke einfügen, um den Titel nach unten zu schieben
                            .frame(height: 50) // Kontrolliere die Höhe des Abstands
                        Text("Lass dich inspirieren")
                            .font(.title) // Größer als .headline
                            .foregroundColor(.primary) // Standardfarbe
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) { // Button oben links
                    Button(action: {
                        showExcludeTagsView.toggle()
                    }) {
                        Image(systemName: "exclamationmark.circle")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .padding(4)
                            .background(Color.black)
                            .clipShape(Circle())
                            .foregroundColor(.white)
                    }
                }
            }

            .sheet(isPresented: $showDetailView) {
                if let recipe = displayedRecipes[safe: topRecipeIndex] {
                    RecipeDetailView(recipe: recipe)
                        .environment(\.managedObjectContext, viewContext)
                }
            }
            .sheet(isPresented: $showExcludeTagsView) {
                ExcludeTagsView(excludedTags: excludedTags) { updatedTags in
                    excludedTagsStorage = updatedTags.joined(separator: ",") // Update storage
                    filterRecipes() // Filter erneut anwenden
                }
                .environment(\.managedObjectContext, viewContext)
            }
            .onAppear {
                if !isDeckInitialized {
                    filterRecipes() // Filter nur bei der ersten Initialisierung anwenden
                    isDeckInitialized = true // Initialisierung festhalten
                }
            }
        }
    }
    
    // Angepasste Filtermethode
    private func filterRecipes() {
        let filtered = recipes.filter { recipe in
            let recipeTags = recipe.tags as? Set<Tag> ?? []
            return !recipeTags.contains { excludedTags.contains($0.name ?? "") }
        }
        
        // Nur beim ersten Aufruf wird das Deck gemischt
        if !isDeckInitialized {
            displayedRecipes = filtered.shuffled()
        } else {
            displayedRecipes = filtered
        }
        
        // Top-Index wird nur bei Initialisierung zurückgesetzt
        if !isDeckInitialized {
            topRecipeIndex = 0
        }
    }


    private func swipeCard() {
        withAnimation(.easeInOut(duration: 0.3)) {
            translation.width = translation.width > 0 ? 800 : -800
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            translation = .zero
            if topRecipeIndex < displayedRecipes.count - 1 {
                topRecipeIndex += 1
            } else {
                resetDeck() // Deck zurücksetzen und mischen
            }
        }
    }

    private func resetDeck() {
        displayedRecipes = recipes.shuffled()
        topRecipeIndex = 0
    }

}

struct ExcludeTagsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Tag.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
    ) var tags: FetchedResults<Tag>
    
    @State private var localExcludedTags: [String]
    var onUpdate: ([String]) -> Void // Callback für Änderungen
    private var initialTags: [String] // Speichert die ursprünglichen Tags

    init(excludedTags: [String], onUpdate: @escaping ([String]) -> Void) {
        _localExcludedTags = State(initialValue: excludedTags)
        self.initialTags = excludedTags
        self.onUpdate = onUpdate
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 30)

            Text("Diese Tags ausschließen")
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        HStack {
                            Text(tag.name ?? "Unbenannter Tag")
                                .font(.body)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { localExcludedTags.contains(tag.name ?? "") },
                                set: { isExcluded in
                                    if let name = tag.name {
                                        if isExcluded {
                                            localExcludedTags.append(name)
                                        } else {
                                            localExcludedTags.removeAll { $0 == name }
                                        }
                                    }
                                }
                            ))
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.black)
                        .cornerRadius(4)
                    }
                }
            }
            .background(Color.black)

            Spacer()
        }
        .padding(.horizontal, 16)
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onDisappear {
            // Vergleiche initialTags mit localExcludedTags, bevor die Änderung weitergegeben wird
            if initialTags.sorted() != localExcludedTags.sorted() {
                onUpdate(localExcludedTags) // Nur wenn sich die Tags geändert haben
            }
        }
    }
}




struct RecipeCardView: View {
    var recipe: Recipe
    var excludedTags: [String] // Excluded tags werden übergeben

    var body: some View {
        if let imageData = recipe.image, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width - 20, height: UIScreen.main.bounds.height / 1.5)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 10)
        } else {
            Image(systemName: "photo")
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width - 20, height: UIScreen.main.bounds.height / 1.5)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 10)
        }
    }
}


// Extension für sicheren Array-Zugriff
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
