import 'package:gsheets/gsheets.dart';

import '../connection/sheets_connector.dart';
import '../page_objects/meta_sheet.dart';

/// Data Access Layer
/// Data specific identifiers, constants and API should be defined inside presentational files/components
class DAL {
  final _sheetsConnection = SheetsConnector();
  MetaSheet? _metaWorksheet;

  writePin(String pin) async {
    try {
      if (_metaWorksheet == null) {
        await connect();
      }

      if (_metaWorksheet == null) {
        throw Exception('Connection not established');
      } else {
        await _metaWorksheet!.writePin(pin);
      }

      await disconnect();
    } catch (e) {
      print(e);
    }
  }

  Future<Spreadsheet> connect() async {
    final coordinatorSheet =
        await _sheetsConnection.getStocksCoordinatorSheet();
    _metaWorksheet = MetaSheet(coordinatorSheet);

    return coordinatorSheet;
  }

  Future<bool> disconnect() async {
    await _sheetsConnection.close();
    _metaWorksheet = null;

    return Future.value(true);
  }
}
