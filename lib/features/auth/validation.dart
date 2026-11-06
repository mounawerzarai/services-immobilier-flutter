bool isValidEmail(String v) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim());

bool isValidPassword(String v) => v.length >= 6;
