class User {
  static String email = "";
  static String password = "";
  static String authToken = "";
  static String name = "";

  User.map(dynamic obj) {
    email = obj["email"];
    password = obj["password"];
    authToken = obj["auth_token"];
    name = obj["name"];
  }

  static Map<String, dynamic> toMap() {
    var map = <String, dynamic>{};
    map["email"] = email;
    map["password"] = password;
    map["authToken"] = authToken;
    map["name"] = name;
    return map;
  }

  static void removeUser() {
    email = password = authToken = name = "";
  }
}
