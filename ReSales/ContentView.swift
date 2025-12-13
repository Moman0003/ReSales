import SwiftUI

struct ContentView: View {
    @StateObject private var authVM: AuthViewModel
    @StateObject private var itemsVM: ItemsViewModel

    init() {
        _authVM = StateObject(wrappedValue: AuthViewModel(repo: AuthRepository()))
        _itemsVM = StateObject(wrappedValue: ItemsViewModel(repo: ItemRepository()))
    }

    var body: some View {
        if authVM.isLoggedIn {
            WelcomeView(itemsVM: itemsVM, authVM: authVM)
        } else {
            HomeView(itemsVM: itemsVM, authVM: authVM)
        }
    }
}

#Preview {
    ContentView()
}
