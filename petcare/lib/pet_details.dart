import 'package:flutter/material.dart';
import 'db_helper.dart';

class PetDetailsPage extends StatefulWidget {
  final int petId;

  const PetDetailsPage({Key? key, required this.petId}) : super(key: key);

  @override
  PetDetailsState createState() => PetDetailsState();
}

class PetDetailsState extends State<PetDetailsPage> {
  final DBHelper dbHelper = DBHelper();
  Map<String, dynamic>? _pet;
  bool careTipsExpanded = false;
  bool illnessSymptomsExpanded = false;

  // Care tips data
  final Map<String, List<String>> careTips = {
    'Dog': [
      'pee alot dog', 
      'exccersie',
      ],

    'Cat': [
      'feed it water', 
      'celan litter box',
      ],

    'Bunny': [
      'food', 
      'clean',
      ],

    'Hamster': [
      'hampter', 
      'feed',
      ],
  };

  // Illness symptoms data
  final Map<String, List<String>> illnessSymptoms = {
    'Dog': [
      'dgog', 
      'listsysmtomsdaog',
      ],

    'Cat': [
      'list of', 
      'symtopms for cat',
      ],

    'Bunny': [
      'symtom bunn', 
      'symptom bunyn',
      ],

    'Hamster': [
      'symtoms hamster', 
      'symtoms hamster',
      ],
  };

  @override
  void initState() {
    super.initState();
    loadPetDetails();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_pet?['name'] ?? 'Pet Details')),
      body:
          _pet == null
              ? Center(child: CircularProgressIndicator())
              : Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Details
                    Text(
                      "Name: ${_pet!['name']}",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Type: ${_pet!['type']}",
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(
                      "Age: ${_pet!['age']} years",
                      style: TextStyle(fontSize: 18),
                    ),

                    SizedBox(height: 20),

                    // Tips Dropdown
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          careTipsExpanded = !careTipsExpanded;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Care Tips",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              careTipsExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (careTipsExpanded)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            careTips[_pet!['type']]?.map((tip) {
                              return Padding(
                                padding: EdgeInsets.only(left: 12, top: 6),
                                child: Text(
                                  "• $tip",
                                  style: TextStyle(fontSize: 16),
                                ),
                              );
                            }).toList() ??
                            [],
                      ),

                    SizedBox(height: 20),

                    // Illness Dropdown
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          illnessSymptomsExpanded = !illnessSymptomsExpanded;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Illness Symptoms",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              illnessSymptomsExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (illnessSymptomsExpanded)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            illnessSymptoms[_pet!['type']]?.map((symptom) {
                              return Padding(
                                padding: EdgeInsets.only(left: 12, top: 6),
                                child: Text(
                                  "• $symptom",
                                  style: TextStyle(fontSize: 16),
                                ),
                              );
                            }).toList() ??
                            [],
                      ),

                    SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text("Back"),
                    ),
                  ],
                ),
              ),
    );
  }
}
