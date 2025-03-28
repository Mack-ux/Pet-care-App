import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'pet_details.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';


void main() {
  runApp(PetApp());
}

class PetApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pet Care App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PetHomePage(),
    );
  }
}

class PetHomePage extends StatefulWidget {
  @override
  PetHomePageState createState() => PetHomePageState();
}

class PetHomePageState extends State<PetHomePage> {
  final DBHelper dbHelper = DBHelper();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  String selectedType = 'Dog'; // Default pet dropdown
  List<Map<String, dynamic>> _pets = [];
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    loadPets();
    _initializeNotifications();
    tz.initializeTimeZones();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initSettings = InitializationSettings(android: androidInitSettings);
    await _notificationsPlugin.initialize(initSettings);
  }

  Future<void> requestExactAlarmPermission() async {
  final permissionStatus = await Permission.notification.request();
  
  if (permissionStatus.isGranted) {
    print("Permission granted! You can schedule exact alarms.");
  } else {
    print("Permission denied! Cannot schedule exact alarms.");
  }
}


  Future<void> _scheduleNotification(String title, String body, TimeOfDay time) async {
    
    await requestExactAlarmPermission();

    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails('reminder_id', 'Pet Reminders',
        importance: Importance.high, priority: Priority.high);
    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      0,
      title,
      body,
      tzScheduledTime,
      notificationDetails,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
      
    );
  }

  Future<void> _showReminderDialog() async {
    String selectedType = 'Feeding';
    TimeOfDay selectedTime = TimeOfDay.now();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Set Reminder"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<String>(
              value: selectedType,
              onChanged: (value) {
                setState(() => selectedType = value!);
              },
              items: ["Feeding", "Vet Visit", "Grooming"].map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () async {
                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: selectedTime,
                );
                if (pickedTime != null) {
                  setState(() => selectedTime = pickedTime);
                }
              },
              child: Text("Select Time: ${selectedTime.format(context)}"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              _scheduleNotification(
                "Pet Reminder", 
                "$selectedType reminder for ['Pet']}", 
                selectedTime,
              );
              Navigator.pop(context);
            },
            child: Text("Set Reminder"),
          ),
        ],
      ),
    );
  }


  Future<void> loadPets() async {
    final pets = await dbHelper.getPets();
    setState(() {
      _pets = pets;
    });
  }

  Future<void> addPet() async {
    if (nameController.text.isEmpty || ageController.text.isEmpty) return;
    int age = int.tryParse(ageController.text) ?? 0;
    await dbHelper.addPet(nameController.text, selectedType, age);
    nameController.clear();
    ageController.clear();
    loadPets();
  }

  Future<void> deletePet(int id) async {
    await dbHelper.deletePet(id);
    loadPets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pet Care Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Pet Name'),
            ),
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Pet Age'),
            ),
            DropdownButton<String>(
              value: selectedType,
              items:
                  ['Dog', 'Cat', 'Bunny', 'Hamster']
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                  selectedType = value!;
                });
              },
            ),
            SizedBox(height: 10),
            ElevatedButton(onPressed: addPet, child: Text('Add Pet')),
            ElevatedButton(
                    onPressed: _showReminderDialog,
                    child: Text("Set Reminder"),
                  ),
                  SizedBox(height: 20), 
            SizedBox(height: 20),
            Expanded(
              child:
                  _pets.isEmpty
                      ? Center(child: Text('No pets added yet'))
                      : ListView.builder(
                        itemCount: _pets.length,
                        itemBuilder: (context, index) {
                          final pet = _pets[index];
                          return Card(
                            child: ListTile(
                              title: Text('${pet['name']} (${pet['type']})'),
                              subtitle: Text('Age: ${pet['age']}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // View Details Button
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => PetDetailsPage(
                                                petId: pet['id'],
                                              ),
                                        ),
                                      );
                                    },
                                    child: Text("View Details"),
                                  ),
                                  SizedBox(width: 8),

                                  
                                  // Delete Button
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => deletePet(pet['id']),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
