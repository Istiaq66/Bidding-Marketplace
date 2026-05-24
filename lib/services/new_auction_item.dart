import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';

class NewAuctionItem {
  
  UploadTask? uploadTask;

  Future addItem(String prodName, String minBidPrice, String description,
      String date, File photo, String userId) async {
    final fileName = basename(photo.path);
    final path = 'files/$fileName';
    final file = File(photo.path);
    final ref = FirebaseStorage.instance.ref().child(path);
    uploadTask = ref.putFile(file);
    final snapshot = await uploadTask!.whenComplete(() => {});
    final urlDownload = await snapshot.ref.getDownloadURL();


    await FirebaseFirestore.instance.collection('products').add({
      'User Id': userId,
      'Product Name': prodName,
      'Product Description': description,
      'Minimum Bid Price': minBidPrice,
      'Date': date,
      'Image Url': urlDownload,
    });
  }
}
