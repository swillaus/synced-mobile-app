class User {
  static int userId = 0;
  static String email = "";
  static String password = "";
  static String authToken = "";
  static String name = "";

  User.map(dynamic obj) {
    userId = obj['userId'];
    email = obj["email"];
    password = obj["password"];
    authToken = obj["auth_token"];
    name = obj["name"];
  }

  static Map<String, dynamic> toMap() {
    var map = <String, dynamic>{};
    map["userId"] = userId;
    map["email"] = email;
    map["password"] = password;
    map["authToken"] = authToken;
    map["name"] = name;
    return map;
  }

  static void removeUser() {
    email = password = authToken = name = "";
    userId = 0;
  }
}
