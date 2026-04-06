import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
// Note: In Web, path_provider fails, so typical download needs html package, 
// but for this utility we assume Mobile or gracefully handle it.
import 'package:printing/printing.dart';

class PdfExportUtility {
  static Future<void> generateAndSaveMedicalReport(String patientId) async {
    final pdf = pw.Document();

    // Fetch data
    final recordsSnapshot = await FirebaseFirestore.instance
        .collection('treatments')
        .where('patientId', isEqualTo: patientId)
        .get();
        
    final prescriptionsSnapshot = await FirebaseFirestore.instance
        .collection('prescriptions')
        .where('patientId', isEqualTo: patientId)
        .get();

    final now = DateTime.now();
    final dateString = DateFormat('yyyy-MM-dd').format(now);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Health Connect', style: pw.TextStyle(color: PdfColors.deepPurple, fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Medical Report', style: const pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Patient ID: $patientId', style: const pw.TextStyle(fontSize: 14)),
            pw.Text('Generated on: $dateString', style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 10),

            // Prescriptions Section
            pw.Text('Doctor Prescriptions', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple)),
            pw.SizedBox(height: 10),
            if (prescriptionsSnapshot.docs.isEmpty)
              pw.Text("No prescriptions found.")
            else
              ...prescriptionsSnapshot.docs.map((doc) {
                final d = doc.data();
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Medicines:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(d['medicines'] ?? "-"),
                      pw.SizedBox(height: 5),
                      pw.Text("Activities:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(d['activities'] ?? "-"),
                    ],
                  ),
                );
              }).toList(),

            pw.SizedBox(height: 20),
            
            // Hospital Records Section
            pw.Text('Hospital Test Results & Treatments', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple)),
            pw.SizedBox(height: 10),
            if (recordsSnapshot.docs.isEmpty)
              pw.Text("No hospital records found.")
            else
              ...recordsSnapshot.docs.map((doc) {
                final d = doc.data();
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Diagnosis / Result:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(d['diagnosis'] ?? "-"),
                      pw.SizedBox(height: 5),
                      pw.Text("Treatment Plan:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(d['treatmentPlan'] ?? "-"),
                    ],
                  ),
                );
              }).toList(),
            
            pw.SizedBox(height: 30),
            pw.Center(
               child: pw.Text("End of Report", style: const pw.TextStyle(color: PdfColors.grey))
            )
          ];
        },
      ),
    );

    // Save or prompt download
    final bytes = await pdf.save();

    if (kIsWeb) {
      // In a real web app, we use html anchor to download. 
      // Using printing package's printing layout as fallback:
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/HealthReport_$dateString.pdf');
      await file.writeAsBytes(bytes);
      // We can also trigger the native share/print dialog for a better UX on mobile
      await Printing.sharePdf(bytes: bytes, filename: 'HealthReport_$dateString.pdf');
    }
  }
}
