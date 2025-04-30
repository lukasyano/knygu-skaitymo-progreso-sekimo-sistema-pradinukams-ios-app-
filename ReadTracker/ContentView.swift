import Combine
import SwiftData
import SwiftUI

// extension DatabaseReference {
//    static let child = Database.database().reference().child("users")
// }
//
// struct UserData: Codable, Identifiable {
//    var id: UUID = .init()
//    var userName: String
// }
//
// class RealtimeDatabasePublisher: ObservableObject {
//    @Published var items: [Item] = .init()
//    var cancellables: Set<AnyCancellable> = .init()
//
//    init() {
//        DatabaseReference.child.observe(.value) {  _ in
//            //  guard let self else { return }
//
//            print("new record")
//        }
//    }
// }


// struct RegistrationView: View {
//    @State private var email = ""
//    @State private var password = ""
//    @State private var selectedRole = "reader"
//    let roles = ["parent", "reader"]
//
//    var body: some View {
//        VStack {
//            TextField("Email", text: $email)
//                .textFieldStyle(.roundedBorder)
//            SecureField("Password", text: $password)
//                .textFieldStyle(.roundedBorder)
//
//            Picker("Select Role", selection: $selectedRole) {
//                ForEach(roles, id: \.self) { role in
//                    Text(role.capitalized)
//                }
//            }
//            .pickerStyle(.segmented)
//
//            Button("Register") {
//                registerUser()
//            }
//            .padding()
//        }
//        .padding()
//    }
//
//    func registerUser() {
//        Auth.auth().createUser(withEmail: email, password: password) { result, error in
//            if let error = error {
//                print("Registration error: \(error.localizedDescription)")
//                return
//            }
//
//            guard let user = result?.user else { return }
//
//            // Save role in Realtime Database
//            let ref = Database.database().reference()
//            ref.child("users").child(user.uid).setValue([
//                "email": email,
//                "role": selectedRole
//            ])
//
//            print("User registered with role: \(selectedRole)")
//        }
//    }
// }

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    //  @StateObject private var realtimeDatabasePublisher = RealtimeDatabasePublisher()

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
