enum MockCredentials {
    static func email(index: Int = 0) -> String {
        "rimtastevas\(index)@gmail.com"
    }

    static func name(index: Int = 0) -> String {
        "Artūras\(index)"
    }

    static func password(index: Int = 0) -> String {
        "password\(index)"
    }

    static func childName(index: Int = 0) -> String {
        "Mažasis skaitytojas\(index)"
    }

    static func childEmail(index: Int = 0) -> String {
        "skaitytojo\(index)@email.com"
    }

    static func childPassword(index: Int = 0) -> String {
        if index == 0 {
            "pass\(index)"
        } else {
            "passssss\(index)"
        }
    }
}
