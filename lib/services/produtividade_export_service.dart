import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/produtividade_provider.dart';

class ProdutividadeExportService {
  static Future<void> exportToPdf(ProdutividadeProvider data) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('PriceCollector - Relatório de Produtividade', 
                    style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.deepPurple)),
                  pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                    style: pw.TextStyle(font: font, fontSize: 10)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Métricas Globais
            pw.Text('Métricas Globais', style: pw.TextStyle(font: fontBold, fontSize: 14)),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildPdfMetric('Total Coletado', data.totalColetados.toString(), font, fontBold),
                _buildPdfMetric('Pendentes', data.totalPendentes.toString(), font, fontBold),
                _buildPdfMetric('Conclusão', '${(data.percentualConclusao * 100).toStringAsFixed(1)}%', font, fontBold),
                _buildPdfMetric('Velocidade', '${data.velocidadeMediaGlobal.toStringAsFixed(1)} i/h', font, fontBold),
              ],
            ),
            pw.SizedBox(height: 30),

            // Ranking da Equipe
            pw.Text('Ranking da Equipe', style: pw.TextStyle(font: fontBold, fontSize: 14)),
            pw.TableHelper.fromTextArray(
              headers: ['Pos', 'Nome', 'Matrícula', 'Itens', 'Velocidade', 'Tempo Médio'],
              data: List<List<String>>.generate(data.rankingEquipe.length, (index) {
                final user = data.rankingEquipe[index];
                return [
                  (index + 1).toString(),
                  user.nome,
                  user.matricula,
                  user.itensColetados.toString(),
                  '${user.velocidadeMedia.toStringAsFixed(1)} i/h',
                  '${user.tempoMedio.inMinutes}m ${user.tempoMedio.inSeconds % 60}s',
                ];
              }),
              headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple),
              cellStyle: pw.TextStyle(font: font),
              columnWidths: {
                0: const pw.FixedColumnWidth(30),
                1: const pw.FlexColumnWidth(),
                2: const pw.FixedColumnWidth(80),
                3: const pw.FixedColumnWidth(50),
                4: const pw.FixedColumnWidth(70),
                5: const pw.FixedColumnWidth(80),
              },
            ),
            pw.SizedBox(height: 30),

            // Progresso por Loja
            pw.Text('Progresso por Loja', style: pw.TextStyle(font: fontBold, fontSize: 14)),
            pw.TableHelper.fromTextArray(
              headers: ['Loja', 'Coletados', 'Total', '%'],
              data: data.progressoPorLoja.map((s) => [
                s.nome,
                s.coletados.toString(),
                s.total.toString(),
                '${(s.percentual * 100).toStringAsFixed(1)}%'
              ]).toList(),
              headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey700),
              cellStyle: pw.TextStyle(font: font),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Relatorio_Produtividade_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildPdfMetric(String label, String value, pw.Font font, pw.Font fontBold) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
        pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 16)),
      ],
    );
  }
}
