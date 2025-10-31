import 'package:auction_app/Screens/bid.dart';
import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String docId;
  final String name;
  final String minPrice;
  final String piclink;

  const ProductCard({
    super.key,
    required this.name,
    required this.minPrice,
    required this.piclink,
    required this.docId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 187, 222, 251),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 10,
          ),
          Expanded(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Material(
                  child: Ink.image(
                    fit: BoxFit.cover,
                    image: NetworkImage(piclink),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Bid(docId: docId),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'SourceSans3',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            '$minPrice tk',
            style: const TextStyle(
              fontFamily: 'SourceSans3',
              fontSize: 13,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
        ],
      ),
    );
  }
}
