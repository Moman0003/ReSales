import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject var itemsVM: ItemsViewModel
    @StateObject var authVM: AuthViewModel

    @State private var showAddSheet = false

    private var myItems: [SalesItem] {
        itemsVM.items.filter { $0.sellerEmail == authVM.userEmail }
            .sorted { $0.time > $1.time }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Logget ind som: \(authVM.userEmail)")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                if myItems.isEmpty {
                    Text("Du har ingen annoncer endnu.")
                        .padding(.horizontal)
                } else {
                    List {
                        ForEach(myItems, id: \.id) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.description).font(.headline)
                                Text("Pris: \(item.price) kr").foregroundStyle(.secondary)
                                Text("Tlf: \(item.sellerPhone)").foregroundStyle(.secondary)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    Task { await itemsVM.deleteItem(id: item.id) }
                                } label: { Text("Slet") }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Min profil")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddItemSheet(
                    authVM: authVM,
                    onSave: { desc, price, phone in
                        Task {
                            await itemsVM.createItem(
                                description: desc,
                                price: price,
                                sellerEmail: authVM.userEmail,
                                sellerPhone: phone,
                                pictureUrl: nil
                            )
                            showAddSheet = false
                        }
                    },
                    onCancel: { showAddSheet = false }
                )
            }
        }
    }
}

private struct AddItemSheet: View {
    @StateObject var authVM: AuthViewModel
    let onSave: (String, Int, String) -> Void
    let onCancel: () -> Void

    @State private var description = ""
    @State private var priceText = ""
    @State private var phone = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Ny annonce") {
                    TextField("Titel / beskrivelse", text: $description)
                    TextField("Pris (kr)", text: $priceText).keyboardType(.numberPad)
                    TextField("Telefon", text: $phone).keyboardType(.phonePad)
                }

                Section("Sælger") {
                    Text(authVM.userEmail).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Ny annonce")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuller") { onCancel() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Gem") {
                        guard let p = Int(priceText), p > 0 else { return }
                        onSave(description, p, phone)
                    }
                    .fontWeight(.semibold)
                    .disabled(description.isEmpty || Int(priceText) == nil || phone.isEmpty)
                }
            }
        }
    }
}
