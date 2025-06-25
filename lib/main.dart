import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/omron_input_screen.dart';
import 'screens/history_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/omron_edit_screen.dart'; // IMPORT BARU
import 'models/omron_data.dart'; // IMPORT BARU

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Indonesian locale
  await initializeDateFormatting('id_ID', null);
  
  runApp(OmronApp());
}

class OmronApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Omron HBF-375 Manual Input',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => OmronInputScreen(),
        '/history': (context) => HistoryScreen(),
        '/analytics': (context) => AnalyticsScreen(),
      },
      // TAMBAHKAN onGenerateRoute untuk handle edit screen dengan parameter
      onGenerateRoute: (settings) {
        if (settings.name == '/edit') {
          final OmronData data = settings.arguments as OmronData;
          return MaterialPageRoute(
            builder: (context) => OmronEditScreen(data: data),
            settings: settings,
          );
        }
        return null;
      },
      debugShowCheckedModeBanner: false,
    );
  }
}