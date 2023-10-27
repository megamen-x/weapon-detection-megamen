import 'package:flutter/material.dart';
import 'package:mmt_fl/src/main_pg/CVModel.dart';
import 'package:file_picker/file_picker.dart'; 
import 'package:open_file/open_file.dart';

void _openFile(PlatformFile file) { 
	OpenFile.open(file.path); 
}

void _pickFile() async { 

	final result = await FilePicker.platform.pickFiles(allowMultiple: true); 

	if (result == null) return; 

	final file = result.files.first; 

	_openFile(file); 
}

class Uploaded_files extends StatelessWidget {
  const Uploaded_files({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff5d6e76),
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0x00121212),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xffdafbea),
            size: 20,
          ),
          onPressed: () {
            Navigator.push(
              context,
              // MaterialPageRoute(builder: (context) => CVModel(newDataList: [],)),
              MaterialPageRoute(builder: (context) => const CVModel()),
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
            child:  IconButton(
              icon: const Icon(
                Icons.add,
                color: Color(0xffd9fae9),
                size: 24,
              ),
              onPressed: () {
                _pickFile();
              },
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 320, maxWidth: 620),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(10, 20, 0, 10),
                    child: Text(
                      "Uploaded Files",
                      textAlign: TextAlign.start,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.normal,
                        fontSize: 18,
                        color: Color(0xffd6fbe8),
                      ),
                    ),
                  ),
                  GridView(
                    padding: const EdgeInsets.all(8),
                    shrinkWrap: true,
                    scrollDirection: Axis.vertical,
                    physics: const ScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.9,
                    ),
                    children: [
                      Container(
                        margin: const EdgeInsets.all(0),
                        padding: const EdgeInsets.all(0),
                        width: 200,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xff353535),
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(5),
                              child:
        
                                  ///***If you have exported images you must have to copy those images in assets/images directory.
                                  Image(
                                image: AssetImage("assets/images/Untitled-1.png"),
                                height: 100,
                                width: 140,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Text(
                              "File_name",
                              textAlign: TextAlign.start,
                              overflow: TextOverflow.clip,
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.normal,
                                fontSize: 14,
                                color: Color(0xffffffff),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(0),
                        padding: const EdgeInsets.all(0),
                        width: 200,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xff353535),
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(5),
                              child:
        
                                  ///***If you have exported images you must have to copy those images in assets/images directory.
                                  Image(
                                image: AssetImage("assets/images/Untitled-1.png"),
                                height: 100,
                                width: 140,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Text(
                              "File_name",
                              textAlign: TextAlign.start,
                              overflow: TextOverflow.clip,
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.normal,
                                fontSize: 14,
                                color: Color(0xffffffff),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(0),
                        padding: const EdgeInsets.all(0),
                        width: 200,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xff353535),
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(5),
                              child:
        
                                  ///***If you have exported images you must have to copy those images in assets/images directory.
                                  Image(
                                image: AssetImage("assets/images/Untitled-1.png"),
                                height: 100,
                                width: 140,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Text(
                              "File_name",
                              textAlign: TextAlign.start,
                              overflow: TextOverflow.clip,
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.normal,
                                fontSize: 14,
                                color: Color(0xffffffff),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(0),
                        padding: const EdgeInsets.all(0),
                        width: 200,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xff353535),
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(5),
                              child:
        
                                  ///***If you have exported images you must have to copy those images in assets/images directory.
                                  Image(
                                image: AssetImage("assets/images/Untitled-1.png"),
                                height: 100,
                                width: 140,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Text(
                              "File_name",
                              textAlign: TextAlign.start,
                              overflow: TextOverflow.clip,
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.normal,
                                fontSize: 14,
                                color: Color(0xffffffff),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(0),
                        padding: const EdgeInsets.all(0),
                        width: 200,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xff353535),
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
