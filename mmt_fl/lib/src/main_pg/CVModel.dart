import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:mmt_fl/src/main_pg/Left_Menu.dart';
import 'package:mmt_fl/src/main_pg/MEGAMEN.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:open_file_manager/open_file_manager.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:flutter/services.dart';

// ---------------------------------------------------------------------------------------------- //
//  Для новых таблиц
class NewData {
  NewData(this.id, this.name, this.designation, this.salary);

  final String id;

  final String name;

  final String designation;

  final String salary;
}

class NewDataSource extends DataGridSource {
  /// Creates the NewData data source class with required details.
  NewDataSource({required List<NewData> NewData_Data}) {
    _NewData_Data = NewData_Data
        .map<DataGridRow>((e) => DataGridRow(cells: [
              DataGridCell<String>(columnName: 'file_name', value: e.id),
              DataGridCell<String>(columnName: 'count_short_name', value: e.name),
              DataGridCell<String>(
                  columnName: 'count_long_name', value: e.designation),
              DataGridCell<String>(columnName: 'count_dangerous_people', value: e.salary),
            ]))
        .toList();
  }
  List<DataGridRow> _NewData_Data = [];
  @override
  List<DataGridRow> get rows => _NewData_Data;
  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
        cells: row.getCells().map<Widget>((e) {
      TextStyle? getTextStyle() {
        if (e.columnName == 'id') {
          return const TextStyle(color: Colors.pinkAccent);
        } else {
          return const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.normal,
                  fontSize: 15,
                  color: Color(0xFFF3F2F3),
                );
        }
      }
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8.0),
        child: Text(
          e.value.toString(), 
          style: getTextStyle(),
          ),
      );
    }).toList());
  }
}
// ---------------------------------------------------------------------------------------------- //
// Данные для новых таблиц
  List<NewData> NewDatas = <NewData>[];
  late NewDataSource NewDataDataSource;
  List<NewData> getNewDataData() {
      return [
        NewData('10001', 'James', 'Project Leeeeead', '20000'),
        NewData('10002', 'Kathryn', 'Manager', '30000'),
      ];
    }

// ---------------------------------------------------------------------------------------------- //
// Класс страницы
class CVModel extends StatefulWidget {
  const CVModel({super.key});
  
  @override
  State<CVModel> createState() => _CVModelState();
}
// ---------------------------------------------------------------------------------------------- //
// сборщик
class  _CVModelState extends State<CVModel>{
  final _pageController = PageController();

  late var newDataList = [];
  List<String> frstImgs = [
    "./assets/images/sml.png",
  ];
  List<String> bboxImgs = [
    // "./assets/images/sml.png",
    "./assets/images/sml.png",
  ];
  List<String> cropImgs = [
    // "./assets/images/sml.png",
    "./assets/images/sml.png",
  ];

  bool flag = false;

  List<Widget> nameSlots = [];

  bool _isLoading = false;

  // ---------------------------------------------------------------------------------------------- //
  // unzip ответа от сервера 
  Future<void> unzipFileFromResponse(List<int> responseBody) async {
    final archive = ZipDecoder().decodeBytes(responseBody);
    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        // print("test file");
        print(filename);
        final data = file.content as List<int>;
        if (filename.contains('.jpg') || filename.contains('.jpeg') || filename.contains('.png')) {
          if (Platform.isWindows) {
            File('./responce/$filename')
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
            if (filename.contains('cropped_image')) {
              cropImgs.add('./responce/$filename');
            }
            else if (filename.contains('boxed_image')) {
              bboxImgs.add('./responce/$filename');
            }
            else {
              frstImgs.add('./responce/$filename');
            }
          }
          if (Platform.isAndroid) {
            Directory? tempDir = await getDownloadsDirectory(); 
            // print(tempDir);
            String tempPath = tempDir!.path; 
            var filePath = tempPath + filename;
            File(filePath)
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
            if (filename.contains('cropped_image')) {
              cropImgs.add(filePath);
            }
            else if (filename.contains('boxed_image')) {
              bboxImgs.add(filePath);
            }
            else {
              frstImgs.add(filePath);
            }
          }
        }
        else {
          if (Platform.isWindows) {
            File('responce/$filename')
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
          }
        }
      } else {
        print("test dir");
        await Directory('responce/$filename').create(recursive: true);
      }
    }
  }
  
// ---------------------------------------------------------------------------------------------- //
  //загрузка изображений 
  Future<void> uploadImage() async {
    setState(() {
      _isLoading = true;
    });
    final picker = ImagePicker();
    List<XFile>? imageFileList = [];
    List<String>? pathFiles = [];
    final List<XFile> selectedImages = await picker.pickMultiImage();
    // final List<XFile> selectedImages = await picker.pickMultiImage();
    if (selectedImages.isNotEmpty) {
        imageFileList.addAll(selectedImages);
    }
    for (var i = 0; i < imageFileList.length; i++) {
      pathFiles.add(imageFileList[i].path.split("\\").last);
    }
    List<String>? base64list = [];
    for (var i = 0; i < imageFileList.length; i++) {
      final imageBytes1 = await imageFileList[i].readAsBytes();
      final base64Image1 = base64.encode(imageBytes1);
      base64list.add(base64Image1);
    }
    final json = {'files_names': pathFiles,
                'files': base64list};

    final response = await http.post(
        // Uri.parse('http://95.163.250.213/get_result_64'),
        Uri.parse('http://127.0.0.1:8000/get_result_64'),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        body: jsonEncode(json),
    );
    if (response.statusCode == 200) {
      unzipFileFromResponse(response.bodyBytes);
      String path = '';
      if (Platform.isWindows) {
        path = "./responce/data.txt";
      }
      if (Platform.isAndroid) { 
        path = "/storage/emulated/0/Android/data/com.example.mmt_fl/files/downloads/data.txt";
      }
      File dataFile = File(path);
      String dataString = dataFile.readAsStringSync();
      final responceMap = jsonDecode(dataString);
      print(responceMap);
      List<dynamic> dataMap = jsonDecode(jsonEncode(responceMap["data"]));
      // print(dataMap);
      List<List> dataList = dataMap.map((element) => [element['name'], element['count_short'], element['count_long'], element['count_dangerous_people']]).toList();
      // print(dataList);
      
      setState(() {
        flag = true;
        _isLoading = false;
        newDataList = dataMap; 
        NewDatas = [];
        for (var i = 0; i < dataList.length; i++) {
          // print(jsonEncode(dataList[i]).toString());
          // print(dataList[i][1]);
          NewDatas.add(NewData(dataList[i][0].toString(), dataList[i][1].toString(), dataList[i][2].toString(), dataList[i][3].toString()));
        }
        NewDataDataSource = NewDataSource(NewData_Data: NewDatas);
        if (Platform.isWindows) {
          if (frstImgs.contains("./assets/images/sml.png")) {
            frstImgs.remove("./assets/images/sml.png");
          }
          if (bboxImgs.contains("./assets/images/sml.png")) {
            bboxImgs.remove("./assets/images/sml.png");
          }
          if (cropImgs.contains("./assets/images/sml.png")) {
            cropImgs.remove("./assets/images/sml.png");
          }
        }
      });
    } else {
      print('Failed to upload image.');
    }
  }
// ---------------------------------------------------------------------------------------------- //
  // функция очистки папки
  Future<void> deleteFilesInFolder(String folderPath) async {
    final directory = Directory(folderPath);
    if (await directory.exists()) {
      await for (final entity in directory.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }
    }
  }
// ---------------------------------------------------------------------------------------------- //
  @override
  void initState() {
    super.initState();
    NewDatas;
    // NewDatas = getNewDataData();
    NewDataDataSource = NewDataSource(NewData_Data: NewDatas);
  }
// ---------------------------------------------------------------------------------------------- //
// loading files from assets on Android
Future<File> getImageFileFromAssets(String path) async { 
  final byteData = await rootBundle.load('assets$path'); 
  final buffer = byteData.buffer; 
  Directory? tempDir = await getDownloadsDirectory(); 
  // print(tempDir);
  String tempPath = tempDir!.path; 
  var filePath = tempPath + path; // path - path to asset file
  // print(filePath);
  return File(filePath) .writeAsBytes(buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
}
// ---------------------------------------------------------------------------------------------- //
// clearing files on Windows and Android
Future<void> clearFolders() async {
  if (Platform.isAndroid) {
      final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
      Directory flutter_assets_dir = Directory('${appDocumentsDir.path}/flutter_assets');
      final String downloadsDir = (await getDownloadsDirectory())!.path;
      List<FileSystemEntity> files = flutter_assets_dir.listSync();
      print(files);
      getImageFileFromAssets('/sml.png');
      deleteFilesInFolder(downloadsDir);
  } 
  else if (Platform.isWindows) {
    frstImgs = [
      "./assets/images/sml.png",
    ];
    bboxImgs = [
      "./assets/images/sml.png",
    ];
    cropImgs = [
      "./assets/images/sml.png",
    ];
    NewDatas = [];
    NewDataDataSource = NewDataSource(NewData_Data: NewDatas);
    deleteFilesInFolder("./responce");
  }
}
// ---------------------------------------------------------------------------------------------- //
// ---------------------------------------------------------------------------------------------- //
// ---------------------------------------------------------------------------------------------- //
// визуальная обертка
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF181818),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.menu,
            color: Color(0xFF3882F2),
            size: 24,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Left_Menu()),
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
            child:  IconButton(
              icon: const Icon(
                Icons.autorenew_outlined,
                color: Color(0xFF3882F2),
                size: 24,
              ),
              onPressed: () {
                setState(() {
                  flag = true;
                  newDataList = [];
                  clearFolders();
                });
              },
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 300, maxWidth: 1280),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(0),
                    width: MediaQuery.of(context).size.width,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Color(0x00000000),
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: MaterialButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MEGAMEN()),
                          );
                        },
                        color: const Color(0xFF3882F2),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                        textColor: const Color(0xFF181818),
                        height: 60,
                        minWidth: 180,
                        child: const Text(
                          "MEGAMEN TEAM",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                              child: 
                              ElevatedButton.icon(
                                icon: _isLoading
                                    ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Color(0xFF181818), )))
                                    : const Icon(Icons.add, color: Color(0xFF181818), size: 22,),
                                label: Text(
                                  _isLoading ? 'Загрузка...' : 'Ваше фото',
                                  style: const TextStyle(fontSize: 20, color: Color(0xFF181818)),
                                ),
                                onPressed: () => _isLoading ? null : uploadImage(),
                                 style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(12),
                                  backgroundColor: const Color(0xFF3882F2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
// ---------------------------------------------------------------------------------------------- //
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(0, 30, 0, 10),
                            child: Text('Таблица предсказаний',
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.clip,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.normal,
                                fontSize: 18,
                                color: Color(0xFFF3F2F3),
                                ) 
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Flexible(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: 220, maxWidth: 700),
                                  child: SfDataGridTheme(
                                    data: SfDataGridThemeData(
                                      headerColor: const Color(0xFF0E223F),
                                      headerHoverColor: const Color(0xFF3882F2),
                                      gridLineColor: const Color(0xFF3882F2), 
                                      gridLineStrokeWidth: 2.0,
                                      rowHoverColor: const Color(0xFF0E223F), 
                                      ),
                                    child: SfDataGrid(
                                        
                                        source: NewDataDataSource,
                                        allowSorting: true,
                                        allowMultiColumnSorting: true,
                                        allowTriStateSorting: true,
                                        // showSortNumbers: true,
                                        showColumnHeaderIconOnHover: true,
                                        columnWidthMode: ColumnWidthMode.lastColumnFill,
                                        // columnWidthMode: ColumnWidthMode.auto,
                                        // columnWidthCalculationRange: ColumnWidthCalculationRange.allRows,
                                        onQueryRowHeight: (details) {
                                          return details.getIntrinsicRowHeight(details.rowIndex);
                                        },
                                        columns: <GridColumn>[
                                          GridColumn(
                                              columnName: 'file_name',
                                              // autoFitPadding: EdgeInsets.all(16.0),
                                              label: Container(
                                                  padding: const EdgeInsets.all(8.0),
                                                  alignment: Alignment.center,
                                                  child: const Text(
                                                    'Файл', 
                                                    // overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                          fontStyle: FontStyle.normal,
                                                          fontSize: 16,
                                                          color: Color(0xFFF3F2F3),
                                                        ),
                                                  )
                                              )
                                          ),
                                          GridColumn(
                                              columnName: 'count_short_name',
                                              // columnWidthMode: ColumnWidthMode.lastColumnFill,
                                              // autoFitPadding: EdgeInsets.all(16.0),
                                              label: Container(
                                                  padding: const EdgeInsets.all(8.0),
                                                  alignment: Alignment.center,
                                                  child: const Text(
                                                    'Короткое оружие',
                                                    // overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                          fontStyle: FontStyle.normal,
                                                          fontSize: 17,
                                                          color: Color(0xFFF3F2F3),
                                                        ),
                                                  )
                                              )
                                          ),
                                          GridColumn(
                                              columnName: 'count_long_name',
                                              // autoFitPadding: EdgeInsets.all(16.0),
                                              label: Container(
                                                  padding: const EdgeInsets.all(8.0),
                                                  alignment: Alignment.center,
                                                  child: const Text(
                                                    'Длинное оружия',
                                                    // overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                          fontStyle: FontStyle.normal,
                                                          fontSize: 17,
                                                          color: Color(0xFFF3F2F3),
                                                        ),
                                                  )
                                              )
                                          ),
                                          GridColumn(
                                              columnName: 'count_dangerous_people',
                                              // autoFitPadding: EdgeInsets.all(16.0),
                                              label: Container(
                                                  padding: const EdgeInsets.all(8.0),
                                                  alignment: Alignment.center,
                                                  child: const Text(
                                                    'Опасные люди',
                                                    // overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                          fontStyle: FontStyle.normal,
                                                          fontSize: 17,
                                                          color: Color(0xFFF3F2F3),
                                                        ),
                                                  )
                                              )
                                          ),
                                        ],
                                        gridLinesVisibility: GridLinesVisibility.both,
                                        headerGridLinesVisibility: GridLinesVisibility.both,
                                        selectionMode: SelectionMode.multiple,
                                      ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
// ---------------------------------------------------------------------------------------------- //
                  const Padding(
                    padding: EdgeInsets.fromLTRB(8, 20, 30, 10),
                    child: Text(
                      "Недавние изображения, распознанные моделью",
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.normal,
                        fontSize: 18,
                        color: Color(0xFFF3F2F3),
                      ),
                    ),
                  ),
// ---------------------------------------------------------------------------------------------- //
                  Container(
                    // margin: const EdgeInsets.all(15.0),
                    // padding: const EdgeInsets.all(3.0),
                    width: MediaQuery.of(context).size.width,
                    height: 350,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF3882F2), width: 2,),
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
                    child:  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: CustomScrollView(
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            slivers: <Widget>[
                              SliverPadding(
                              padding: const EdgeInsets.fromLTRB(20, 20, 0, 20),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate(
                                  <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(0, 20, 70, 20),
                                      child: SizedBox(
                                        height: 330,
                                        width: 300,
                                        child: Stack(
                                          children: [                           
                                            PageView.builder(
                                              controller: _pageController ,
                                              scrollDirection: Axis.horizontal,
                                              itemCount: bboxImgs.length,
                                              itemBuilder: (context, index) {
                                                return Align(
                                                  alignment: Alignment.topCenter,
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(
                                                        vertical: 16, horizontal: 0),
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(5.0),
                                                      child:
                                                          Column(
                                                            children: [
                                                              Image.file(File(bboxImgs[index]),
                                                                        height: 200,
                                                                        width: MediaQuery.of(context).size.width,
                                                                        fit: BoxFit.contain,
                                                              ),
                                                              Text(basename(bboxImgs[index].toString()), 
                                                              style: const TextStyle(
                                                                fontWeight: FontWeight.w400,
                                                                fontStyle: FontStyle.normal,
                                                                fontSize: 18,
                                                                color: Color(0xFFF3F2F3),
                                                              ),
                                                              )
                                                            ],
                                                          ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            Align(
                                              alignment: Alignment.bottomCenter,
                                              child: Padding(
                                                padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
                                                child: SmoothPageIndicator(
                                                  controller: _pageController ,
                                                  count: bboxImgs.length,
                                                  axisDirection: Axis.horizontal,
                                                  effect: const ExpandingDotsEffect(
                                                    dotColor: Color(0xFF2b548f),
                                                    activeDotColor: Color(0xFF2b548f),
                                                    dotHeight: 10,
                                                    dotWidth: 10,
                                                    radius: 16,
                                                    spacing: 7,
                                                    expansionFactor: 2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const Align(
                                              alignment: Alignment.topCenter,
                                              child: Padding(
                                                padding: EdgeInsets.fromLTRB(40, 0, 0, 0),
                                                child: Row(
                                                  children: [
                                                  Text(
                                                  "Yolo BBOX",
                                                  textAlign: TextAlign.center,
                                                  overflow: TextOverflow.clip,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle: FontStyle.normal,
                                                    fontSize: 14,
                                                    color: Color(0xFFF3F2F3),
                                                  ),
                                                ), ],
                                                ),
                                              ),
                                            ),  
                                          ],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(70, 20, 20, 20),
                                      child: SizedBox(
                                        height: 330,
                                        width: 300,
                                        child: Stack(
                                          children: [
                                            PageView.builder(
                                              controller: _pageController,
                                              scrollDirection: Axis.horizontal,
                                              itemCount: cropImgs.length,
                                              itemBuilder: (context, index) {
                                                return Align(
                                                  alignment: Alignment.topCenter,
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(
                                                        vertical: 16, horizontal: 0),
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(5.0),
                                                      child:
                                                          Column(
                                                            children: [
                                                              Image.file(File(cropImgs[index]),
                                                                        height: 200,
                                                                        width: MediaQuery.of(context).size.width,
                                                                        fit: BoxFit.contain,
                                                              ),
                                                              Text(basename(cropImgs[index].toString()), 
                                                              style: const TextStyle(
                                                                fontWeight: FontWeight.w400,
                                                                fontStyle: FontStyle.normal,
                                                                fontSize: 18,
                                                                color: Color(0xFFF3F2F3),
                                                              ),
                                                              )
                                                            ],
                                                          ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            Align(
                                              alignment: Alignment.bottomCenter,
                                              child: Padding(
                                                padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
                                                child: SmoothPageIndicator(
                                                  controller: _pageController ,
                                                  count: cropImgs.length,
                                                  axisDirection: Axis.horizontal,
                                                  effect: const ExpandingDotsEffect(
                                                    dotColor: Color(0xFF2b548f),
                                                    activeDotColor: Color(0xFF2b548f),
                                                    dotHeight: 10,
                                                    dotWidth: 10,
                                                    radius: 16,
                                                    spacing: 7,
                                                    expansionFactor: 2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const Align(
                                              alignment: Alignment.topCenter,
                                              child: Padding(
                                                padding: EdgeInsets.fromLTRB(40, 0, 0, 0),
                                                child: Row(
                                                  children: [
                                                  Text(
                                                  "Yolo Crop",
                                                  textAlign: TextAlign.center,
                                                  overflow: TextOverflow.clip,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle: FontStyle.normal,
                                                    fontSize: 14,
                                                    color: Color(0xFFF3F2F3),
                                                  ),
                                                ), ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(0),
                    width: MediaQuery.of(context).size.width,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Color(0x00000000),
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: MaterialButton(
                        onPressed: () {
                          openFileManager();
                        },
                        color: const Color(0xFF3882F2),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                        textColor: const Color(0xFF181818),
                        height: 60,
                        minWidth: 180,
                        child: const Text(
                          "Открыть predict",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
// ---------------------------------------------------------------------------------------------- //
                  const Padding(
                    padding: EdgeInsets.fromLTRB(0, 90, 0, 0),
                    child: Divider(
                      color: Color(0xFF3882F2),
                      height: 16,
                      thickness: 3,
                      indent: 0,
                      endIndent: 0,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(0),
                    padding: const EdgeInsets.all(0),
                    width: MediaQuery.of(context).size.width,
                    height: 300,
                    decoration: BoxDecoration(
                      color: const Color(0xFF181818),
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(color: const Color(0x4d9e9e9e), width: 1),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(10),
                          child:
                              Image(
                            image: AssetImage("assets/images/rgi_logo.png"),
                            height: 190,
                            width: 190,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Text(
                          "ПФО 2023",
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.normal,
                            fontSize: 18,
                            color: Color(0xFF3882F2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  State<StatefulWidget> createState() {
    throw UnimplementedError();
  }
}
