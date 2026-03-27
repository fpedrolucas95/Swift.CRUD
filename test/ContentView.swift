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

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
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

                if displayedItems.isEmpty {
                    ContentEmptyState()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(displayedItems) { item in
                                NavigationLink(value: item) {
                                    ItemCard(item: item)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(item.isFavorite ? "Remover dos favoritos" : "Adicionar aos favoritos") {
                                        toggleFavorite(item)
                                    }
                                    Button(role: .destructive) {
                                        delete(item)
                                    } label: {
                                        Label("Apagar", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) { delete(item) } label: { Label("Apagar", systemImage: "trash") }
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button { toggleFavorite(item) } label: { Label("Favorito", systemImage: item.isFavorite ? "star.slash" : "star.fill") }
                                        .tint(.yellow)
                                }
                            }
                            .animation(.spring(), value: displayedItems)
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Meus Itens")
            .navigationBarTitleDisplayMode(.large)
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
                    ItemFormView { title, notes, date, isFav in
                        withAnimation(.spring()) {
                            let newItem = Item(title: title, notes: notes, timestamp: date, isFavorite: isFav)
                            modelContext.insert(newItem)
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
    }

    private func toggleFavorite(_ item: Item) {
        withAnimation(.snappy) {
            item.isFavorite.toggle()
        }
    }

    private func delete(_ item: Item) {
        withAnimation(.spring()) {
            modelContext.delete(item)
        }
    }
}

private enum SortOption: String, CaseIterable {
    case dateDesc, dateAsc, title

    var title: String {
        switch self {
        case .dateDesc: return "Mais recentes"
        case .dateAsc: return "Mais antigos"
        case .title: return "Título"
        }
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
            Text("Nada por aqui ainda")
                .font(.title3).bold()
                .foregroundStyle(.primary)
            Text("Toque em \"Adicionar\" para criar seu primeiro item.")
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
