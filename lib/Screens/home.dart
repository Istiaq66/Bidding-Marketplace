import 'package:auction_app/Components/floating_action_button.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:auction_app/Components/product_card.dart';
import 'package:auction_app/Screens/add_new_Item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../Services/new_user.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    NewUser().checkUserExistence();
    super.initState();
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1), () {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: MyFloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewItem()),
          );
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade500,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Product Gallery',
                style: TextStyle(
                  fontFamily: 'SourceSans3',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Expanded(
                child: LiquidPullToRefresh(
              onRefresh: _handleRefresh,
              child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  future:
                      FirebaseFirestore.instance.collection('products').get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      final doc = snapshot.data!.docs;
                      return GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2),
                        itemCount: doc.length,
                        itemBuilder: (context, index) {
                          final documentData = doc[index].data();
                          return ProductCard(
                            name: 'Name: ${documentData['Product Name']}',
                            minPrice: 'Min bid price: ${documentData['Minimum Bid Price']}',
                            piclink: documentData['Image Url'],
                            docId: doc[index].id,
                          );

                        },
                      );
                    } else {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                  }),
            ))
          ],
        ),
      ),
    );
  }
}
