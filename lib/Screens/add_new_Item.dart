import 'dart:io';
import 'package:app/Services/new_auction_item.dart';
import 'package:app/providers/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../Components/my_textfield.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() => _NewItemState();
}

class _NewItemState extends State<NewItem> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _minBidprice = TextEditingController();
  File? image;

  DateTime selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2010),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future getImage(ImageSource source) async {
    try {
      final tempImage = await ImagePicker().pickImage(source: source);
      if (tempImage == null) return;
      final imageTemporary = File(tempImage.path);
      setState(() {
        image = imageTemporary;
      });
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _minBidprice.dispose();
    super.dispose();
  }

  bool isloading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeProvider.of(context).colorToken.background,
      appBar: AppBar(
        title: const Text('Add new item'),
        centerTitle: true,
        backgroundColor: Colors.grey[300],
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(
            height: 20,
          ),
          MyTextField(
            controller: _name,
            hinText: 'Product Name',
            obsecureText: false,
          ),
          const SizedBox(
            height: 20,
          ),
          MyTextField(
            controller: _description,
            hinText: 'Description',
            obsecureText: false,
          ),
          const SizedBox(
            height: 20,
          ),
          MyTextField(
            controller: _minBidprice,
            hinText: 'Minimum Bid price',
            obsecureText: false,
          ),
          const SizedBox(
            height: 30,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    thickness: 0.5,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 30,
          ),
          const Text(
            'Auction End Date',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 25,
                fontFamily: 'SourceSans3'),
          ),
          const SizedBox(
            height: 20,
          ),
          ElevatedButton(
            onPressed: () => _selectDate(context),
            child: Text(
              'Click here to Pick end Date: ${selectedDate.day} - ${selectedDate.month} - ${selectedDate.year}',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SourceSans3'),
            ),
          ),
          const SizedBox(
            height: 30,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    thickness: 0.5,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 30,
          ),
          const Text(
            'Upload Image',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 25,
                fontFamily: 'SourceSans3'),
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      getImage(ImageSource.gallery);
                    },
                    icon: const Icon(
                      Icons.photo_album,
                      size: 20,
                    ),
                    label: const Text('Upload from Gallery'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      getImage(ImageSource.camera);
                    },
                    icon: const Icon(
                      Icons.camera_alt_outlined,
                      size: 20,
                    ),
                    label: const Text('Upload from Camera'),
                  ),
                ],
              ),
              image != null
                  ? Image.file(
                      image!,
                      height: 100,
                      width: 100,
                    )
                  : const FlutterLogo(
                      size: 100,
                    ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          const SizedBox(
            height: 35,
          ),
          ElevatedButton(
              onPressed: () {
                String name = _name.text;
                String minbid = _minBidprice.text;
                String desc = _description.text;

                if (name == null ||
                    minbid == null ||
                    desc == null ||
                    image == null) {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: Colors.grey.shade100,
                          title: const Text(
                            "Empty Field",
                            style: TextStyle(
                              fontFamily: 'SourceSansPro3',
                              color: Colors.black,
                            ),
                          ),
                          content: const Text(
                            "One multiple of your fields are empty",
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'SourceSansPro3',
                            ),
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text(
                                'Back',
                                style: TextStyle(fontFamily: 'SourceSansPro3'),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        );
                      });
                } else {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: Colors.grey.shade100,
                          title: const Text(
                            "Add New Item",
                            style: TextStyle(
                              fontFamily: 'SourceSansPro3',
                              color: Colors.black,
                            ),
                          ),
                          content: const Text(
                            "Are you sure?",
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'SourceSansPro3',
                            ),
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () async {
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    });
                                isloading = true;
                                await NewAuctionItem().addItem(
                                    _name.text.trim(),
                                    _minBidprice.text.trim(),
                                    _description.text.trim(),
                                    selectedDate.toString().substring(0, 10),
                                    image!,
                                    currentUser!.uid);
                                isloading = false;
                                if (isloading == false) {
                                  setState(() {
                                    Navigator.pop(context);
                                    _name.clear();
                                    _description.clear();
                                    _minBidprice.clear();
                                  });
                                }
                                // ignore: use_build_context_synchronously
                                Navigator.pop(context);
                                // ignore: avoid_print
                                print(isloading);
                              },
                              child: const Text(
                                'Yes',
                                style: TextStyle(fontFamily: 'SourceSansPro3'),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade700,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text(
                                'No',
                                style: TextStyle(fontFamily: 'SourceSansPro3'),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ],
                        );
                      });
                }
              },
              child: const Text(
                'Submit Data',
                style: TextStyle(fontSize: 25),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(10),
                backgroundColor: Colors.green,
              )),
          const SizedBox(
            height: 30,
          ),
        ]),
      ),
    );
  }
}
