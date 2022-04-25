import 'package:gsheets/gsheets.dart';

const sheetTitle = 'Meta';

class MetaSheet {
  final Spreadsheet spreadsheet;
  
  MetaSheet(this.spreadsheet);
  
  Future<bool> writePin(String pin) async {
    final worksheet = _getWorksheet();
    if(worksheet != null) {
      return await worksheet.values.insertValue(pin, column: 1, row: 2);
    } else {
      throw Exception('Reference to worksheet $sheetTitle could not be retrieved.');
    }
  }
  
  Worksheet? _getWorksheet() {
    final worksheet = spreadsheet.worksheetByTitle(sheetTitle);

    return worksheet;
  }
}