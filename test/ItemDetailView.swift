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

    private var recurrenceBinding: Binding<Recurrence> {
        Binding<Recurrence>(
            get: { Recurrence(rawValue: item.recurrence) ?? .none },
            set: { item.recurrence = $0.rawValue }
        )
    }

    var body: some View {
        Form {
            Section("Informações") {
                TextField("Título", text: $item.title)
                TextField("Notas", text: $item.notes, axis: .vertical)
                    .lineLimit(4, reservesSpace: true)
                DatePicker("Data", selection: $item.timestamp, displayedComponents: [.date, .hourAndMinute])
            }

            Section("Recorrência") {
                Picker("Repetição", selection: recurrenceBinding) {
                    ForEach(Recurrence.allCases) { r in
                        Text(r.title).tag(r)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Lembrete") {
                Toggle("Ativar lembrete", isOn: $item.reminderEnabled)
                Stepper(value: $item.reminderMinutesBefore, in: 0...120, step: 5) {
                    Text("Minutos antes: \(item.reminderMinutesBefore)")
                }
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
            Button("Apagar", role: .destructive) {
                modelContext.delete(item)
                Task { await reschedule() }
            }
        } message: {
            Text("Esta ação não pode ser desfeita.")
        }
        .onChange(of: item.timestamp, initial: false) { Task { await reschedule() } }
        .onChange(of: item.reminderEnabled, initial: false) { Task { await reschedule() } }
        .onChange(of: item.reminderMinutesBefore, initial: false) { Task { await reschedule() } }
        .onChange(of: item.recurrence, initial: false) { Task { await reschedule() } }
    }

    private func reschedule() async {
        await NotificationManager.cancelNotification(for: item)
        await NotificationManager.scheduleNotification(for: item)
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
