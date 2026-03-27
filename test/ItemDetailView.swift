//
//  ItemDetailView.swift
//  test
//
//  Created by Pedro Lucas França on 27/03/26.
//

import SwiftUI
import SwiftData

struct ItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: Item

    @State private var showingDeleteAlert = false

    var body: some View {
        Form {
            Section("Informações") {
                TextField("Título", text: $item.title)
                TextField("Notas", text: $item.notes, axis: .vertical)
                    .lineLimit(4, reservesSpace: true)
                DatePicker("Data", selection: $item.timestamp, displayedComponents: [.date, .hourAndMinute])
            }

            Section("Preferências") {
                Toggle("Favorito", isOn: $item.isFavorite)
            }

            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Apagar item", systemImage: "trash")
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("Detalhes")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Apagar item?", isPresented: $showingDeleteAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Apagar", role: .destructive) { modelContext.delete(item) }
        } message: {
            Text("Esta ação não pode ser desfeita.")
        }
    }
}

#Preview {
    let preview = PreviewContainer()
    let item = Item(title: "Exemplo", notes: "Algumas notas", timestamp: .now, isFavorite: true)
    preview.container.mainContext.insert(item)
    return NavigationStack { ItemDetailView(item: item) }
        .modelContainer(preview.container)
}

struct PreviewContainer {
    let container: ModelContainer
    init() {
        container = try! ModelContainer(for: Item.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }
}
