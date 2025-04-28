import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class DataPage extends StatelessWidget {
  final List<LatLng> nodes;
  final List<Map<String, dynamic>> edges;
  final void Function(
      List<LatLng> newNodes, List<Map<String, dynamic>> newEdges) onImport;

  const DataPage({
    super.key,
    required this.nodes,
    required this.edges,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                await exportData(context, nodes, edges);
              },
              child: const Text('匯出'),
            ),
            ElevatedButton(
              onPressed: () async {
                final imported = await importData(context);
                if (imported != null) {
                  onImport(imported['nodes'], imported['edges']);
                  Navigator.pop(context);
                }
              },
              child: const Text('匯入'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> exportData(BuildContext context, List<LatLng> nodes,
    List<Map<String, dynamic>> edges) async {
  Map<String, dynamic> data = {
    'nodes': List.generate(
        nodes.length,
        (i) => {
              'id': i,
              'x': 0,
              'y': 0,
              'lat': nodes[i].latitude,
              'lon': nodes[i].longitude,
            }),
    'edges': List.generate(
        edges.length,
        (i) => {
              'id': i,
              'from': edges[i]['from'],
              'to': edges[i]['to'],
              'distance': edges[i]['distance'],
            }),
  };

  String jsonString = jsonEncode(data);

  String? path = await FilePicker.platform.saveFile(
    fileName: 'roadmap.json',
    type: FileType.custom,
    allowedExtensions: ['json'],
  );

  if (path != null) {
    File file = File(path);
    await file.writeAsString(jsonString);
  }
}

Future<Map<String, dynamic>?> importData(BuildContext context) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
  );

  if (result != null) {
    String path = result.files.single.path!;
    String jsonString = await File(path).readAsString();
    Map<String, dynamic> data = jsonDecode(jsonString);

    List<LatLng> importedNodes = List<LatLng>.from(
      data['nodes'].map((n) => LatLng(n['lat'], n['lon'])),
    );
    List<Map<String, dynamic>> importedEdges =
        List<Map<String, dynamic>>.from(data['edges']);

    return {
      'nodes': importedNodes,
      'edges': importedEdges,
    };
  }
  return null;
}
