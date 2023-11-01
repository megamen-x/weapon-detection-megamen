import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:mmt_fl/src/main_pg/CVModel.dart';
import 'package:mmt_fl/src/main_pg/Left_Menu.dart';
import 'package:mmt_fl/src/syst_pg/DataNotFound.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';

// ---------------------------------------------------------------------------------------------- //
// Класс страницы
class CVVID extends StatefulWidget {
  const CVVID({super.key});
  @override
  State<CVVID> createState() => _CVVIDState();
}
// ---------------------------------------------------------------------------------------------- //
// сборщик
class  _CVVIDState extends State<CVVID>{
  late var newDataList = [];
  List<String> frstImgs = [
    "./assets/images/sml.png",
  ];
  List<String> bboxImgs = [

  ];
  List<String> cropImgs = [
    "./assets/images/sml.png",
  ];
// ---------------------------------------------------------------------------------------------- //
  
// ---------------------------------------------------------------------------------------------- //
  // инициация видео
  @override
  void initState() {
    super.initState();
  }
  @override
  void dispose() {
    super.dispose();
  }
// ---------------------------------------------------------------------------------------------- //

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
        else if (filename.contains('.mp4')) {
          if (Platform.isWindows) {
            File('assets/$filename')
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
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
        await Directory('responce/$filename').create(recursive: true);
      }
    }
  }
  
// ---------------------------------------------------------------------------------------------- //
  //загрузка видео 
  Future<void> uploadVideo() async {
    setState(() {
      _isLoading = true;
    });
    final picker = ImagePicker();
    final XFile? file = await picker.pickVideo(
            source: ImageSource.gallery, maxDuration: const Duration(seconds: 20));
    print(file?.path);
    final json = {'file': file?.path};
    final response = await http.post(
        Uri.parse('http://127.0.0.1:80/get_result_64'),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        body: jsonEncode(json),
    );
    if (response.statusCode == 200) {
      unzipFileFromResponse(response.bodyBytes);
      setState(() {
        flag = true;
        _isLoading = false;
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
    }
    else {
      print('Загрузка видео не удалась!');
      setState(() {
        _isLoading = false;
      });
    }
  }
// ---------------------------------------------------------------------------------------------- //
  // здесь была выгрузка изображений
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
// clearing files on Windows and Android
Future<void> clearFolders() async {
  if (Platform.isAndroid) {
      
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
    deleteFilesInFolder("./responce");
  }
}
// ---------------------------------------------------------------------------------------------- //
// popup виджет
  void _showAlert(BuildContext context) {
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(5, 30, 0, 15),
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
                                  _isLoading ? 'Загрузка...' : 'Ваше видео',
                                  style: const TextStyle(fontSize: 20, color: Color(0xFF181818)),
                                ),
                                onPressed: () => _isLoading ? null : uploadVideo(),
                                 style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(14),
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
                  // здесь была таблица
// ---------------------------------------------------------------------------------------------- //
                  const Padding(
                    padding: EdgeInsets.fromLTRB(8, 20, 8, 10),
                    child: Text(
                      "Ваше видео открроется в новом окне",
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
                  Container(
                    margin: const EdgeInsets.all(0),
                    padding: const EdgeInsets.all(0),
                    width: MediaQuery.of(context).size.width,
                    height: 250,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          "Для увеличения скорости обработки видео - используйте графические ускорители",
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            fontSize: 18,
                            color: Color(0xFF3882F2),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(0),
                          child:
                              Image(
                            image: AssetImage("assets/images/tmp.png"),
                            height: 170,
                            width: 170,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
// ---------------------------------------------------------------------------------------------- //
                  // здесь был вывод видео
// ---------------------------------------------------------------------------------------------- //
                  Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(0),
                    width: MediaQuery.of(context).size.width,
                    height: 180,
                    decoration: const BoxDecoration(
                      color: Color(0x00000000),
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.zero,
                    ),
                    child: 
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: MaterialButton(
                              onPressed: () {                              
                                if (Platform.isWindows) {
                                  try {
                                    File file = File('./responce/data.txt');
                                    if (file.existsSync()) {
                                        OpenFile.open(file.path);
                                    }
                                    else {
                                      _showAlert(context);
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
                              height: 50,
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
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: MaterialButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const CVModel()),
                                );
                              },
                              color: const Color(0xFF3882F2),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                              textColor: const Color(0xFF181818),
                              height: 50,
                              minWidth: 100,
                              child: const Text(
                                "Назад",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.normal,
                                ),
                              ),
                            ),
                          ),
                        ],
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