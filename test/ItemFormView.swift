//
//  ItemFormView.swift
//  test
//
//  Created by Pedro Lucas França on 27/03/26.
//

import SwiftUI

struct ItemFormView: View {
    var onSave: (_ title: String, _ notes: String, _ date: Date, _ isFavorite: Bool) -> Void
    var onCancel: () -> Void

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var date: Date = .now
    @State private var isFavorite: Bool = false

    var body: some View {
        Form {
            Section("Informações") {
                TextField("Título", text: $title)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)
                TextField("Notas", text: $notes, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
                DatePicker("Data", selection: $date, displayedComponents: [.date, .hourAndMinute])
            }

            Section("Preferências") {
                Toggle("Favorito", isOn: $isFavorite)
            }
        }
        .navigationTitle("Novo item")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancelar", action: onCancel)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Salvar") {
                    guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    onSave(title, notes, date, isFavorite)
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

#Preview {
    NavigationStack { ItemFormView(onSave: {_,_,_,_ in}, onCancel: {}) }
}
