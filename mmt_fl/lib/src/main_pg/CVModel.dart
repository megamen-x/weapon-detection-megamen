import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:mmt_fl/src/main_pg/CVModel_video.dart';
import 'package:mmt_fl/src/main_pg/Left_Menu.dart';
import 'package:mmt_fl/src/main_pg/MEGAMEN.dart';
import 'package:mmt_fl/src/syst_pg/DataNotFound.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
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
              DataGridCell<String>(columnName: 'count_short_n', value: e.name),
              DataGridCell<String>(
                  columnName: 'count_long_n', value: e.designation),
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
        if (e.columnName == 'file_name') {
          return const TextStyle(
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.normal,
            fontSize: 14, 
            color: Colors.pinkAccent);
        } else {
          return const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.normal,
                  fontSize: 14,
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
  late var popup = '';
  // for debug
  List<String> frstImgs = [
    "./assets/images/sml.png",
  ];
  List<String> bboxImgs = [

  ];
  List<String> cropImgs = [
    "./assets/images/sml.png",
  ];

  bool flag = false;
  List<Widget> nameSlots = [];
  bool _isLoading = false;

  // ---------------------------------------------------------------------------------------------- //
  // unzip ответа от сервера 
  Future<void> unzipFileFromResponse(List<int> responseBody) async {
    final archive = ZipDecoder().decodeBytes(responseBody);
    bboxImgs = [];
    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        // print(filename);
        final data = file.content as List<int>;
        if (filename.contains('.jpg') || filename.contains('.jpeg') || filename.contains('.png')) {
          // if (Platform.isWindows) {
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
          // }
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
          // if (Platform.isWindows) {
            File('responce/$filename')
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
          // }
        }
      } else {
        await Directory('responce/$filename').create(recursive: true);
      }
    }
  }
  
// ---------------------------------------------------------------------------------------------- //
  //загрузка изображений 
  Future<void> uploadImage() async {
    setState(() {
      _isLoading = true;
      popup = '';
    });
    final picker = ImagePicker();
    List<XFile>? imageFileList = [];
    List<String>? pathFiles = [];
    final List<XFile> selectedImages = await picker.pickMultiImage();
    if (selectedImages.isNotEmpty) {
        imageFileList.addAll(selectedImages);
    }
    for (var i = 0; i < imageFileList.length; i++) {
      if (Platform.isWindows) {
        pathFiles.add(imageFileList[i].path.split("\\").last);
      }
      if (Platform.isLinux) {
        pathFiles.add(imageFileList[i].path.split("/").last);
      }
    }
    List<String>? base64list = [];
    for (var i = 0; i < imageFileList.length; i++) {
      final imageBytes1 = await imageFileList[i].readAsBytes();
      final base64Image1 = base64.encode(imageBytes1);
      base64list.add(base64Image1);
    }
    final json = {'files_names': pathFiles,'files': base64list};
    final response = await http.post(
        Uri.parse('http://127.0.0.1:80/get_result_64'),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        body: jsonEncode(json),
    );
    if (response.statusCode == 200) {
      unzipFileFromResponse(response.bodyBytes);
      String path = '';
      if (Platform.isWindows) {
        path = "./responce/data.txt";
      }
      if (Platform.isLinux) {
        path = "./responce/data.txt";
      }
      if (Platform.isAndroid) { 
        path = "/storage/emulated/0/Android/data/com.example.mmt_fl/files/downloads/data.txt";
      }
      File dataFile = File(path);
      String dataString = dataFile.readAsStringSync();
      final responceMap = jsonDecode(dataString);
      List<dynamic> dataMap = jsonDecode(jsonEncode(responceMap["data"]));
      List<List> dataList = dataMap.map((element) => [element['name'], element['count_short'], element['count_long'], element['count_dangerous_people']]).toList();
      
      setState(() {
        flag = true;
        _isLoading = false;
        newDataList = dataMap; 
        NewDatas = [];
        popup = 'файл-короткое-длинное-вооруженные\n';
        for (var i = 0; i < dataList.length; i++) {
          NewDatas.add(NewData(dataList[i][0].toString(), dataList[i][1].toString(), dataList[i][2].toString(), dataList[i][3].toString()));
          popup += '${dataList[i][0]}             ${dataList[i][1]}              ${dataList[i][2]}                 ${dataList[i][3]}';
          popup += '\n';
        }
        popup += '\n';
        popup += jsonEncode(responceMap["data"]);
        NewDataDataSource = NewDataSource(NewData_Data: NewDatas);
        if (Platform.isWindows) {
          if (frstImgs.contains("./assets/images/sml.png")) {
            frstImgs.remove("./assets/images/sml.png");
          }
          if (bboxImgs.contains("./mmt_fl/assets/images/sml.png")) {
            bboxImgs.remove("./mmt_fl/assets/images/sml.png");
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
      setState(() {
        _isLoading = false;
      });
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
    NewDataDataSource = NewDataSource(NewData_Data: NewDatas);
  }
// ---------------------------------------------------------------------------------------------- //
// loading files from assets on Android
Future<File> getImageFileFromAssets(String path) async { 
  final byteData = await rootBundle.load('assets$path'); 
  final buffer = byteData.buffer; 
  Directory? tempDir = await getDownloadsDirectory(); 
  String tempPath = tempDir!.path; 
  var filePath = tempPath + path;
  return File(filePath) .writeAsBytes(buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
}
// ---------------------------------------------------------------------------------------------- //
// clearing files on Windows and Android
Future<void> clearFolders() async {
  popup = '';
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
// popup виджет
  void _showAlertPredict(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12.0))),
          title: const Text("Ошибка!", 
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.normal,
                  fontSize: 16,
                  color: Color(0xFFF3F2F3),
                )
              ),
          backgroundColor: const Color(0xFF242424),
          content: const Text("Файл предсказания модели не существует!", 
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.normal,
                              fontSize: 16,
                              color: Color(0xFFF3F2F3),
                            )
                          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK", 
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.normal,
                            fontSize: 16,
                            color: Color(0xFFF3F2F3),
                        )
                      ),
            ),
          ],
        );
      },
    );
  }
  void _showPredict(BuildContext context, String fileContext) {
    if (fileContext != '') {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12.0))),
            title: const Text("Содержание предикта модели", 
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.normal,
                    fontSize: 16,
                    color: Color(0xFFF3F2F3),
                  )
                ),
            backgroundColor: const Color(0xFF242424),
            content: Text(fileContext, 
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal,
                                fontSize: 16,
                                color: Color(0xFFF3F2F3),
                              )
                            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("OK", 
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.normal,
                              fontSize: 16,
                              color: Color(0xFFF3F2F3),
                          )
                        ),
              ),
            ],
          );
        },
      );
    }
    else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12.0))),
            title: const Text("Ошибка!", 
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.normal,
                    fontSize: 16,
                    color: Color(0xFFF3F2F3),
                  )
                ),
            backgroundColor: const Color(0xFF242424),
            content: const Text("Файл предсказания пуст!", 
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal,
                                fontSize: 16,
                                color: Color(0xFFF3F2F3),
                              )
                            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("OK", 
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.normal,
                              fontSize: 16,
                              color: Color(0xFFF3F2F3),
                          )
                        ),
              ),
            ],
          );
        },
      );
    }
    
  }
// ---------------------------------------------------------------------------------------------- //
// final DataGridController _dataGridController = DataGridController();
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
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [
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
                                padding: const EdgeInsets.all(14),
                                backgroundColor: const Color(0xFF3882F2),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                              child: MaterialButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const CVVID()),
                                  );
                                },
                                color: const Color(0xFF3882F2),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                                padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                textColor: const Color(0xFF181818),
                                height: 45,
                                minWidth: 180,
                                child: const Text(
                                  "Загрузить видео",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FontStyle.normal,
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
                                  constraints: const BoxConstraints(minWidth: 220, maxWidth: 700, maxHeight: 200),
                                  child: SfDataGridTheme(
                                    data: SfDataGridThemeData(
                                      headerColor: const Color(0xFF0E223F),
                                      headerHoverColor: const Color(0xFF3882F2),
                                      gridLineColor: const Color(0xFF3882F2), 
                                      // gridLineStrokeWidth: 2.0,
                                      rowHoverColor: const Color(0xFF0E223F),
                                      ),
                                    child: SfDataGrid(
                                        source: NewDataDataSource,
                                        // showCheckboxColumn: true,
                                        // checkboxColumnSettings:  const DataGridCheckboxColumnSettings(showCheckboxOnHeader: false),
                                        allowSorting: true,
                                        allowMultiColumnSorting: true,
                                        allowTriStateSorting: true,
                                        showColumnHeaderIconOnHover: true,
                                        columnWidthMode: ColumnWidthMode.lastColumnFill,
                                        onQueryRowHeight: (details) {
                                          return details.getIntrinsicRowHeight(details.rowIndex);
                                        },
                                        columns: <GridColumn>[
                                          GridColumn(
                                              columnName: 'file_name',
                                              label: Container(
                                                  padding: const EdgeInsets.all(8.0),
                                                  alignment: Alignment.center,
                                                  child: const Text(
                                                    'Файл', 
                                                    style: TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                          fontStyle: FontStyle.normal,
                                                          fontSize: 14,
                                                          color: Color(0xFFF3F2F3),
                                                        ),
                                                  )
                                              )
                                          ),
                                          GridColumn(
                                              columnName: 'count_short_n',
                                              label: Container(
                                                  padding: const EdgeInsets.all(8.0),
                                                  alignment: Alignment.center,
                                                  child: const Text(
                                                    'Короткое оружие',
                                                    style: TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                          fontStyle: FontStyle.normal,
                                                          fontSize: 14,
                                                          color: Color(0xFFF3F2F3),
                                                        ),
                                                  )
                                              )
                                          ),
                                          GridColumn(
                                              columnName: 'count_long_n',
                                              label: Container(
                                                  padding: const EdgeInsets.all(8.0),
                                                  alignment: Alignment.center,
                                                  child: const Text(
                                                    'Длинное оружие',
                                                    style: TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                          fontStyle: FontStyle.normal,
                                                          fontSize: 14,
                                                          color: Color(0xFFF3F2F3),
                                                        ),
                                                  )
                                              )
                                          ),
                                          GridColumn(
                                              columnName: 'count_dangerous_people',
                                              label: Container(
                                                  padding: const EdgeInsets.all(8.0),
                                                  alignment: Alignment.center,
                                                  child: const Text(
                                                    'Опасные люди',
                                                    style: TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                          fontStyle: FontStyle.normal,
                                                          fontSize: 14,
                                                          color: Color(0xFFF3F2F3),
                                                        ),
                                                  )
                                              )
                                          ),
                                        ],
                                        footer: Container(
                                        color: const Color(0xFF0E223F),
                                        child: Center(
                                            child: 
                                            Padding(
                                              padding: const EdgeInsets.all(5),
                                              child: MaterialButton(
                                                onPressed: () {
                                                  
                                                },
                                                color: const Color(0xFF0E223F),
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(2.0),
                                                ),
                                                padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                                                textColor: const Color(0xFF0E223F),
                                                height: 50,
                                                minWidth: 110,
                                                child: const Text(
                                                  "Active Learning",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle: FontStyle.normal,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )),
                                          gridLinesVisibility: GridLinesVisibility.both,
                                          navigationMode: GridNavigationMode.row,
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
                    padding: EdgeInsets.fromLTRB(40, 90, 40, 0),
                    child: Divider(
                      color: Color(0xFF3882F2),
                      height: 16,
                      thickness: 2,
                      indent: 0,
                      endIndent: 0,
                    ),
                  ),
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
                    width: MediaQuery.of(context).size.width,
                    height: 440,
                    child:  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: CustomScrollView(
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            slivers: <Widget>[
                              SliverPadding(
                              padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate(
                                  <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                                      child: 
                                      SizedBox(
                                        width: 500,
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
                                                                        height: 320,
                                                                        width: MediaQuery.of(context).size.width * 1.15,
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
                                                padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
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
                                                padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
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
                  const Padding(
                    padding: EdgeInsets.fromLTRB(40, 40, 40, 0),
                    child: Divider(
                      color: Color(0xFF3882F2),
                      height: 16,
                      thickness: 2,
                      indent: 0,
                      endIndent: 0,
                    ),
                  ),
// ---------------------------------------------------------------------------------------------- //
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
                    child: 
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: MaterialButton(
                          onPressed: () async {
                            if (Platform.isWindows) {
                              try {
                                File file = File('./responce/data.txt');
                                if (file.existsSync()) {
                                    _showPredict(context, popup);
                                    OpenFile.open(file.path);
                                }
                                else {
                                  _showAlertPredict(context);
                                }
                              }
                              catch (e) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const DataNotFound()),
                                );
                              }
                            }
                          },
                          color: const Color(0xFF3882F2),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0),
                            
                          ),
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
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
