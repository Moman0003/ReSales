import SwiftUI

struct HomeView: View {
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

    private var filteredItems: [SalesItem] {
        var result = itemsVM.items

        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            result = result.filter { item in
                item.description.lowercased().contains(q) ||
                item.sellerEmail.lowercased().contains(q) ||
                item.sellerPhone.lowercased().contains(q) ||
                String(item.price).contains(q)
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

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                Picker("", selection: $sortIndex) {
                    Label("Nyeste", systemImage: "clock").tag(0)
                    Label("Pris ↑", systemImage: "arrow.up").tag(1)
                    Label("Pris ↓", systemImage: "arrow.down").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if itemsVM.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }

                if let msg = itemsVM.errorMessage, !msg.isEmpty {
                    Text("Fejl: \(msg)")
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }

                List {
                    ForEach(filteredItems, id: \.id) { item in
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
                            .onTapGesture {
                                expandedId = (expandedId == item.id) ? nil : item.id
                            }

                            if expandedId == item.id {
                                Divider().padding(.top, 8)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Flere detaljer")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.tint)

                                    Text("Sælger: \(item.sellerEmail)")
                                        .font(.subheadline)

                                    Text("Telefon: \(item.sellerPhone)")
                                        .font(.subheadline)

                                    Text("Oprettet: \(Date(timeIntervalSince1970: TimeInterval(item.time)).formatted(date: .numeric, time: .omitted))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
                .listStyle(.plain)
                .refreshable { await itemsVM.loadItems() }
            }
            .navigationTitle("ReSales")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        LoginView(authVM: authVM)
                    } label: {
                        Image(systemName: "person.crop.circle.badge.plus")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button { showFilterSheet = true } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await itemsVM.loadItems() } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Søg i annoncer")
            .task { await itemsVM.loadItems() }
            .sheet(isPresented: $showFilterSheet) {
                filterSheet
            }
        }
    }

    private var filterSheet: some View {
        NavigationStack {
            Form {
                Section("Pris") {
                    TextField("Min pris", text: $minPriceText).keyboardType(.numberPad)
                    TextField("Max pris", text: $maxPriceText).keyboardType(.numberPad)
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
                    Button("Anvend") { showFilterSheet = false }.fontWeight(.semibold)
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
