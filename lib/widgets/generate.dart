import 'package:flutter/material.dart';
import 'dart:math';

import 'package:latlong2/latlong.dart';

class GenerateSheet extends StatefulWidget {
  final void Function(List<LatLng>, List<Map<String, dynamic>>)? onGenerate;

  const GenerateSheet({super.key, this.onGenerate});

  @override
  State<GenerateSheet> createState() => _GenerateSheetState();
}

class _GenerateSheetState extends State<GenerateSheet> {
  int nodeCount = 20;
  double maxDistance = 0.02;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('產生道路網參數',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('節點數量:'),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: nodeCount.toDouble(),
                  min: 5,
                  max: 100,
                  divisions: 95,
                  label: nodeCount.toString(),
                  onChanged: (value) {
                    setState(() {
                      nodeCount = value.toInt();
                    });
                  },
                ),
              ),
              Text('$nodeCount')
            ],
          ),
          Row(
            children: [
              const Text('最大邊距離:'),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: maxDistance,
                  min: 0.005,
                  max: 0.1,
                  divisions: 95,
                  label: maxDistance.toStringAsFixed(3),
                  onChanged: (value) {
                    setState(() {
                      maxDistance = value;
                    });
                  },
                ),
              ),
              Text('${(maxDistance * 1000).toStringAsFixed(0)}m')
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final result = _generateRoadmap(nodeCount, maxDistance);
              widget.onGenerate?.call(result['nodes']!, result['edges']!);
              Navigator.pop(context);
            },
            child: const Text('產生'),
          )
        ],
      ),
    );
  }

  Map<String, dynamic> _generateRoadmap(int count, double maxDist) {
    final rng = Random();
    final List<LatLng> nodes = [];
    final List<Map<String, dynamic>> edges = [];
    const double baseLat = 22.6490;
    const double baseLon = 120.3265;

    for (int i = 0; i < count; i++) {
      double lat = baseLat + rng.nextDouble() * 0.02;
      double lon = baseLon + rng.nextDouble() * 0.02;
      nodes.add(LatLng(lat, lon));
    }

    int edgeId = 0;
    for (int i = 0; i < count; i++) {
      for (int j = i + 1; j < count; j++) {
        double d = _latLonDist(nodes[i], nodes[j]);
        if (d <= maxDist) {
          edges.add({"id": edgeId++, "from": i, "to": j, "distance": d});
        }
      }
    }

    return {"nodes": nodes, "edges": edges};
  }

  double _latLonDist(LatLng a, LatLng b) {
    double dx = a.latitude - b.latitude;
    double dy = a.longitude - b.longitude;
    return sqrt(dx * dx + dy * dy);
  }
}
