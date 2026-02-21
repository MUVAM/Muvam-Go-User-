import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart';

class ReceiptGenerator {
  static Future<File> generateReceipt({
    required int tripId,
    required String driverName,
    required String passengerName,
    required String paymentMethod,
    required double amount,
    required String completionTime,
  }) async {
    final pdf = pw.Document();

    String formattedTime = '';
    try {
      final dateTime = DateTime.parse(completionTime).toLocal();
      formattedTime = DateFormat('h:mma, MMM d,yyyy').format(dateTime);
    } catch (e) {
      formattedTime = completionTime;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final watermarks = <pw.Widget>[];

          for (double y = 50; y < 800; y += 120) {
            for (double x = 0; x < 600; x += 180) {
              watermarks.add(
                pw.Positioned(
                  left: x,
                  top: y,
                  child: pw.Transform.rotate(
                    angle: -0.3,
                    child: pw.Opacity(
                      opacity: 0.08,
                      child: pw.Text(
                        'MUVAM',
                        style: pw.TextStyle(
                          fontSize: 48,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
          }

          return pw.Stack(
            children: [
              ...watermarks,

              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 50,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Center(
                      child: pw.Text(
                        'Receipt',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 50),

                    pw.Center(
                      child: pw.Text(
                        'MUVAM',
                        style: pw.TextStyle(
                          fontSize: 36,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#2A8359'),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 50),

                    _buildReceiptRow('Driver', driverName),
                    pw.SizedBox(height: 30),

                    _buildReceiptRow('Passenger', passengerName),
                    pw.SizedBox(height: 30),

                    _buildReceiptRow(
                      'Trip Id',
                      '#${tripId.toString().toLowerCase()}',
                    ),
                    pw.SizedBox(height: 30),

                    _buildReceiptRow('Payment Method', paymentMethod),
                    pw.SizedBox(height: 30),

                    _buildReceiptRow(
                      'Amount',
                      '₦${NumberFormat('#,##0.00').format(amount)}',
                    ),
                    pw.SizedBox(height: 30),

                    _buildReceiptRow('Completion time', formattedTime),
                    pw.SizedBox(height: 60),

                    pw.Center(
                      child: pw.Text(
                        'Enjoy more seamless rides like this only on\nMUVAM',
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey500,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/receipt_$tripId.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static pw.Widget _buildReceiptRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 13, color: PdfColors.grey500),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
            font: Font.helvetica(),
          ),
        ),
      ],
    );
  }
}
