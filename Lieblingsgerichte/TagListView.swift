import SwiftUI
import CoreData


struct TagListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Tag.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
    ) var tags: FetchedResults<Tag>
    
    @State private var searchText: String = "" // Suchleiste für Tags
    @State private var showImpressumView = false // Steuert die Anzeige der Impressum-Seite

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                VStack {
                    // Toolbar Bereich mit Titel
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Tags")
                                .font(.largeTitle)
                                .bold()
                            Spacer()
                            // Info-Button
                            Button(action: {
                                showImpressumView = true
                            }) {
                                Image(systemName: "info.circle")
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
                            .frame(height: 20) // Abstand zwischen Titel und Suchleiste
                    }
                    .padding(.top)

                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                        TextField("Tag suchen", text: $searchText)
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

                    // Liste der Tags
                    List {
                        ForEach(filteredTags, id: \.self) { tag in
                            ZStack(alignment: .leading) {
                                NavigationLink(destination: FilteredRecipeListView1(tag: tag)) {
                                    EmptyView()
                                }
                                .opacity(0)

                                Text(tag.name ?? "Unbenannter Tag")
                                    .font(.headline)
                                    .padding()
                                    .background(Color(.systemGray6).opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .background(Color.black.ignoresSafeArea()) // Schwarzer Hintergrund
            .sheet(isPresented: $showImpressumView) {
                ImpressumView()
            }
        }
    }

    private var filteredTags: [Tag] {
        let uniqueTags = Dictionary(grouping: tags, by: { $0.name }).compactMap { $0.value.first }
        let filteredTags = uniqueTags.filter { $0.name?.localizedCaseInsensitiveCompare("Ausprobieren") != .orderedSame }
        let sortedTags = filteredTags.sorted { ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending }
        if searchText.isEmpty {
            return sortedTags
        } else {
            return sortedTags.filter { $0.name?.localizedCaseInsensitiveContains(searchText) == true }
        }
    }
}



import SwiftUI
import CoreData

struct FilteredRecipeListView1: View {
    var tag: Tag
    @Environment(\.managedObjectContext) private var viewContext
    @State private var recipes: [Recipe] = []
    
    var body: some View {
        VStack {
            HStack {
                Text("Rezepte mit Tag: ")
                    .font(.title3) +
                Text(tag.name ?? "Unbenannter Tag")
                    .font(.title3)
                    .bold()
            }

            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
            
            List(recipes, id: \.self) { recipe in
                ZStack(alignment: .leading) {
                    NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                        EmptyView()
                    }
                    .opacity(0)
                    
                    RecipeRow(recipe: recipe)
                        .listRowSeparator(.hidden) // Zeilentrenner in jeder Reihe entfernen
                }
            }
            .listStyle(PlainListStyle())
            .background(Color.black.ignoresSafeArea())
            .onAppear(perform: fetchRecipes)
        }
        .background(Color.black.ignoresSafeArea())

    }
    
    private func fetchRecipes() {
        let fetchRequest: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "ANY tags.name == %@", tag.name ?? "")
        
        do {
            recipes = try viewContext.fetch(fetchRequest)
        } catch {
            print("Fehler beim Abrufen der Rezepte: \(error.localizedDescription)")
        }
    }
}

struct ImpressumView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea() // Schwarzer Hintergrund
            
            VStack(alignment: .leading, spacing: 20) {
                Spacer().frame(height: 20) // Platz oben
                
                // Oberer Bereich
                Text("Impressum")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.bottom, 10) // Abstand unter dem Titel
                
                Text("Vielen Dank an Pepa, die mich bei diesem Projekt inspiriert hat. Ich hoffe, diese App hilft uns dabei, unsere Lieblingsrezepte effizient zu verwalten. Ich liebe dich!")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Spacer() // Füllt den mittleren Bereich
                
                // Unterer Bereich
                VStack(alignment: .leading, spacing: 10) {
                    Text("Diese App wurde erstellt von Arthur Wunder.")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Text("Kontakt:")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("E-Mail: arthur.wunder@drs-wunder.de")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                }
                .padding(.bottom, 40) // Abstand unten
            }
            .padding(.horizontal, 25) // Abstand links und rechts
        }
    }
}
