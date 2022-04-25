import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:stocks_hannover_flutter/constants.dart';
import 'package:gsheets/gsheets.dart';

class SheetsConnector {
  GSheets? gsheets;

  Future<Spreadsheet> getStocksCoordinatorSheet() async {
    final connection = await connectSheetsApi();
    final sheetIds = jsonDecode(await _loadSheetIds());

    return connection.spreadsheet(sheetIds[STOCKS_COORDINATE_SHEET_ID_KEY],
        input: ValueInputOption.raw);
  }

  Future<GSheets> connectSheetsApi() async {
    final secretsJson = await _loadGcpSecrets();
    gsheets = GSheets(secretsJson);
    return Future.value(gsheets);
  }

  Future<void> close() async {
    if (gsheets != null) {
      await gsheets!.close();
      gsheets = null;
    }
  }

  Future<String> _loadGcpSecrets() {
    return rootBundle.loadString('assets/secrets/stocks-hannover-gcp.json');
  }

  Future<String> _loadSheetIds() {
    return rootBundle.loadString('assets/secrets/sheet-ids.json');
  }
}
