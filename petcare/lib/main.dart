import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'pet_details.dart';

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
  String selectedType = 'Dog';
  List<Map<String, dynamic>> _pets = [];
  List<Map<String, dynamic>> _reminders = [];

  @override
  void initState() {
    super.initState();
    loadPets();
    loadReminders();
  }

  Future<void> loadPets() async {
    final pets = await dbHelper.getPets();
    setState(() {
      _pets = pets;
    });
  }

  Future<void> loadReminders() async {
    final reminders = await dbHelper.getAllReminders();
    setState(() {
      _reminders = reminders;
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
    loadReminders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pet Care Tracker')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "All Reminders:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            _reminders.isEmpty
                ? Text("No reminders yet.")
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      _reminders.map((r) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: HoverableReminder(
                            text: "• ${r['text']} (${r['pet_name']})",
                            onTap: () async {
                              await dbHelper.deleteReminder(r['id']);
                              loadReminders();
                            },
                          ),
                        );
                      }).toList(),
                ),

            SizedBox(height: 20),

            Center(
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
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                      });
                    },
                  ),
                  ElevatedButton(onPressed: addPet, child: Text('Add Pet')),
                ],
              ),
            ),

            SizedBox(height: 20),

            Text(
              "Pet List:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            _pets.isEmpty
                ? Center(child: Text('No pets added yet'))
                : Column(
                  children:
                      _pets.map((pet) {
                        return Card(
                          child: ListTile(
                            title: Text('${pet['name']} (${pet['type']})'),
                            subtitle: Text('Age: ${pet['age']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
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
                                    ).then((_) {
                                      loadReminders();
                                    });
                                  },
                                  child: Text("View Details"),
                                ),
                                SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => deletePet(pet['id']),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                ),
          ],
        ),
      ),
    );
  }
}

class HoverableReminder extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const HoverableReminder({Key? key, required this.text, required this.onTap})
    : super(key: key);

  @override
  hoverableReminderState createState() => hoverableReminderState();
}

class hoverableReminderState extends State<HoverableReminder> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.text,
          style: TextStyle(
            decoration:
                hovering ? TextDecoration.lineThrough : TextDecoration.none,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
