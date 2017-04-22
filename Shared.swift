final class Shared {
    static let shared = Shared() //lazy init, and it only runs once
    
    // enables sharing of data across different ViewControllers but if u need persistors use SQLite
    var selectedUser : String = ""
    var successfulLogin : Bool = false
    var myUserLogin : String = ""
    var registrationMode : Bool = false
}
