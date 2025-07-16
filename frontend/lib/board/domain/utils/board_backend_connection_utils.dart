import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:prodspace/board/domain/models/board_models.dart';

class BoardBackendConnectionUtils {
  static Future<String?> sendBoardItem(BoardItem item, String token) async {
    // Create json to send
    dynamic boardData = item.toJson();

    // Print resulted json
    debugPrint('boardData: ${jsonEncode(boardData)}');

    // Send request
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/workspaces/my/items'),
        headers: {
          'Authorization': "Bearer $token",
          'Content-Type': 'application/json',
        },
        body: jsonEncode(boardData),
      );

      // Return Success flag
      return (response.statusCode >= 200 && response.statusCode < 300) ? null : "${response.statusCode}: ${response.body}";
    } catch (e) {
      rethrow;
    }
  } 
}