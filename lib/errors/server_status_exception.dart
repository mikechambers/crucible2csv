class ServerStatusException implements Exception {
  String message;
  int code;

  ServerStatusException({this.message, this.code});

  String toString() {
    return "ServerStatusException : code $code : $message";
  }
}