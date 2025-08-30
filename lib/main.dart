import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_compare/image_compare.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final textfieldTitleController = TextEditingController();
  final textfieldAController = TextEditingController();
  final textfieldBController = TextEditingController();
  final textfieldOutputPathController = TextEditingController();
  bool isLoading = false;

  List<MapEntry<File, File>> comparisonResults = [];
  int currentIndex = 0;

  Future<void> onCompareButtonClick() async {
    //Get images on both folders
    final imagesA = getImageFilesRecursively(textfieldAController.text);
    final imagesB = getImageFilesRecursively(textfieldBController.text);

    Map<File, File> imagesMatch = {};

    for (var image in imagesA) {
      try {
        final result = await listCompare(target: image, list: imagesB);
        final bestMatchIndex = getBestMatchIndex(result);
        imagesMatch[image] = imagesB[bestMatchIndex];
      } catch (e) {
        print(image.path);
      }
    }

    await writeImageMatchesToFile(imagesMatch);

    setState(() {
      comparisonResults = imagesMatch.entries.toList();
      currentIndex = 0;
    });
  }

  List<File> getImageFilesRecursively(String rootDir) {
    final dir = Directory(rootDir);
    if (!dir.existsSync()) {
      print('Directory does not exist: $rootDir');
      return [];
    }

    return dir.listSync(recursive: true).whereType<File>().where((file) {
      final lower = file.path.toLowerCase();
      return lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg') ||
          lower.endsWith('.png') ||
          lower.endsWith('.bmp') ||
          lower.endsWith('.webp');
    }).toList();
  }

  int getBestMatchIndex(List<double> result) {
    double minValue = result.first;
    int minIndex = 0;

    for (int i = 1; i < result.length; i++) {
      if (result[i] < minValue) {
        minValue = result[i];
        minIndex = i;
      }
    }

    return minIndex;
  }

  Future<void> writeImageMatchesToFile(Map<File, File> imagesMatch) async {
    final file = File(textfieldOutputPathController.text);
    final sink = file.openWrite(mode: FileMode.append); // Append mode
    sink.writeln('');
    sink.writeln("#${textfieldTitleController.text}");
    for (final entry in imagesMatch.entries) {
      final String nameA = p.basename(entry.key.path);
      final String nameB = p.basename(entry.value.path);
      sink.writeln('$nameA:$nameB');
    }

    await sink.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
            scrollbars: false,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  decoration: InputDecoration(hintText: 'Comparison title'),
                  controller: textfieldTitleController,
                ),
                Container(height: 10),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Images A directory/folder path (recursive)',
                  ),
                  controller: textfieldAController,
                ),
                Container(height: 10),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Images B directory/folder path (recursive)',
                  ),
                  controller: textfieldBController,
                ),
                Container(height: 10),
                TextField(
                  decoration: InputDecoration(hintText: 'Output txt path'),
                  controller: textfieldOutputPathController,
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (isLoading) {
                      return;
                    }
                    setState(() {
                      isLoading = true;
                    });
                    await onCompareButtonClick();
                    setState(() {
                      isLoading = false;
                    });
                  },
                  child: Text("Compare"),
                ),
                Text('Freezing = Loading'),
                Container(height: 20),
                if (comparisonResults.isNotEmpty)
                  Column(
                    children: [
                      SizedBox(height: 20),
                      Text(
                        'Match ${currentIndex + 1} of ${comparisonResults.length}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Image.file(
                                  comparisonResults[currentIndex].key,
                                  height: 300,
                                ),
                                Text(
                                  p.basename(
                                    comparisonResults[currentIndex].key.path,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              children: [
                                Image.file(
                                  comparisonResults[currentIndex].value,
                                  height: 300,
                                ),
                                Text(
                                  p.basename(
                                    comparisonResults[currentIndex].value.path,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            currentIndex =
                                (currentIndex + 1) % comparisonResults.length;
                          });
                        },
                        child: Text('Next'),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            currentIndex =
                                (currentIndex - 1) % comparisonResults.length;
                          });
                        },
                        child: Text('Prev'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
