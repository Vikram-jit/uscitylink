class AppExceptions implements Exception {
  final _message;
  final _prefix;

  AppExceptions([this._message, this._prefix]);

  @override
  String toString() {
    return '$_prefix$_message';
  }
}

class InternetException extends AppExceptions {
  InternetException([String message = ""])
      : super(message, 'No Internet Connection');
}

class RequestTimeout extends AppExceptions {
  RequestTimeout([String message = ""]) : super(message, 'Request Time out: ');
}

class ServerException extends AppExceptions {
  ServerException([String message = ""]) : super(message, 'Server Error: ');
}
