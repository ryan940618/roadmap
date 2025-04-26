import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  List<LatLng> nodes = [];
  List<Map<String, int>> edges = [];
  List<LatLng> highlightPathPoints = [];

  @override
  void initState() {
    super.initState();
    loadRoadMap();
  }

  Future<void> loadRoadMap() async {
    final String data = await rootBundle.loadString('assets/roadmap.json');
    final jsonResult = json.decode(data);

    for (var node in jsonResult['nodes']) {
      double lat = node['lat'];
      double lon = node['lon'];
      nodes.add(LatLng(lat, lon));
    }

    for (var edge in jsonResult['edges']) {
      edges.add({'from': edge['from'], 'to': edge['to']});
    }

    setState(() {});
  }

  void highlightPath(List<int> nodeIndexes) {
    highlightPathPoints = [];
    for (var index in nodeIndexes) {
      if (index >= 0 && index < nodes.length) {
        highlightPathPoints.add(nodes[index]);
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('道路圖資分析與計算 Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.route),
            onPressed: () {
              highlightPath([0, 2, 5, 10, 20]);
            },
          )
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter:
              nodes.isNotEmpty ? nodes[0] : const LatLng(22.6490, 120.3265),
          initialZoom: 15,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}",
            userAgentPackageName: 'com.ryan940618.roadmap',
          ),
          PolylineLayer(
            polylines: [
              ...edges.map((e) {
                return Polyline(
                  points: [
                    nodes[e['from']!],
                    nodes[e['to']!],
                  ],
                  strokeWidth: 2.0,
                  color: Colors.grey,
                );
              }),
              if (highlightPathPoints.length >= 2)
                Polyline(
                  points: highlightPathPoints,
                  strokeWidth: 4.0,
                  color: Colors.red,
                )
            ],
          ),
          MarkerLayer(
            markers: nodes.map((node) {
              return Marker(
                width: 10,
                height: 10,
                point: node,
                child: const Icon(Icons.circle, size: 6, color: Colors.blue),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
