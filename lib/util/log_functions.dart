void errorLog<T>(T text) {
  print('\x1B[31m$text\x1B[0m');
}

void greenLog<T>(T text) {
  print('\x1B[32m$text\x1B[0m');
}

void debugLog<T>(T text) {
  print('\x1B[35m$text\x1B[0m');
}



void warningLog<T>(T text) {
  print('\x1B[33m$text\x1B[0m');
}

void infoLog<T>(T text) {
  print('\x1B[34m$text\x1B[0m');
}
