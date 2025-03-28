import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';

class FoodWaterLogPage extends StatefulWidget {
  final int petId;
  final String petName;

  const FoodWaterLogPage({required this.petId, required this.petName});

  @override
  _FoodWaterLogPageState createState() => _FoodWaterLogPageState();
}

class _FoodWaterLogPageState extends State<FoodWaterLogPage> {
  final DBHelper dbHelper = DBHelper();
  List<Map<String, dynamic>> foodLogs = [];
  List<Map<String, dynamic>> waterLogs = [];

  @override
  void initState() {
    super.initState();
    loadLogs();
  }

  Future<void> loadLogs() async {
    final allLogs = await dbHelper.getLogsForPet(widget.petId);
    setState(() {
      foodLogs = allLogs.where((log) => log['type'] == 'Food').toList();
      waterLogs = allLogs.where((log) => log['type'] == 'Water').toList();
    });
  }

  Future<void> addLog(String type) async {
    await dbHelper.addLog(widget.petId, type);
    await loadLogs();
  }

  String formatTime(String isoTime) {
    final dt = DateTime.parse(isoTime).toLocal();
    return DateFormat('MMMM d - h:mm a').format(dt);
  }

  String? getLastLogTime(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) return null;
    final latest = DateTime.parse(logs.first['timestamp']).toLocal();
    return DateFormat('h:mm a').format(latest);
  }

  @override
  Widget build(BuildContext context) {
    final lastFood = getLastLogTime(foodLogs);
    final lastWater = getLastLogTime(waterLogs);

    return Scaffold(
      appBar: AppBar(title: Text('${widget.petName} - Food/Water Log')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Food/Water Log',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 16),
            if (lastFood != null)
              Text('Last fed: $lastFood', style: TextStyle(fontSize: 16)),
            if (lastWater != null)
              Text(
                'Last given water: $lastWater',
                style: TextStyle(fontSize: 16),
              ),

            SizedBox(height: 20),
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Food log:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ...foodLogs.map(
                    (log) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '• ${formatTime(log['timestamp'])}',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Water log:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ...waterLogs.map(
                    (log) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '• ${formatTime(log['timestamp'])}',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Spacer(),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => addLog('Food'),
                  child: Text('Log Food'),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => addLog('Water'),
                  child: Text('Log Water'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
