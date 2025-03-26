import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:browser_extension/providers/settings.dart';
import 'package:browser_extension/utils/generation.dart';
import 'package:browser_extension/utils/read_csv.dart';
import 'package:browser_extension/utils/Saver/saver.dart';
import 'package:browser_extension/web/interop.dart';
import 'package:browser_extension/widgets/settings.dart';

//import '' if (dart.library.html) 'package:browser_extension/web/interop.dart';

class NameGeneratorPage extends StatefulWidget {
  const NameGeneratorPage({super.key});

  @override
  State<NameGeneratorPage> createState() => _NameGeneratorPageState();
}

class _NameGeneratorPageState extends State<NameGeneratorPage> {
  bool _isButtonDisabled = false;

  late List<String> names;
  late List<double> nameFreq;
  late List<String> surNames;
  late List<double> surNamesFreq;
  late List<String> cities;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _datecontroller = TextEditingController();
  final TextEditingController _countrycontroller = TextEditingController();
  final TextEditingController _citycontroller = TextEditingController();
  final TextEditingController _addresscontroller = TextEditingController();
  final TextEditingController _postalcontroller = TextEditingController();

  int _frameId = -1;
  List<Map> _detectedFields = [];

  @override
  void initState() {
    super.initState();
    SettingProvider.getInstance().addListener(_loadCSVData);
    _loadCSVData();
  }

  @override
  void dispose() {
    SettingProvider.getInstance().removeListener(_loadCSVData);
    super.dispose();
  }

  Future<void> _loadCSVData() async {
    String namesFilePath;
    String surnamesFilePath;
    String country;

    if (SettingProvider.getInstance().region == 'us') {
      namesFilePath = 'assets/EngNames.csv';
      surnamesFilePath = 'assets/EngSur.csv';
      country = 'United States';
    } else {
      namesFilePath = 'assets/LTNames.csv';
      surnamesFilePath = 'assets/LTSur.csv';
      country = 'Lithuania';
    }

    var result = await readCSV(namesFilePath);
    var result2 = await readCSV(surnamesFilePath);
    var result3 = await readCities('assets/CityList.csv', country);

    setState(() {
      names = result.$1;
      nameFreq = result.$2;
      surNames = result2.$1;
      surNamesFreq = result2.$2;
      cities = result3;
    });
  }

  void _generateName() async {
    setState(() {
      _isButtonDisabled = true;
    });

    final locationInfo = await Generation.getRandomLocation(cities);

    if (names.isEmpty ||
        nameFreq.isEmpty ||
        surNames.isEmpty ||
        surNamesFreq.isEmpty) {
      return;
    }

    String fullName = Generation.generateName(
      names,
      nameFreq,
      surNames,
      surNamesFreq,
    );

    List<String> nameParts = fullName.split(" ");
    String name = nameParts[0];
    String surname = nameParts[1];
    surname = surname[0].toUpperCase() + surname.substring(1).toLowerCase();

    while (true) {
      if (name[name.length - 1].codeUnitAt(0) == 's'.codeUnitAt(0) &&
          surname[surname.length - 1].codeUnitAt(0) == 's'.codeUnitAt(0)) {
        break;
      } else if (name[name.length - 1].codeUnitAt(0) != 's'.codeUnitAt(0) &&
          surname[surname.length - 1].codeUnitAt(0) != 's'.codeUnitAt(0)) {
        break;
      }
      fullName = Generation.generateName(
        names,
        nameFreq,
        surNames,
        surNamesFreq,
      );
      nameParts = fullName.split(" ");
      name = nameParts[0];
      surname = nameParts[1];
      surname = surname[0].toUpperCase() + surname.substring(1).toLowerCase();
    }

    setState(() {
      _nameController.text = name;
      _surnameController.text = surname;
      _usernameController.text = Generation.generateUsername(name, surname);
      _datecontroller.text =
          Generation.getRandomDateTime().toIso8601String().split('T')[0];
      _countrycontroller.text = Generation.getCountry(
        SettingProvider.getInstance().region,
        false,
      );
      _citycontroller.text = locationInfo['city'];
      _addresscontroller.text = locationInfo['street'];
      _postalcontroller.text = locationInfo['postcode'];
    });

    Timer(Duration(seconds: 2), () {
      setState(() {
        _isButtonDisabled = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.ext_title)),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ExpansionTile(
                title: Text(
                  AppLocalizations.of(context)!.expansion_tile,
                ), // Add appropriate localization
                initiallyExpanded:
                    true, // Set to false if you want it collapsed initially
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)!.generator_name_name,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _surnameController,
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)!.generator_surname_name,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)!.generator_username,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _citycontroller,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.generator_city,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _countrycontroller,
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)!.generator_country,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _addresscontroller,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.generator_street,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _postalcontroller,
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)!.generator_postal_code,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _datecontroller,
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)!.generator_date_of_birth,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),

              ElevatedButton(
                onPressed: _isButtonDisabled ? null : _generateName,
                child: Text(
                  _isButtonDisabled
                      ? AppLocalizations.of(context)!.button_wait
                      : AppLocalizations.of(context)!.button_generate,
                ),
              ),
              SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  if (_nameController.text == '' &&
                      _surnameController.text == '') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.missing_name_surname,
                        ),
                      ),
                    );
                    return;
                  }
                  Saver.saveInfo(_nameController.text, _surnameController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.entry_saved),
                    ),
                  );
                },
                child: Text(AppLocalizations.of(context)!.button_save_entry),
              ),
              SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  Saver.readInfo();
                },
                child: Text("Read"),
              ),
              SizedBox(height: 16),

              ElevatedButton(
                onPressed: () async {
                  var result = await queryFields();
                  if (result["status"] != "FOUND") {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.detect_fail,
                        ),
                      ),
                    );
                    return;
                  }

                  _frameId = result["frameId"];
                  _detectedFields = result["data"];

                  print("Received fields:");
                  print(_detectedFields);
                },
                child: Text("Detect fields from current website"),
              ),
              SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  if (_detectedFields.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.detect_fail,
                        ),
                      ),
                    );
                    return;
                  }

                  List<Map<String, dynamic>> fieldsToFill = [];
                  for (var i = 0; i < _detectedFields.length; i++) {
                    fieldsToFill.add({
                      "ref": _detectedFields[i]["ref"],
                      "value":
                          _detectedFields[i]["generator"], // TODO: perform actual generation
                    });
                  }
                  fillFields(_frameId, fieldsToFill);
                },
                child: Text("Fill detected fields"),
              ),
              SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsPage()),
                  );
                },
                child: Text(AppLocalizations.of(context)!.settings_title),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
