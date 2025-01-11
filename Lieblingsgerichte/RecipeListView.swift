import SwiftUI
import CoreData
struct RecipeListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText: String = ""
    @State private var showAddRecipeView = false
    @State private var showTryRecipesView = false // State für "Ausprobieren"-Liste

    @FetchRequest(
        entity: Recipe.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Recipe.title, ascending: true)]
    ) var recipes: FetchedResults<Recipe>

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                VStack {
                    // Toolbar Bereich mit Spacer
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Rezepte")
                                .font(.largeTitle)
                                .bold()
                            Spacer()
                            Button("Ausprobieren") {
                                showTryRecipesView = true
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 5)
                            .background(Color(.black))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        Spacer() // Fügt Abstand zwischen "Tags" und der Suchleiste ein
                            .frame(height: 20) // Passen Sie die Höhe nach Wunsch an
                    }
                    .padding(.top)

                    // Suchleiste
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                        TextField("Rezept suchen", text: $searchText)
                            .foregroundColor(.white)
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = "" // Löscht den Text
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

                    List {
                        ForEach(filteredRecipes, id: \.self) { recipe in
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

                // Floating Action Button
                Button(action: {
                    showAddRecipeView = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(Color.pink)
                        .shadow(radius: 10)
                }
                .padding(.bottom, 20)
                .sheet(isPresented: $showAddRecipeView) {
                    AddRecipeView(onDismiss: {
                        showAddRecipeView = false
                    })
                    .environment(\.managedObjectContext, viewContext)
                }
            }
            .sheet(isPresented: $showTryRecipesView) {
                NavigationView {
                    TryRecipeListView()
                        .environment(\.managedObjectContext, viewContext)
                }
            }
        }
    }

    private var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return recipes.filter { recipe in
                !(recipe.tags as? Set<Tag> ?? []).contains { $0.name == "Ausprobieren" }
            }
        } else {
            return recipes.filter { recipe in
                !(recipe.tags as? Set<Tag> ?? []).contains { $0.name == "Ausprobieren" } &&
                    recipe.title?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
}

struct RecipeRow: View {
    var recipe: Recipe

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(recipe.title ?? "Unbenanntes Rezept")
                    .font(.headline)
                    .lineLimit(1)
                Text(recipe.recipeDescription ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            .padding(.leading,8)
            Spacer()
            
            if let imageData = recipe.image, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 5)
            }
        }
        .padding(.vertical, 8)
        .background(Color.clear) // Keine graue Box
        .cornerRadius(12)
    }
}




struct FilteredRecipeListView: View {
    var tag: Tag

    var body: some View {
        // Verwende den FetchRequest hier direkt für Rezepte mit dem ausgewählten Tag
        let fetchRequest: FetchRequest<Recipe> = FetchRequest(
            entity: Recipe.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Recipe.title, ascending: true)],
            predicate: NSPredicate(format: "ANY tags.name == %@", tag.name ?? "")
        )
        let recipes = fetchRequest.wrappedValue
        
        if recipes.isEmpty {
            Text("Keine Rezepte für den Tag '\(tag.name ?? "Kein Tag")' verfügbar")
        } else {
            ForEach(recipes) { recipe in
                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                    Text(recipe.title ?? "Unbenanntes Rezept")
                }
            }
        }
    }
}
import SwiftUI
import CoreData

struct RecipeDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showEditView = false
    @State private var showDeleteAlert = false

    var recipe: Recipe

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // Rezeptbild
                if let imageData = recipe.image, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / 2)
                        .clipped()
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    
                    // Titel des Rezepts
                    Text(recipe.title ?? "Unbenanntes Rezept")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    // Zutatenliste
                    if let ingredients = recipe.ingredients as? Set<Ingredient>, !ingredients.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Zutaten")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.leading, 8)
                            
                            ForEach(Array(ingredients), id: \.self) { ingredient in
                                HStack {
                                    Text("• \(ingredient.name ?? "Unbenannte Zutat")")
                                        .foregroundColor(.white.opacity(0.85))
                                    Spacer()
                                }
                                .padding(.leading, 16)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                    }
                    
                    // Beschreibung
                    if let description = recipe.recipeDescription {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Beschreibung")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.leading, 8)
                            
                            HStack {
                                Text(description)
                                    .foregroundColor(.white.opacity(0.85))
                                Spacer()
                            }
                            .padding(.leading, 16)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                    }

                    // Tags
                    if let tags = recipe.tags as? Set<Tag>, !tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.leading, 8)
                            
                            HStack {
                                ForEach(Array(tags), id: \.self) { tag in
                                    Text(tag.name ?? "Unbenannter Tag")
                                        .padding(8)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(5)
                                        .foregroundColor(.white)
                                        .font(.subheadline)
                                }
                                Spacer()
                            }
                            .padding(.leading, 8)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 0)
                
                Spacer()
            }
            .background(Color.black.ignoresSafeArea())
            .sheet(isPresented: $showEditView) {
                EditRecipeView(recipe: recipe)
                    .environment(\.managedObjectContext, viewContext)
            }
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("Rezept löschen"),
                    message: Text("Möchten Sie dieses Rezept wirklich löschen?"),
                    primaryButton: .destructive(Text("Löschen")) {
                        deleteRecipe()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .navigationBarItems(
            trailing: HStack(spacing: 20) {
                Button(action: { showEditView = true }) {
                    Image(systemName: "square.and.pencil") // Bearbeiten-Symbol
                        .font(.system(size: 17)) // Kleinere Schriftgröße für das Icon
                        .foregroundColor(.gray) // Ändere von .blue zu .gray
                }
                
                Button(action: { showDeleteAlert = true }) {
                    Image(systemName: "trash") // Löschen-Symbol
                        .font(.system(size: 17)) // Kleinere Schriftgröße für das Icon
                        .foregroundColor(.red) // Rot bleibt hier unverändert
                }
            }
        )
    }
    
    private func deleteRecipe() {
        viewContext.delete(recipe)
        do {
            try viewContext.save()
        } catch {
            print("Fehler beim Löschen des Rezepts: \(error.localizedDescription)")
        }
    }
}

struct EditRecipeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    var recipe: Recipe
    @State private var title: String = ""
    @State private var descriptionText: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var tags: [String] = [] // Tags als Array von Strings
    @State private var ingredients: [String] = [] // Zutaten als Array von Strings
    @State private var newTagText: String = "" // Neues Tag hinzufügen
    @State private var newIngredientText: String = "" // Neue Zutat hinzufügen

    init(recipe: Recipe) {
        self.recipe = recipe
        _title = State(initialValue: recipe.title ?? "")
        _descriptionText = State(initialValue: recipe.recipeDescription ?? "")
        if let imageData = recipe.image, let uiImage = UIImage(data: imageData) {
            _selectedImage = State(initialValue: uiImage)
        }
        if let existingTags = recipe.tags as? Set<Tag> {
            _tags = State(initialValue: existingTags.compactMap { $0.name })
        }
        if let existingIngredients = recipe.ingredients as? Set<Ingredient> {
            _ingredients = State(initialValue: existingIngredients.compactMap { $0.name })
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea() // Schwarzer Hintergrund für die gesamte Ansicht
                
                Form {
                    Section(header: Text("Titel").foregroundColor(.white)) {
                        TextField("Rezeptname", text: $title)
                            .foregroundColor(.white)
                    }

                    Section(header: Text("Beschreibung").foregroundColor(.white)) {
                        TextEditor(text: $descriptionText)
                            .frame(height: 100)
                            .foregroundColor(.white)
                    }

                    Section(header: Text("Tags").foregroundColor(.white)) {
                        HStack {
                            TextField("Tag hinzufügen", text: $newTagText)
                                .foregroundColor(.white)
                            Button(action: {
                                if !newTagText.isEmpty {
                                    tags.append(newTagText)
                                    newTagText = ""
                                }
                            }) {
                                Image(systemName: "plus.circle")
                            }
                        }
                        List {
                            ForEach(tags, id: \.self) { tag in
                                Text(tag)
                                    .foregroundColor(.white)
                            }
                            .onDelete { indexSet in
                                tags.remove(atOffsets: indexSet)
                            }
                        }
                    }

                    Section(header: Text("Zutaten").foregroundColor(.white)) {
                        HStack {
                            TextField("Zutat hinzufügen", text: $newIngredientText)
                                .foregroundColor(.white)
                            Button(action: {
                                if !newIngredientText.isEmpty {
                                    ingredients.append(newIngredientText)
                                    newIngredientText = ""
                                }
                            }) {
                                Image(systemName: "plus.circle")
                            }
                        }
                        List {
                            ForEach(ingredients, id: \.self) { ingredient in
                                Text(ingredient)
                                    .foregroundColor(.white)
                            }
                            .onDelete { indexSet in
                                ingredients.remove(atOffsets: indexSet)
                            }
                        }
                    }

                    Section(header: Text("Bild").foregroundColor(.white)) {
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .onTapGesture {
                                    showImagePicker = true
                                }
                        } else {
                            Button("Bild auswählen") {
                                showImagePicker = true
                            }
                            .foregroundColor(.green)
                        }
                    }
                }
                .scrollContentBackground(.hidden) // Entfernt den grauen Hintergrund der Form
                .background(Color.black)          // Setzt die Form auf Schwarz
            }
            .navigationTitle("Rezept bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button(action: {
                    saveChanges()
                }) {
                    Text("Speichern")
                        .foregroundColor(.green) // Schriftfarbe grün setzen
                }
            )
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Einheitlicher Stil
    }

    

    private func saveChanges() {
        recipe.title = title
        recipe.recipeDescription = descriptionText
        if let selectedImage = selectedImage {
            recipe.image = selectedImage.pngData()
        }
        
        // Tags speichern
        let currentTags = recipe.tags as? Set<Tag> ?? []
        for tag in currentTags {
            viewContext.delete(tag)
        }
        for tagName in tags {
            let newTag = Tag(context: viewContext)
            newTag.name = tagName
            recipe.addToTags(newTag)
        }

        // Zutaten aktualisieren
        let currentIngredients = recipe.ingredients as? Set<Ingredient> ?? []
        for ingredient in currentIngredients {
            viewContext.delete(ingredient)
        }
        for ingredientName in ingredients {
            let newIngredient = Ingredient(context: viewContext)
            newIngredient.name = ingredientName
            recipe.addToIngredients(newIngredient)
        }

        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Fehler beim Speichern der Änderungen: \(error.localizedDescription)")
        }
    }
}


struct TryRecipeListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showAddRecipeView = false // Rezept hinzufügen

    @FetchRequest(
        entity: Recipe.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Recipe.title, ascending: true)],
        predicate: NSPredicate(format: "ANY tags.name == %@", "Ausprobieren")
    ) var tryRecipes: FetchedResults<Recipe>

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea() // Schwarzer Hintergrund

            VStack {
                List {
                    ForEach(tryRecipes, id: \.self) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            Text(recipe.title ?? "Unbenanntes Rezept")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .cornerRadius(10)
                        }
                        .listRowBackground(Color.clear) // Entfernt den Standard-Hintergrund der Zeile
                        .padding(.vertical, 2) // Abstand zwischen den Zellen
                    }
                    .onDelete(perform: deleteRecipe)
                }
                .listStyle(PlainListStyle())
                .background(Color.black) // Hintergrund der Liste schwarz
                .navigationBarTitleDisplayMode(.inline) // Macht den Titel kompakter
                .toolbar {
                    ToolbarItem(placement: .principal) { // Zentriert den Titel
                        Text("Ausprobieren")
                            .font(.headline) // Kleinere Schriftgröße
                            .multilineTextAlignment(.center) // Text zentrieren
                    }
                }
            }

            // Floating Button oben in der ZStack-Hierarchie
            Button(action: {
                showAddRecipeView = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(Color.pink) // Normale Farbe
                    .shadow(radius: 10)
            }
            .padding(.bottom, 20)
            .sheet(isPresented: $showAddRecipeView) {
                AddRecipeView(isTryRecipe: true, onDismiss: {
                    showAddRecipeView = false
                })
                .environment(\.managedObjectContext, viewContext)
            }
        }
    }

    private func deleteRecipe(at offsets: IndexSet) {
        for index in offsets {
            let recipeToDelete = tryRecipes[index]
            viewContext.delete(recipeToDelete)
        }

        do {
            try viewContext.save()
        } catch {
            print("Fehler beim Löschen des Rezepts: \(error.localizedDescription)")
        }
    }
}
