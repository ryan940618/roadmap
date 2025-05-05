import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/data.dart';
import '../widgets/editor.dart';
import '../widgets/generate.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  int? selectedNode;
  int? startNode;
  int? endNode;
  List<int> waypoints = [];
  List<int> path = [];

  List<LatLng> nodes = [];
  List<Map<String, dynamic>> edges = [];
  List<LatLng> highlightPathPoints = [];
  final MapController _mapController = MapController();

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

    if (highlightPathPoints.isNotEmpty) {
      LatLng center = _calculateCenter(highlightPathPoints);
      _mapController.move(center, 15);
    }

    setState(() {});
  }

  LatLng _calculateCenter(List<LatLng> points) {
    double latSum = 0;
    double lonSum = 0;
    for (var point in points) {
      latSum += point.latitude;
      lonSum += point.longitude;
    }
    return LatLng(latSum / points.length, lonSum / points.length);
  }

  List<int> dijkstra(List<LatLng> nodes, List<Map<String, dynamic>> edges,
      int start, int goal) {
    Map<int, List<Map<String, dynamic>>> graph = {}; //adjacency list
    for (var edge in edges) {
      int from = edge['from']!;
      int to = edge['to']!;
      double distance = const Distance().as(
        LengthUnit.Meter,
        nodes[from],
        nodes[to],
      );
      graph.putIfAbsent(from, () => []).add({'node': to, 'cost': distance});
      graph.putIfAbsent(to, () => []).add({'node': from, 'cost': distance});
    }

    //dijkstra setup
    Map<int, double> dist = {};
    Map<int, int?> prev = {};
    List<int> Q = [];

    for (int node = 0; node < nodes.length; node++) {
      dist[node] = double.infinity;
      prev[node] = null;
      Q.add(node);
    }
    dist[start] = 0;

    //dijkstra
    while (Q.isNotEmpty) {
      //找Q裡面dist最小的node
      Q.sort((a, b) => dist[a]!.compareTo(dist[b]!));
      int u = Q.removeAt(0);

      if (u == goal) break; //若為目標就結束

      for (var neighbor in graph[u] ?? []) {
        int v = neighbor['node'];
        double cost = neighbor['cost'];
        double alt = dist[u]! + cost;
        if (alt < dist[v]!) {
          dist[v] = alt;
          prev[v] = u;
        }
      }
    }

    //還原最短路徑
    List<int> path = [];
    int? u = goal;
    while (u != null) {
      path.insert(0, u);
      u = prev[u];
    }
    return path;
  }

  void navigate(int start, int goal) {
    List<int> path = dijkstra(nodes, edges, start, goal);
    highlightPath(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(160),
        child: AppBar(
          title: const Text('道路圖資分析與計算 Demo'),
          actions: [
            Row(children: [
              IconButton(
                icon: const Icon(Icons.edit_attributes_rounded),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const RoadmapEditor()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.generating_tokens_rounded),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => GenerateSheet(
                      onGenerate: (nodes, edges) {
                        setState(() {
                          this.nodes = nodes;
                          this.edges = edges;
                        });
                      },
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => DataPage(
                      nodes: nodes,
                      edges: edges,
                      onImport: (newNodes, newEdges) {
                        setState(() {
                          nodes = newNodes;
                          edges = newEdges;
                        });
                      },
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  resetNavigation();
                },
              ),
            ]),
          ],
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Text('起點: '),
                      DropdownButton<int?>(
                        value: startNode,
                        hint: const Text('請選擇'),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('請選擇'),
                          ),
                          ...List.generate(nodes.length, (index) {
                            return DropdownMenuItem(
                              value: index,
                              child: Text('n$index'),
                            );
                          })
                        ],
                        onChanged: (value) {
                          setState(() {
                            startNode = value;
                          });
                        },
                      ),
                      const Text('終點: '),
                      DropdownButton<int?>(
                        value: endNode,
                        hint: const Text('請選擇'),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('請選擇'),
                          ),
                          ...List.generate(nodes.length, (index) {
                            return DropdownMenuItem(
                              value: index,
                              child: Text('n$index'),
                            );
                          })
                        ],
                        onChanged: (value) {
                          setState(() {
                            endNode = value;
                          });
                        },
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: (startNode != null && endNode != null)
                            ? () {
                                path = dijkstra(
                                    nodes, edges, startNode!, endNode!);
                                highlightPath(path);
                                setState(() {});
                              }
                            : null,
                        icon: const Icon(Icons.navigation),
                        label: const Text('計算路線'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      )
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Visibility(
                        visible: selectedNode != null,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: Text(
                          '選中: n$selectedNode',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: selectedNode != null
                            ? () {
                                setState(() {
                                  startNode = selectedNode;
                                  selectedNode = null;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.flag),
                        label: const Text('設為起點'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: selectedNode != null
                            ? () {
                                setState(() {
                                  endNode = selectedNode;
                                  selectedNode = null;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.location_on),
                        label: const Text('設為終點'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
      body: FlutterMap(
        mapController: _mapController,
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
          PolylineLayer(polylines: buildPolylines()),
          MarkerLayer(markers: buildMarkers()),
        ],
      ),
    );
  }

  List<Marker> buildMarkers() {
    return nodes.asMap().entries.map((entry) {
      int index = entry.key;
      LatLng node = entry.value;
      return Marker(
        width: 30,
        height: 30,
        point: node,
        child: GestureDetector(
          onTap: () {
            setState(() {
              if (waypoints.contains(index)) {
                waypoints.remove(index);
              } else {
                selectedNode = index;
              }
            });
          },
          child: Icon(
            index == startNode
                ? Icons.play_arrow
                : index == endNode
                    ? Icons.flag
                    : waypoints.contains(index)
                        ? Icons.star
                        : Icons.circle,
            color: index == selectedNode
                ? Colors.orange
                : index == startNode
                    ? Colors.green
                    : index == endNode
                        ? Colors.red
                        : waypoints.contains(index)
                            ? Colors.amber
                            : Colors.blue,
            size: index == startNode
                ? 30
                : index == endNode
                    ? 25
                    : 20,
          ),
        ),
      );
    }).toList();
  }

  List<Polyline> buildPolylines() {
    List<Polyline> polylines = [];

    polylines.addAll(edges.map((e) {
      return Polyline(
        points: [
          nodes[e['from']!],
          nodes[e['to']!],
        ],
        strokeWidth: 2.0,
        color: Colors.grey,
      );
    }));

    if (path.isNotEmpty) {
      List<LatLng> pathPoints = path.map((i) => nodes[i]).toList();
      polylines.add(
        Polyline(
          points: pathPoints,
          strokeWidth: 5.0,
          color: Colors.redAccent,
        ),
      );
    }

    return polylines;
  }

  int findNearestNode(LatLng latlng) {
    double minDist = double.infinity;
    int nearest = 0;
    for (int i = 0; i < nodes.length; i++) {
      double dist = const Distance().as(
        LengthUnit.Meter,
        nodes[i],
        latlng,
      );
      if (dist < minDist) {
        minDist = dist;
        nearest = i;
      }
    }
    return nearest;
  }

  void resetNavigation() {
    setState(() {
      startNode = null;
      endNode = null;
      selectedNode = null;
      path.clear();
    });
  }
}
