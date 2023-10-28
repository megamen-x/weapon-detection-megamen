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
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
// import 'package:video_player/video_player.dart';

// MediaKit.ensureInitialized();
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
// ---------------------------------------------------------------------------------------------- //
  late final player = Player();
  late final controller = VideoController(player);
// ---------------------------------------------------------------------------------------------- //
  // инициация видео
  @override
  void initState() {
    super.initState();
    // Play a [Media] or [Playlist].
    // player.open(Media('D:/Work/hack_perm_megamen/perm_hack/mmt_fl/assets/images/test1.mp4'));
  }
  @override
  void dispose() {
    player.dispose();
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
        print("test dir");
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
        Uri.parse('http://127.0.0.1:8000/video'),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        body: jsonEncode(json),
    );
    if (response.statusCode == 200) {
      unzipFileFromResponse(response.bodyBytes);
      // const path = "./responce/data.txt";
      // File dataFile = File(path);
      // String dataString = dataFile.readAsStringSync();
      // final responceMap = jsonDecode(dataString);
      // print(jsonEncode(responceMap["data"]));
      setState(() {
        player.open(Media('D:/Work/hack_perm_megamen/perm_hack/mmt_fl/assets/images/test1.mp4'));
        flag = true;
        _isLoading = false;
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
    }
    else {
      print('Загрузка видео не удалась!');
      setState(() {
        _isLoading = false;
        player.open(Media('D:/Work/hack_perm_megamen/perm_hack/mmt_fl/assets/images/test1.mp4'));
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
      // final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
      // Directory flutter_assets_dir = Directory('${appDocumentsDir.path}/flutter_assets');
      // final String downloadsDir = (await getDownloadsDirectory())!.path;
      // List<FileSystemEntity> files = flutter_assets_dir.listSync();
      // print(files);
      // // getImageFileFromAssets('/sml.png');
      // deleteFilesInFolder(downloadsDir);
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
                    height: 460,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF3882F2), width: 2),
                      borderRadius: const BorderRadius.all(Radius.circular(6)),
                    ),
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
                                        width: MediaQuery.of(context).size.width,
                                        height: MediaQuery.of(context).size.width * 9.0 / 16.0,
                                        // Use [Video] widget to display video output.
                                        child: Video(controller: controller),
                                      ),
                                      // SizedBox(
                                      //   // height: MediaQuery.of(context).size.height,
                                      //   width: 300,
                                      //   child: Stack(
                                      //     children: [                           
                                      //       PageView.builder(
                                      //         controller: _pageController ,
                                      //         scrollDirection: Axis.horizontal,
                                      //         itemCount: bboxImgs.length,
                                      //         itemBuilder: (context, index) {
                                      //           return Align(
                                      //             alignment: Alignment.topCenter,
                                      //             child: Padding(
                                      //               padding: const EdgeInsets.symmetric(
                                      //                   vertical: 16, horizontal: 0),
                                      //               child: ClipRRect(
                                      //                 borderRadius: BorderRadius.circular(5.0),
                                      //                 child:
                                      //                   Column(
                                      //                     children: [
                                      //                       Image.file(File(bboxImgs[index]),
                                      //                                 height: 300,
                                      //                                 width: MediaQuery.of(context).size.width,
                                      //                                 fit: BoxFit.contain,
                                      //                       ),
                                      //                       Text(basename(bboxImgs[index].toString()), 
                                      //                       style: const TextStyle(
                                      //                         fontWeight: FontWeight.w400,
                                      //                         fontStyle: FontStyle.normal,
                                      //                         fontSize: 18,
                                      //                         color: Color(0xFFF3F2F3),
                                      //                       ),
                                      //                       )
                                      //                     ],
                                      //                   ),
                                      //               ),
                                      //             ),
                                      //           );
                                      //         },
                                      //       ),
                                      //       Align(
                                      //         alignment: Alignment.bottomCenter,
                                      //         child: Padding(
                                      //           padding: const EdgeInsets.fromLTRB(0, 0, 0, 35),
                                      //           child: SmoothPageIndicator(
                                      //             controller: _pageController ,
                                      //             count: bboxImgs.length,
                                      //             axisDirection: Axis.horizontal,
                                      //             effect: const ExpandingDotsEffect(
                                      //               dotColor: Color(0xFF2b548f),
                                      //               activeDotColor: Color(0xFF2b548f),
                                      //               dotHeight: 10,
                                      //               dotWidth: 10,
                                      //               radius: 16,
                                      //               spacing: 7,
                                      //               expansionFactor: 2,
                                      //             ),
                                      //           ),
                                      //         ),
                                      //       ),
                                      //       const Align(
                                      //         alignment: Alignment.topCenter,
                                      //         child: Padding(
                                      //           padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                                      //           child: Row(
                                      //             children: [
                                      //             Text(
                                      //             "Yolo BBOX on video",
                                      //             textAlign: TextAlign.center,
                                      //             overflow: TextOverflow.clip,
                                      //             style: TextStyle(
                                      //               fontWeight: FontWeight.w600,
                                      //               fontStyle: FontStyle.normal,
                                      //               fontSize: 14,
                                      //               color: Color(0xFFF3F2F3),
                                      //             ),
                                      //           ), ],
                                      //           ),
                                      //         ),
                                      //       ),  
                                      //     ],
                                      //   ),
                                      // ),
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