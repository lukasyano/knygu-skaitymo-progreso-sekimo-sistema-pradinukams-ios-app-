enum RegistrationModels {
    static let registrationSuccessMessage = "Registracija sėkminga, šaunu! Dabar galėsite prisijungti. Ar prisimeni slaptazodį? :)"
    
    struct RoleSelection {
        var selected: Role
        var availableRoles: [Role]
    }
}
