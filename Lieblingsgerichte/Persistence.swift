import CoreData
import UIKit

struct PersistenceController {
    static let shared = PersistenceController(inMemory: false) // Permanente Speicherung

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        for _ in 0..<10 {
            let newRecipe = Recipe(context: viewContext)
            newRecipe.title = "Beispielrezept"
            newRecipe.recipeDescription = "Beschreibung des Beispielrezepts"
            newRecipe.image = nil
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) { // Standardmäßig persistenter Speicher
           container = NSPersistentContainer(name: "Lieblingsgerichte")

           if inMemory {
               container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
           }

           container.loadPersistentStores { (storeDescription, error) in
               if let error = error as NSError? {
                   fatalError("Unresolved error \(error), \(error.userInfo)")
               }
           }

           container.viewContext.automaticallyMergesChangesFromParent = true

           // Lade Rezepte bei jedem Start und bereinige Duplikate und verwaiste Tags
           importRecipesFromJSON(context: container.viewContext)
           removeOrphanedTags(context: container.viewContext)
       }

    private func importRecipesFromJSON(context: NSManagedObjectContext) {
        guard let url = Bundle.main.url(forResource: "defaultRecipes", withExtension: "json") else {
            print("JSON-Datei nicht gefunden")
            return
        }

        // Lade nur, wenn keine bestehenden Rezepte vorhanden sind
        let fetchRequest: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        do {
            let existingRecipes = try context.fetch(fetchRequest)
            if !existingRecipes.isEmpty {
                print("Rezepte existieren bereits. Kein neuer Import.")
                return
            }

            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let recipes = try decoder.decode([RecipeData].self, from: data)

            for recipeData in recipes {
                let recipe = Recipe(context: context)
                recipe.title = recipeData.title
                recipe.recipeDescription = recipeData.recipeDescription

                if let imageName = recipeData.imageName,
                   let image = UIImage(named: imageName)?.pngData() {
                    recipe.image = image
                }

                for ingredientData in recipeData.ingredients {
                    let ingredient = Ingredient(context: context)
                    ingredient.name = ingredientData.name
                    recipe.addToIngredients(ingredient)
                }

                for tagData in recipeData.tags {
                    let tagFetch: NSFetchRequest<Tag> = Tag.fetchRequest()
                    tagFetch.predicate = NSPredicate(format: "name == %@", tagData.name)

                    let existingTags = try context.fetch(tagFetch)
                    let tag = existingTags.first ?? Tag(context: context)
                    tag.name = tagData.name
                    recipe.addToTags(tag)
                }
            }

            try context.save()
        } catch {
            print("Fehler beim Importieren der Rezepte: \(error.localizedDescription)")
        }
    }


    private func removeOrphanedTags(context: NSManagedObjectContext) {
        let tagFetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        
        do {
            let tags = try context.fetch(tagFetchRequest)
            for tag in tags {
                // Entferne Tags, die keinem Rezept zugeordnet sind
                if tag.recipes?.count == 0 {
                    context.delete(tag)
                }
            }
            try context.save()
        } catch {
            print("Fehler beim Bereinigen verwaister Tags: \(error.localizedDescription)")
        }
    }
}

// JSON-Datenmodelle
struct RecipeData: Codable {
    let title: String
    let recipeDescription: String
    let imageName: String?
    let ingredients: [IngredientData]
    let tags: [TagData]
}

struct IngredientData: Codable {
    let name: String
}

struct TagData: Codable {
    let name: String
}

