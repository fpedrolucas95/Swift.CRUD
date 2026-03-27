//
//  ContentView.swift
//  test
//
//  Created by Pedro Lucas França on 27/03/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var searchText: String = ""
    @State private var showFavoritesOnly: Bool = false
    @State private var sortOption: SortOption = .dateDesc
    @State private var showingAddSheet: Bool = false

    @Query(sort: [SortDescriptor(\Item.timestamp, order: .reverse)], animation: .default)
    private var items: [Item]

    private var displayedItems: [Item] {
        var result = items

        if showFavoritesOnly {
            result = result.filter { $0.isFavorite }
        }
        if !searchText.isEmpty {
            let text = searchText
            result = result.filter { $0.title.localizedStandardContains(text) || $0.notes.localizedStandardContains(text) }
        }

        switch sortOption {
        case .dateDesc:
            result.sort { $0.timestamp > $1.timestamp }
        case .dateAsc:
            result.sort { $0.timestamp < $1.timestamp }
        case .title:
            result.sort { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        }
        return result
    }

    private var sections: [PeriodSection] {
        let calendar = Calendar.current
        let groups: [String: [Item]] = Dictionary(grouping: displayedItems, by: { item in
            let hour = calendar.component(.hour, from: item.timestamp)
            switch hour {
            case 5..<12: return "Manhã"
            case 12..<18: return "Tarde"
            default: return "Noite"
            }
        })
        let order = ["Manhã", "Tarde", "Noite"]
        return order.compactMap { key in
            guard let arr = groups[key], !arr.isEmpty else { return nil }
            return PeriodSection(id: key, title: key, items: arr)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HeaderControls(sortOption: $sortOption, showFavoritesOnly: $showFavoritesOnly)

                if displayedItems.isEmpty {
                    ContentEmptyState()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                            ForEach(sections) { section in
                                Section {
                                    ForEach(section.items) { item in
                                        ItemRow(
                                            item: item,
                                            onToggleFavorite: { toggleFavorite(item) },
                                            onDelete: { delete(item) }
                                        )
                                    }
                                } header: {
                                    SectionHeader(title: section.title)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .animation(.spring(), value: displayedItems)
                    }
                }
            }
            .navigationTitle("Meus Lembretes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Label("Adicionar", systemImage: "plus.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                    }
                    .keyboardShortcut("n", modifiers: [.command])
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Buscar por título ou nota")
            .sheet(isPresented: $showingAddSheet) {
                NavigationStack {
                    ItemFormView { title, notes, date, isFav, recurrence, reminderEnabled, minutesBefore in
                        withAnimation(.spring()) {
                            let newItem = Item(
                                title: title,
                                notes: notes,
                                timestamp: date,
                                isFavorite: isFav,
                                recurrence: recurrence.rawValue,
                                reminderEnabled: reminderEnabled,
                                reminderMinutesBefore: minutesBefore
                            )
                            modelContext.insert(newItem)
                            Task { await NotificationManager.scheduleNotification(for: newItem) }
                        }
                        showingAddSheet = false
                    } onCancel: {
                        showingAddSheet = false
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .navigationDestination(for: Item.self) { item in
                ItemDetailView(item: item)
            }
        }
        .task { try? await NotificationManager.requestAuthorization() }
    }

    private func toggleFavorite(_ item: Item) {
        withAnimation(.snappy) {
            item.isFavorite.toggle()
        }
    }

    private func delete(_ item: Item) {
        withAnimation(.spring()) {
            Task { NotificationManager.cancelNotification(for: item) }
            modelContext.delete(item)
        }
    }
}

private struct PeriodSection: Identifiable {
    let id: String
    let title: String
    let items: [Item]
}

private enum SortOption: String, CaseIterable {
    case dateDesc, dateAsc, title

    var title: String {
        switch self {
        case .title: return "Título"
        case .dateDesc: return "Recentes"
        case .dateAsc: return "Antigos"
        }
    }
}

private struct HeaderControls: View {
    @Binding var sortOption: SortOption
    @Binding var showFavoritesOnly: Bool

    var body: some View {
        HStack(spacing: 12) {
            Picker("Ordenar", selection: $sortOption) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)

            Toggle(isOn: $showFavoritesOnly) {
                Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                    .foregroundStyle(.yellow)
            }
            .toggleStyle(.button)
            .tint(.yellow)
            .accessibilityLabel("Apenas favoritos")
        }
        .padding(.horizontal)
    }
}

private struct SectionHeader: View {
    let title: String
    var body: some View {
        HStack {
            Text(title)
                .font(.title3).bold()
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 4)
        .background(Color.clear)
    }
}

private struct ItemRow: View {
    let item: Item
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void

    var body: some View {
        NavigationLink(value: item) {
            ItemCard(item: item)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(item.isFavorite ? "Remover dos favoritos" : "Adicionar aos favoritos", action: onToggleFavorite)
            Button(role: .destructive, action: onDelete) {
                Label("Apagar", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) { Label("Apagar", systemImage: "trash") }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(action: onToggleFavorite) { Label("Favorito", systemImage: item.isFavorite ? "star.slash" : "star.fill") }
                .tint(.yellow)
        }
        .padding(.horizontal)
    }
}

private struct ItemCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let item: Item

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.1), radius: 12, x: 0, y: 6)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if item.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .imageScale(.small)
                            .accessibilityLabel("Favorito")
                    }
                    Spacer()
                }

                if !item.notes.isEmpty {
                    Text(item.notes)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .imageScale(.small)
                        .foregroundStyle(.secondary)
                    Text(item.timestamp, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(item.timestamp, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.08))
        )
    }

    private var gradientColors: [Color] {
        if item.isFavorite {
            return [Color.yellow.opacity(0.35), Color.orange.opacity(0.25)]
        } else {
            return [Color.blue.opacity(0.25), Color.purple.opacity(0.2)]
        }
    }
}

private struct ContentEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(.quaternary).frame(width: 120, height: 120)
                Image(systemName: "tray")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            Text("Nenhum lembrete adicionado")
                .font(.title3).bold()
                .foregroundStyle(.primary)
            Text("Toque em \"Adicionar\" para criar um lembrete.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

