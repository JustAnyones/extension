import 'package:flutter/services.dart' show rootBundle;

Future<(List<String>, List<double>)> readCSV(String filePath) async {
  List<String> data = [];
  List<double> freq = [];

  try {
    final csvString = await rootBundle.loadString(filePath);
    var lines = csvString.split("\n");
    for (var i = 0; i < lines.length; i++) {
      if (lines[i] == "") break;
      var fields = lines[i].split(",");
      data.add(fields[0].toString());
      freq.add(double.parse(fields[1].toString()));
    }
    return (data, freq);
  } catch (e) {
    print('Error reading file: $e');
    return (data, freq);
  }
}

Future<List<String>> readCities(String filePath, String countryCode) async {
  List<String> data = [];

  try {
    final csvString = await rootBundle.loadString(filePath);
    var lines = csvString.split("\n");
    for (var i = 0; i < lines.length; i++) {
      if (lines[i] == "") break;
      var fields = lines[i].split(",");
      if (fields[1].trim() == countryCode) {
        data.add(fields[0].toString().trim());
      }
    }
    return data;
  } catch (e) {
    print('Error reading file: $e');
    return data;
  }
}
