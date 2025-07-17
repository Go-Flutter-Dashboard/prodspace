import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:prodspace/board/domain/models/board_models.dart';

class BoardBackendConnectionUtils {
  static Future<String?> sendBoardItem(BoardItem item, String token) async {
    // Create json to send
    dynamic boardData = item.toJson();

    debugPrint(boardData.toString());

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

  static Future<List<Map<String, dynamic>>> getWorkspaceItems(String token) async {
    // Send request
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/workspaces/my'),
        headers: {
          'Authorization': "Bearer $token",
          'Content-Type': 'application/json',
        },
      );
      final items = jsonDecode(response.body)["items"];
      if (items == null) {
        return [];
      }
      List<Map<String, dynamic>> result = [];
      for (int i = 0; i < items.length; i++) {
        result.add(items[i] as Map<String, dynamic>);
      }
      return result;
    } catch (e) {
      rethrow;
    }
  }

  static Future<BoardItem> createBoardItem(Map<String, dynamic> json) async {
    debugPrint(json.toString());
    if (json.containsKey("drawing")) {
      return BoardItemPath(DrawPath.fromJson(json));
    } else {
      return BoardItemObject(BoardObject.fromJson(json));
    }
  }
}