import SwiftUI
import CoreData

struct AddRecipeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var title: String = ""
    @State private var descriptionText: String = ""
    @State private var ingredients: [String] = []
    @State private var ingredientText: String = ""
    @State private var tags: [String] = []
    @State private var tagText: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var showSuccessMessage = false

    var isTryRecipe: Bool = false // Automatisch "Ausprobieren"-Tag setzen
    var onDismiss: (() -> Void)? // Callback nach Speichern

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Titel")) {
                    TextField("Rezeptname", text: $title)
                }

                Section(header: Text("Beschreibung")) {
                    TextEditor(text: $descriptionText)
                        .frame(height: 100)
                }

                Section(header: Text("Zutaten")) {
                    HStack {
                        TextField("Zutat hinzufügen", text: $ingredientText)
                        Button(action: {
                            if !ingredientText.isEmpty {
                                ingredients.append(ingredientText)
                                ingredientText = ""
                            }
                        }) {
                            Image(systemName: "plus.circle")
                        }
                    }
                    List {
                        ForEach(ingredients, id: \.self) { ingredient in
                            Text(ingredient)
                        }
                        .onDelete(perform: removeIngredient)
                    }
                }

                Section(header: Text("Tags")) {
                    HStack {
                        TextField("Tag hinzufügen", text: $tagText)
                        Button(action: {
                            if !tagText.isEmpty {
                                tags.append(tagText)
                                tagText = ""
                            }
                        }) {
                            Image(systemName: "plus.circle")
                        }
                    }
                    List {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                        }
                        .onDelete(perform: removeTag)
                    }
                }

                Section(header: Text("Bild")) {
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    } else {
                        Button("Bild auswählen") {
                            showImagePicker = true
                        }
                    }
                }
            }
            .navigationTitle("Rezept hinzufügen")
            .navigationBarItems(trailing: Button("Speichern") {
                
                saveRecipe()
            }
            .foregroundColor(.green) // Beibehaltung der ursprünglichen Farbe
            .opacity(0.8) // Setzt die Transparenz auf 80%
            
            )
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .overlay(
                Group {
                    if showSuccessMessage {
                        Text("Rezept erfolgreich gespeichert!")
                            .font(.headline)
                            .padding()
                            .background(Color.green.opacity(0.8))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .transition(.scale)
                    }
                }
            )
        }
        .onAppear { // Füge den Modifikator hier hinzu
            if isTryRecipe {
                // Verhindere doppelte Einträge für den Tag
                if !tags.contains("Ausprobieren") {
                    tags.append("Ausprobieren")
                }
            }
        }
        .preferredColorScheme(.dark) // Erzwingt den Dark Mode
    }


    private func removeIngredient(at offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
    }

    private func removeTag(at offsets: IndexSet) {
        tags.remove(atOffsets: offsets)
    }
    
    private func saveRecipe() {
        let newRecipe = Recipe(context: viewContext)
        newRecipe.title = title
        newRecipe.recipeDescription = descriptionText

        // Zutaten hinzufügen
        for ingredientName in ingredients {
            let newIngredient = Ingredient(context: viewContext)
            newIngredient.name = ingredientName
            newRecipe.addToIngredients(newIngredient)
        }

        // Automatisch den Tag "Ausprobieren" hinzufügen, falls `isTryRecipe` aktiv ist
        if isTryRecipe {
            let tagFetch: NSFetchRequest<Tag> = Tag.fetchRequest()
            tagFetch.predicate = NSPredicate(format: "name == %@", "Ausprobieren")

            do {
                let existingTags = try viewContext.fetch(tagFetch)
                let tag = existingTags.first ?? Tag(context: viewContext)
                tag.name = "Ausprobieren"
                newRecipe.addToTags(tag)
            } catch {
                print("Fehler beim Abrufen oder Erstellen des 'Ausprobieren'-Tags: \(error.localizedDescription)")
            }
        }

        // Manuell hinzugefügte Tags verarbeiten
        for tagName in tags where tagName != "Ausprobieren" || !isTryRecipe {
            let tagFetch: NSFetchRequest<Tag> = Tag.fetchRequest()
            tagFetch.predicate = NSPredicate(format: "name == %@", tagName)

            do {
                let existingTags = try viewContext.fetch(tagFetch)
                let tag = existingTags.first ?? Tag(context: viewContext)
                tag.name = tagName
                newRecipe.addToTags(tag)
            } catch {
                print("Fehler beim Abrufen oder Erstellen des Tags: \(error.localizedDescription)")
            }
        }

        // Bild hinzufügen (falls vorhanden)
        if let selectedImage = selectedImage {
            newRecipe.image = selectedImage.pngData()
        }

        // Rezept speichern
        do {
            try viewContext.save()
            resetForm()
            showSuccessMessage = true

            // Schließt das Hinzufügen-Fenster
            DispatchQueue.main.async {
                onDismiss?()
            }
        } catch {
            print("Fehler beim Speichern des Rezepts: \(error.localizedDescription)")
        }
    }



    private func resetForm() {
        title = ""
        descriptionText = ""
        ingredients = []
        tags = []
        ingredientText = ""
        tagText = ""
        selectedImage = nil
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Fehler beim Speichern von Core Data: \(error.localizedDescription)")
        }
    }

}
