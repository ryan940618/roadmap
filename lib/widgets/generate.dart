import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class GenerateSheet extends StatefulWidget {
  final Function(List<LatLng>, List<Map<String, dynamic>>) onGenerate;

  const GenerateSheet({super.key, required this.onGenerate});

  @override
  State<GenerateSheet> createState() => _GenerateSheetState();
}

class _GenerateSheetState extends State<GenerateSheet> {
  final _formKey = GlobalKey<FormState>();

  int nodeCount = 100;
  int maxEdges = 200;
  double spaceSize = 1000;
  double scale = 0.0001;
  double centerLat = 22.649060;
  double centerLon = 120.326589;

  void _submit() {
    final result = _generateRoadmap();
    widget.onGenerate(result['nodes']!, result['edges']!);
    Navigator.of(context).pop();
  }

  Map<String, dynamic> _generateRoadmap() {
    final Random random = Random(10); // 固定随机种子

    // 生成节点
    List<List<int>> nodes = [];
    for (int i = 0; i < nodeCount; i++) {
      int x = random.nextInt(spaceSize.toInt());
      int y = random.nextInt(spaceSize.toInt());
      nodes.add([x, y]);
    }

    // 对节点进行排序
    nodes.sort((a, b) =>
        (a[0] * a[0] + a[1] * a[1]).compareTo(b[0] * b[0] + b[1] * b[1]));

    // 计算Delaunay三角剖分（此处用简单的方式替代）
    List<List<int>> edges = [];
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        double dist = sqrt(pow(nodes[i][0] - nodes[j][0], 2) +
            pow(nodes[i][1] - nodes[j][1], 2));
        edges.add([dist.toInt(), i, j]);
      }
    }

    // 根据距离排序并取前 maxEdges 条边
    edges.sort((a, b) => a[0].compareTo(b[0]));
    edges = edges.take(maxEdges).toList();

    // 创建节点列表（转换为经纬度）
    List<LatLng> nodeList = [];
    for (int i = 0; i < nodes.length; i++) {
      int x = nodes[i][0];
      int y = nodes[i][1];
      double lat = centerLat + (y - spaceSize / 2) * scale;
      double lon = centerLon + (x - spaceSize / 2) * scale;
      nodeList.add(LatLng(lat, lon));
    }

    // 创建边列表
    List<Map<String, dynamic>> edgeList = [];
    for (int i = 0; i < edges.length; i++) {
      edgeList.add({
        'id': i,
        'from': edges[i][1],
        'to': edges[i][2],
        'distance': edges[i][0]
      });
    }

    // 生成 road map 返回
    return {'nodes': nodeList, 'edges': edgeList};
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Wrap(
          runSpacing: 12,
          children: [
            const Text("參數",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildNumberField(
                "nodes數量", nodeCount, (v) => nodeCount = v.toInt()),
            _buildNumberField(
                "最大edges數量", maxEdges, (v) => maxEdges = v.toInt()),
            _buildNumberField(
                "空間大小", spaceSize, (v) => spaceSize = v.toDouble()),
            _buildNumberField(
                "座標比例(scale)", scale * 10000, (v) => scale = v / 10000,
                isDouble: true),
            _buildNumberField(
                "中心緯度", centerLat, (v) => centerLat = v.toDouble(),
                isDouble: true),
            _buildNumberField(
                "中心經度", centerLon, (v) => centerLon = v.toDouble(),
                isDouble: true),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.auto_fix_high),
                label: const Text("產生"),
                onPressed: _submit,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField(String label, num initial, Function(num) onChanged,
      {bool isDouble = false}) {
    return TextFormField(
      initialValue: initial.toString(),
      decoration:
          InputDecoration(labelText: label, border: const OutlineInputBorder()),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final parsed = isDouble ? double.tryParse(value) : int.tryParse(value);
        if (parsed != null) {
          onChanged(parsed);
        }
      },
    );
  }
}
