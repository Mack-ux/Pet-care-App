import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'foodwater.dart';

class PetDetailsPage extends StatefulWidget {
  final int petId;

  const PetDetailsPage({Key? key, required this.petId}) : super(key: key);

  @override
  PetDetailsState createState() => PetDetailsState();
}

class PetDetailsState extends State<PetDetailsPage> {
  final DBHelper dbHelper = DBHelper();
  Map<String, dynamic>? _pet;
  final TextEditingController _reminderController = TextEditingController();
  List<Map<String, dynamic>> _reminders = [];
  bool careTipsExpanded = false;
  bool illnessSymptomsExpanded = false;

  final Map<String, List<String>> careTips = {
    'Dog': ['Walk the dog daily', 'Regular grooming'],
    'Cat': ['Clean litter box', 'Provide scratching post'],
    'Bunny': ['Give hay and space', 'Clean cage regularly'],
    'Hamster': ['Use clean bedding', 'Provide wheel and chew toys'],
  };

  final Map<String, List<String>> illnessSymptoms = {
    'Dog': ['Vomiting', 'Itchy skin'],
    'Cat': ['Hairballs', 'Lethargy'],
    'Bunny': ['Runny nose', 'Overgrown teeth'],
    'Hamster': ['Wet tail', 'Fur loss'],
  };

  @override
  void initState() {
    super.initState();
    loadPetDetails();
    loadReminders();
  }

  Future<void> loadPetDetails() async {
    List<Map<String, dynamic>> pets = await dbHelper.getPets();
    Map<String, dynamic>? pet = pets.firstWhere(
      (p) => p['id'] == widget.petId,
      orElse: () => {},
    );

    setState(() {
      _pet = pet.isNotEmpty ? pet : null;
    });
  }

  Future<void> loadReminders() async {
    final data = await dbHelper.getRemindersForPet(widget.petId);
    setState(() {
      _reminders = data;
    });
  }

  Future<void> addReminder() async {
    final text = _reminderController.text.trim();
    if (text.isNotEmpty) {
      await dbHelper.addReminder(widget.petId, text);
      _reminderController.clear();
      loadReminders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_pet?['name'] ?? 'Pet Details')),
      body: _pet == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Name: ${_pet!['name']}",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text("Type: ${_pet!['type']}", style: TextStyle(fontSize: 18)),
                    Text("Age: ${_pet!['age']} years", style: TextStyle(fontSize: 18)),

                    SizedBox(height: 20),

                    buildDropdown("Care Tips", careTipsExpanded, () {
                      setState(() => careTipsExpanded = !careTipsExpanded);
                    }, careTips[_pet!['type']] ?? []),

                    SizedBox(height: 10),

                    buildDropdown("Illness Symptoms", illnessSymptomsExpanded, () {
                      setState(() => illnessSymptomsExpanded = !illnessSymptomsExpanded);
                    }, illnessSymptoms[_pet!['type']] ?? []),

                    SizedBox(height: 20),

                    Text(
                      "Add Reminder:",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _reminderController,
                            decoration: InputDecoration(hintText: 'Enter reminder...'),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(onPressed: addReminder, child: Text("Add")),
                      ],
                    ),

                    SizedBox(height: 20),

                    Text("Reminders:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ..._reminders.map(
                      (r) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: HoverableReminder(
                          text: "• ${r['text']}",
                          onTap: () async {
                            await dbHelper.deleteReminder(r['id']);
                            loadReminders();
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FoodWaterLogPage(
                              petId: _pet!['id'],
                              petName: _pet!['name'],
                            ),
                          ),
                        );
                      },
                      child: Text("Food & Water Log"),
                    ),

                    SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Back"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildDropdown(
    String title,
    bool expanded,
    VoidCallback toggle,
    List<String> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: toggle,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Icon(expanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
        ),
        if (expanded)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items
                .map((item) => Padding(
                      padding: EdgeInsets.only(left: 12, top: 6),
                      child: Text("• $item", style: TextStyle(fontSize: 16)),
                    ))
                .toList(),
          ),
      ],
    );
  }
}

class HoverableReminder extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const HoverableReminder({Key? key, required this.text, required this.onTap}) : super(key: key);

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
            decoration: hovering ? TextDecoration.lineThrough : TextDecoration.none,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
