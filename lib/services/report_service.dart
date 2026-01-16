import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/attendance_model.dart';
import '../models/user_model.dart';

class ReportService {
  Future<void> generateAndPrintReport(List<AttendanceModel> records, List<UserInfo> students) async {
    final pdf = pw.Document();
    
    // İnternet gerektirmeyen standart font kullanımı
    final font = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: boldFont,
        ),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Yurt Denetim Raporu', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Son 30 Gunluk Yoklama Kayitlari',
              style: pw.TextStyle(fontSize: 18),
            ),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              context: context,
              headers: ['Tarih', 'Ogrenci Adi', 'Oda', 'Durum'],
              data: records.map((record) {
                final student = students.firstWhere(
                  (s) => s.studentId == record.studentId,
                  orElse: () => UserInfo(uid: '', email: '', fullName: 'Bilinmeyen', roomNumber: '-'),
                );
                
                String statusText = '';
                 switch (record.status) {
                  case AttendanceStatus.present: statusText = 'Yurtta'; break;
                  case AttendanceStatus.onLeave: statusText = 'Izinli'; break;
                  case AttendanceStatus.absent: statusText = 'YOK'; break;
                }
                
                return [
                  DateFormat('dd.MM.yyyy').format(record.date),
                  student.fullName, // Türkçe karakterler PDF varsayılan fontunda görünmeyebilir
                  student.roomNumber ?? '-',
                  statusText,
                ];
              }).toList(),
            ),
            pw.Footer(
              leading: pw.Text('YurtNet Otomasyon Sistemi'),
              trailing: pw.Text('Sayfa ${context.pageNumber} / ${context.pagesCount}'),
            ),
          ];
        },
      ),
    );

    // Önizleme veya yazdırma ekranını aç
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'YurtNet_Denetim_Raporu_${DateFormat('yyyyMMdd').format(DateTime.now())}',
    );
  }
}
