import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/basic_form/basic_form_page.dart';
import 'ui/advanced/advanced_page.dart';
import 'ui/schema_form/schema_form_page.dart';
import 'ui/conditional_form/conditional_form_page.dart';
import 'ui/derived_fields/derived_fields_page.dart';
import 'ui/validation_examples/validation_examples_page.dart';
import 'ui/headless_form/headless_form_page.dart';
import 'ui/performance_examples/performance_examples_page.dart';

void main() {
  runApp(const ProviderScope(child: BetterFormExampleApp()));
}

class BetterFormExampleApp extends StatelessWidget {
  const BetterFormExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Better Form Examples',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Better Form Examples'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Basic', icon: Icon(Icons.edit)),
            Tab(text: 'Schema', icon: Icon(Icons.schema)),
            Tab(text: 'Conditional', icon: Icon(Icons.visibility)),
            Tab(text: 'Derived', icon: Icon(Icons.calculate)),
            Tab(text: 'Validation', icon: Icon(Icons.check_circle)),
            Tab(text: 'Headless', icon: Icon(Icons.code)),
            Tab(text: 'Performance', icon: Icon(Icons.speed)),
            Tab(text: 'Advanced', icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          BasicFormExample(),
          SchemaFormExample(),
          ConditionalFormExample(),
          DerivedFieldsExample(),
          ValidationExamples(),
          HeadlessFormExample(),
          PerformanceExamples(),
          AdvancedExample(),
        ],
      ),
    );
  }
}
