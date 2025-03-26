import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'pet_details.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
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

  @override
  void initState() {
    super.initState();
    loadPets();
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
