import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class DataPage extends StatefulWidget {
  @override
  _DataPageState createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  List<Map<String, dynamic>> nodes = [];
  List<Map<String, dynamic>> edges = [];

  Future<void> importData(String type) async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      String filePath = result.files.single.path!;
      String fileContent = await File(filePath).readAsString();
      Map<String, dynamic> data = jsonDecode(fileContent);

      setState(() {
        if (type == 'nodes') {
          nodes = List<Map<String, dynamic>>.from(data['nodes']);
        } else if (type == 'edges') {
          edges = List<Map<String, dynamic>>.from(data['edges']);
        }
      });
    }
  }

  Future<void> exportData(String type) async {
    Map<String, dynamic> data = {
      'nodes': nodes,
      'edges': edges,
    };
    String jsonData = jsonEncode(data);

    final result = await FilePicker.platform.saveFile(
      fileName: type == 'nodes' ? 'nodes.json' : 'edges.json',
    );

    if (result != null) {
      await File(result).writeAsString(jsonData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成功匯出 ${type == 'nodes' ? 'Nodes' : 'Edges'}')),
      );
    }
  }

  void _showImportExportSheet(String action, String type) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Text(
                action == 'import' ? '匯入 $type' : '匯出 $type',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (action == 'import') {
                    importData(type);
                  } else {
                    exportData(type);
                  }
                  Navigator.pop(context);
                },
                child: Text(action == 'import' ? '選擇檔案匯入' : '匯出到檔案'),
              ),
            ],
          ),
        );
      },
    );
  }

  // AppBar 和操作按鈕
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('匯入/匯出 節點和邊'),
        actions: [
          IconButton(
            icon: const Icon(Icons.import_export),
            onPressed: () {
              _showImportExportSheet('import', 'nodes');
            },
          ),
          IconButton(
            icon: const Icon(Icons.import_export),
            onPressed: () {
              _showImportExportSheet('import', 'edges');
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('選擇匯入/匯出的操作'),
      ),
    );
  }
}
