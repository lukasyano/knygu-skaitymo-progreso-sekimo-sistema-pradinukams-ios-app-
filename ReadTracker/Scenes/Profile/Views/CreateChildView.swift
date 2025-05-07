import SwiftUI

struct CreateChildView: View {
    @Environment(\.dismiss) private var dismiss

    let createChild: (String, String, String) -> Void

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Vaiko informacija") {
                    TextField("Vardas", text: $name)
                    TextField("El. paštas", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    SecureField("Slaptažodis", text: $password)
                }

                Section {
                    Button("Sukurti") {
                        createChild(name, email, password)
                        dismiss()
                    }
                    .disabled(!formIsValid)
                }
            }
            .navigationTitle("Naujas vaikas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Atšaukti") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var formIsValid: Bool {
        !name.isEmpty && email.contains("@") && email.contains(".") && !password.isEmpty
    }
}
