//
//  ItemFormView.swift
//  test
//
//  Created by Pedro Lucas França on 27/03/26.
//

import SwiftUI

enum ItemRecurrence: String, CaseIterable, Identifiable {
    case none
    case daily
    case weekly
    case monthly
    case yearly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: return "Nenhuma"
        case .daily: return "Diária"
        case .weekly: return "Semanal"
        case .monthly: return "Mensal"
        case .yearly: return "Anual"
        }
    }
}

struct ItemFormView: View {
    var onSave: (_ title: String, _ notes: String, _ date: Date, _ isFavorite: Bool, _ recurrence: ItemRecurrence, _ reminderEnabled: Bool, _ minutesBefore: Int) -> Void
    var onCancel: () -> Void

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var date: Date = .now
    @State private var isFavorite: Bool = false

    @State private var recurrence: ItemRecurrence = .none
    @State private var reminderEnabled: Bool = false
    @State private var minutesBefore: Int = 0

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

            Section("Recorrência") {
                Picker("Repetição", selection: $recurrence) {
                    ForEach(ItemRecurrence.allCases) { r in
                        Text(r.title).tag(r)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Lembrete") {
                Toggle("Ativar lembrete", isOn: $reminderEnabled)
                Stepper(value: $minutesBefore, in: 0...120, step: 5) {
                    Text("Minutos antes: \(minutesBefore)")
                }
                .disabled(!reminderEnabled)
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
                    onSave(title, notes, date, isFavorite, recurrence, reminderEnabled, minutesBefore)
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .task {
            try? await NotificationManager.requestAuthorization()
        }
    }
}

#Preview {
    NavigationStack { ItemFormView(onSave: {_,_,_,_,_,_,_ in}, onCancel: {}) }
}
