import SwiftUI

struct WelcomeView: View {
    @StateObject var itemsVM: ItemsViewModel
    @StateObject var authVM: AuthViewModel

    @State private var searchText = ""
    @State private var sortIndex = 0
    @State private var expandedId: Int? = nil

    @State private var showFilterSheet = false
    @State private var minPriceText = ""
    @State private var maxPriceText = ""
    @State private var fromDate: Date? = nil
    @State private var useFromDate = false

    var body: some View {
        NavigationStack {
            List {
                headerSection
                sortSection

                if itemsVM.isLoading {
                    Section { ProgressView() }
                }

                if let msg = itemsVM.errorMessage, !msg.isEmpty {
                    Section {
                        Text("Fejl: \(msg)")
                            .foregroundStyle(.red)
                    }
                }

                itemsSection
            }
            .listStyle(.plain)
            .navigationTitle("ReSales")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { topToolbar }
            .searchable(text: $searchText, prompt: "Søg i annoncer")
            .refreshable { await itemsVM.loadItems() }
            .task { await itemsVM.loadItems() }
            .sheet(isPresented: $showFilterSheet) { filterSheet }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text("Velkommen")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(authVM.userEmail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)
        }
    }

    // Filter (venstre) + Sortering (midt) + Reload (højre)
    private var sortSection: some View {
        Section {
            HStack(spacing: 10) {

                Button {
                    showFilterSheet = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.headline)
                        .frame(width: 36, height: 36)
                        .background(.thinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Filtre")

                Picker("", selection: $sortIndex) {
                    Label("Nyeste", systemImage: "clock").tag(0)
                    Label("Pris ↑", systemImage: "arrow.up").tag(1)
                    Label("Pris ↓", systemImage: "arrow.down").tag(2)
                }
                .pickerStyle(.segmented)

                Button {
                    Task { await itemsVM.loadItems() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.headline)
                        .frame(width: 36, height: 36)
                        .background(.thinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Opdatér")
            }
            .padding(.vertical, 4)
        }
    }

    private var itemsSection: some View {
        Section {
            ForEach(filteredItems, id: \.id) { item in
                ItemRow(
                    item: item,
                    isExpanded: expandedId == item.id,
                    onTap: { expandedId = (expandedId == item.id) ? nil : item.id }
                )
                .swipeActions {
                    if authVM.userEmail == item.sellerEmail {
                        Button(role: .destructive) {
                            Task { await itemsVM.deleteItem(id: item.id) }
                        } label: {
                            Text("Slet")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Toolbar (kun profil + logout)

    @ToolbarContentBuilder
    private var topToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            NavigationLink {
                ProfileView(itemsVM: itemsVM, authVM: authVM)
            } label: {
                Image(systemName: "person.circle")
            }

            Button(role: .destructive) {
                authVM.signOut()
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
            }
        }
    }

    // MARK: - Filtering logic

    private var filteredItems: [SalesItem] {
        var result = itemsVM.items

        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            result = result.filter {
                $0.description.lowercased().contains(q) ||
                $0.sellerEmail.lowercased().contains(q) ||
                $0.sellerPhone.lowercased().contains(q) ||
                String($0.price).contains(q)
            }
        }

        if let minP = Int(minPriceText) { result = result.filter { $0.price >= minP } }
        if let maxP = Int(maxPriceText) { result = result.filter { $0.price <= maxP } }

        if useFromDate, let date = fromDate {
            let epoch = Int64(date.timeIntervalSince1970)
            result = result.filter { $0.time >= epoch }
        }

        switch sortIndex {
        case 0: result.sort { $0.time > $1.time }
        case 1: result.sort { $0.price < $1.price }
        case 2: result.sort { $0.price > $1.price }
        default: break
        }

        return result
    }

    // MARK: - Filter sheet

    private var filterSheet: some View {
        NavigationStack {
            Form {
                Section("Pris") {
                    TextField("Min pris", text: $minPriceText)
                        .keyboardType(.numberPad)
                    TextField("Max pris", text: $maxPriceText)
                        .keyboardType(.numberPad)
                }

                Section("Dato") {
                    Toggle("Fra dato", isOn: $useFromDate)
                    if useFromDate {
                        DatePicker(
                            "Vælg dato",
                            selection: Binding(
                                get: { fromDate ?? Date() },
                                set: { fromDate = $0 }
                            ),
                            displayedComponents: [.date]
                        )
                    }
                }

                Section {
                    Text("Efterlad tom for ingen grænse")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Filtrér annoncer")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Luk") { showFilterSheet = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Anvend") { showFilterSheet = false }
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .bottomBar) {
                    Button("Ryd") {
                        minPriceText = ""
                        maxPriceText = ""
                        fromDate = nil
                        useFromDate = false
                        showFilterSheet = false
                    }
                    .foregroundStyle(.red)
                }
            }
        }
    }
}

// MARK: - Split out row to keep compiler fast

private struct ItemRow: View {
    let item: SalesItem
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {

                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.secondarySystemFill))

                    if let urlString = item.pictureUrl,
                       let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                EmptyView()
                            }
                        }
                        .clipped()
                    }
                }
                .frame(width: 84, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.description)
                        .font(.headline)

                    Text("Email: \(item.sellerEmail)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Tlf: \(item.sellerPhone)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(item.price) kr")
                    .font(.headline.weight(.semibold))
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)

            if isExpanded {
                Divider().padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Flere detaljer")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tint)

                    Text("Oprettet: \(Date(timeIntervalSince1970: TimeInterval(item.time)).formatted(date: .numeric, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }
}
