
import 'package:flutter/material.dart';

class WorkspacePage extends StatelessWidget {
  const WorkspacePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: WorkspaceBody());
  }
}

class WorkspaceBody extends StatefulWidget {
  const WorkspaceBody({super.key});

  @override
  State<WorkspaceBody> createState() => _WorkspaceBodyState();
}

class _WorkspaceBodyState extends State<WorkspaceBody> {
  // For now like this
  @override
  Widget build(BuildContext context) {
    // var colorScheme = Theme.of(context).colorScheme;
    return Scaffold(body: Text("Here should be workspace"));
  }
}