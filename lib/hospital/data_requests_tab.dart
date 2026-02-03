import 'package:flutter/material.dart';

class DataRequestsTab extends StatelessWidget {
  const DataRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.swap_horiz_rounded,
                  size: 64,
                  color: Colors.blue,
                ),
                SizedBox(height: 20),
                Text(
                  "Patient Data Requests",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  "This section will allow hospitals to request\n"
                      "patient medical information from other hospitals\n"
                      "after patient consent.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 24),
                Chip(
                  label: Text("Coming Soon"),
                  backgroundColor: Color(0xFFE3F2FD),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
