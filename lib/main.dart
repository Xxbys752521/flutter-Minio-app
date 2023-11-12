import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'fileList/fileList.dart';
import 'upload.dart';
import 'state/uploaded_files_model.dart';
import 'state/download_files_model.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UploadedFilesModel()),
        ChangeNotifierProvider(create: (context) => DownloadFilesModel()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = FileListPage();
        break;
      case 1:
        page = UploadPage();
        break;
      default:
        throw UnimplementedError('Invalid index: $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                extended: constraints.maxWidth > 600,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.file_copy),
                    label: Text('Files'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.file_upload),
                    label: Text('Upload'),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.inversePrimary,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}
