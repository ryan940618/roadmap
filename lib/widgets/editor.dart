import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:file_picker/file_picker.dart';

class Node {
  final int id;
  double lat, lon;
  Node({required this.id, required this.lat, required this.lon});

  Map<String, dynamic> toJson() => {'id': id, 'lat': lat, 'lon': lon};
}

class Edge {
  final int id;
  final int from, to;
  double distance;
  Edge(
      {required this.id,
      required this.from,
      required this.to,
      required this.distance});

  Map<String, dynamic> toJson() =>
      {'id': id, 'from': from, 'to': to, 'distance': distance};
}

class RoadmapEditor extends StatefulWidget {
  const RoadmapEditor({super.key});
  @override
  State<RoadmapEditor> createState() => _RoadmapEditorState();
}

class _RoadmapEditorState extends State<RoadmapEditor> {
  final List<Node> nodes = [];
  final List<Edge> edges = [];
  int nodeIdCounter = 0;
  int edgeIdCounter = 0;
  int? selectedNodeId;
  int? startId, endId;

  final mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Roadmap Editor"),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportRoadmap,
          ),
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: _importRoadmap,
          ),
        ],
      ),
      body: Row(
        children: [
          // Side panel
          SizedBox(
            width: 200,
            child: Column(
              children: [
                DropdownButton<int?>(
                  hint: const Text("Start Node"),
                  value: startId,
                  items: nodes
                      .map((n) => DropdownMenuItem(
                          value: n.id, child: Text("Node ${n.id}")))
                      .toList(),
                  onChanged: (v) => setState(() => startId = v),
                ),
                DropdownButton<int?>(
                  hint: const Text("End Node"),
                  value: endId,
                  items: nodes
                      .map((n) => DropdownMenuItem(
                          value: n.id, child: Text("Node ${n.id}")))
                      .toList(),
                  onChanged: (v) => setState(() => endId = v),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (startId != null && endId != null && startId != endId) {
                      final fromNode = nodes.firstWhere((n) => n.id == startId);
                      final toNode = nodes.firstWhere((n) => n.id == endId);
                      final dist = const Distance().as(
                          LengthUnit.Meter,
                          LatLng(fromNode.lat, fromNode.lon),
                          LatLng(toNode.lat, toNode.lon));
                      setState(() {
                        edges.add(Edge(
                            id: edgeIdCounter++,
                            from: fromNode.id,
                            to: toNode.id,
                            distance: dist));
                      });
                    }
                  },
                  child: const Text("Add Edge"),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    children: nodes.map((n) {
                      return ListTile(
                        title: Text("Node ${n.id}"),
                        selected: n.id == selectedNodeId,
                        onTap: () => setState(() => selectedNodeId = n.id),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteNode(n.id),
                        ),
                      );
                    }).toList(),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: const LatLng(25.0330, 121.5654),
                initialZoom: 13,
                onTap: (tapPosition, latlng) {
                  setState(() {
                    nodes.add(Node(
                        id: nodeIdCounter++,
                        lat: latlng.latitude,
                        lon: latlng.longitude));
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "http://mt1.google.com/vt/lyrs=r&x={x}&y={y}&z={z}",
                  userAgentPackageName: 'com.example.app',
                ),
                PolylineLayer(
                  polylines: edges.map((e) {
                    final from = nodes.firstWhere((n) => n.id == e.from);
                    final to = nodes.firstWhere((n) => n.id == e.to);
                    return Polyline(points: [
                      LatLng(from.lat, from.lon),
                      LatLng(to.lat, to.lon)
                    ], color: Colors.red, strokeWidth: 2);
                  }).toList(),
                ),
                MarkerLayer(
                  markers: nodes.map((n) {
                    return Marker(
                      width: 30,
                      height: 30,
                      point: LatLng(n.lat, n.lon),
                      child: GestureDetector(
                        onTap: () => setState(() => selectedNodeId = n.id),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: n.id == selectedNodeId
                                ? Colors.blue
                                : Colors.green,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _deleteNode(int id) {
    setState(() {
      nodes.removeWhere((n) => n.id == id);
      edges.removeWhere((e) => e.from == id || e.to == id);
      if (selectedNodeId == id) selectedNodeId = null;
      if (startId == id) startId = null;
      if (endId == id) endId = null;
    });
  }

  Future<void> _exportRoadmap() async {
    // 建立 ID 對應表：舊 ID → 新連續 ID（0 開始）
    final idMap = <int, int>{};
    for (int i = 0; i < nodes.length; i++) {
      idMap[nodes[i].id] = i;
    }

    // 重建 nodes 與 edges，套用新的 ID
    final exportedNodes = nodes.asMap().entries.map((entry) {
      final newId = entry.key;
      final node = entry.value;
      return {
        'id': newId,
        'lat': node.lat,
        'lon': node.lon,
      };
    }).toList();

    final exportedEdges = edges
        .map((e) {
          // 避免匯出不存在的點（已被刪除）
          if (!idMap.containsKey(e.from) || !idMap.containsKey(e.to))
            return null;
          return {
            'id': idMap[e.id] ?? 0, // 你可以也讓 edge id 連續，或保持不變
            'from': idMap[e.from],
            'to': idMap[e.to],
            'distance': e.distance,
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    final data = {
      'nodes': exportedNodes,
      'edges': exportedEdges,
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    String? result = await FilePicker.platform.saveFile(
      fileName: 'roadmap.json',
      allowedExtensions: ['json'],
      type: FileType.custom,
    );

    if (result != null) {
      File file = File(result);
      await file.writeAsString(jsonStr, flush: true);
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("匯出成功（ID 已重新編號）")));
  }

  Future<void> _importRoadmap() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      setState(() {
        nodes.clear();
        edges.clear();
        nodeIdCounter = 0;
        edgeIdCounter = 0;
        for (var n in decoded['nodes']) {
          nodes.add(Node(id: n['id'], lat: n['lat'], lon: n['lon']));
          nodeIdCounter =
              nodeIdCounter < n['id'] + 1 ? n['id'] + 1 : nodeIdCounter;
        }
        for (var e in decoded['edges']) {
          edges.add(Edge(
              id: e['id'],
              from: e['from'],
              to: e['to'],
              distance: e['distance']));
          edgeIdCounter =
              edgeIdCounter < e['id'] + 1 ? e['id'] + 1 : edgeIdCounter;
        }
      });
    }
  }
}
