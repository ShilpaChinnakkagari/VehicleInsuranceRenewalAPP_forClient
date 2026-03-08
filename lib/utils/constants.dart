import 'package:flutter/material.dart';

class AppConstants {
  static const String supabaseUrl = 'https://dzsdnxxixpfdbdixvmed.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR6c2RueHhpeHBmZGJkaXh2bWVkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4Nzg3NzEsImV4cCI6MjA4ODQ1NDc3MX0.FF0GEd0rAFxc_QFYQZCEVYAJjzvxxgYERQ2CHzfVI1c';
  
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color statusYellow = Color(0xFFF59E0B);
  static const Color statusGreen = Color(0xFF10B981);
  static const Color statusRed = Color(0xFFEF4444);
  static const Color rowBlue = Color(0xFFEFF6FF);
}

class StatusTypes {
  static const String notContacted = 'not_contacted';
  static const String contacted = 'contacted';
  static const String notResponded = 'not_responded';
  
  static Color getColor(String status) {
    switch(status) {
      case contacted:
        return AppConstants.statusGreen;
      case notResponded:
        return AppConstants.statusRed;
      default:
        return AppConstants.primaryBlue;
    }
  }
}