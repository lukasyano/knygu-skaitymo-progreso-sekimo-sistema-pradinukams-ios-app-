import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                Group {
                    if configuration.isPressed {
                        Color.accentColor.opacity(0.7)
                    } else {
                        Color.accentColor
                    }
                }
            )
            .cornerRadius(8)
            .shadow(color: .black.opacity(configuration.isPressed ? 0 : 0.2),
                    radius: 5, x: 0, y: 4)
            .opacity(isEnabled ? 1 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct CreateChildView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isLoading: Bool
    let createChild: (String, String, String) -> Void
    @State var mockedChildCounter: Int = 0

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""

    private var formIsValid: Bool {
        !name.isEmpty && email.contains("@") && email.contains(".") && !password.isEmpty
    }

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
                    Button {
                        guard !isLoading else { return }
                        isLoading = true
                        createChild(name, email, password)
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(1.1)
                            } else {
                                Text("Sukurti")
                            }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!formIsValid || isLoading)
                }
                .navigationTitle("Naujas vaikas")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Atšaukti") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Demo") {

                            name = MockCredentials.childName(index: mockedChildCounter)
                            email = MockCredentials.childEmail(index: mockedChildCounter)
                            password = MockCredentials.childPassword(index: mockedChildCounter)
                            mockedChildCounter += 1
                        }
                    }
                }
            }
        }
    }
}
