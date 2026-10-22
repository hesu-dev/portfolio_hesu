import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

import '../data/portfolio_data.dart';
import 'portfolio_pdf_document.dart';
import 'portfolio_print_document.dart';

/// Opens the tab before any await to retain the click's popup permission.
Future<bool> openPrintDocument(PortfolioData data) async {
  web.Window? preview;
  final ready = Completer<void>();
  final previewUrl = Uri.base.resolve('print-preview.html').toString();
  final onReady = ((web.MessageEvent event) {
    if (event.origin == web.window.location.origin && event.source == preview) {
      if (event.data.dartify() case {'type': 'portfolio-print-ready'}) {
        if (!ready.isCompleted) ready.complete();
      }
    }
  }).toJS;
  web.window.addEventListener('message', onReady);
  try {
    preview = web.window.open(previewUrl, '_blank');
    if (preview == null) return false;
    await ready.future.timeout(const Duration(seconds: 15));

    String? pdfUrl;
    if (web.window.navigator.pdfViewerEnabled) {
      try {
        final fonts = await Future.wait([
          rootBundle.load('assets/pdf_fonts/NanumGothic-Regular.ttf'),
          rootBundle.load('assets/pdf_fonts/NanumGothic-Bold.ttf'),
        ]);
        final bytes = await buildPortfolioPdfDocument(
          data,
          regularFont: fonts[0],
          boldFont: fonts[1],
          introduction: data.introduction,
        );
        if (preview.closed) return true;
        final pdf = web.Blob(
          [bytes.toJS].toJS,
          web.BlobPropertyBag(type: 'application/pdf'),
        );
        pdfUrl = web.URL.createObjectURL(pdf);
      } catch (_) {
        // Font loading or PDF rendering failure still leaves a printable copy.
      }
    }
    // Returning while the fonts/PDF load must not replace the portfolio page.
    if (preview.closed || preview.location.href != previewUrl) {
      if (pdfUrl != null) web.URL.revokeObjectURL(pdfUrl);
      return true;
    }
    preview.postMessage(
      {
        'type': 'portfolio-print-document',
        'title': '${data.name} 포트폴리오',
        'returnUrl': web.window.location.href,
        'html': buildPortfolioPrintDocument(
          data,
          introduction: data.introduction,
        ),
        'pdfUrl': pdfUrl,
      }.jsify(),
      web.window.location.origin.toJS,
    );
    return true;
  } catch (_) {
    if (preview?.closed ?? false) return true;
    preview?.close();
    return false;
  } finally {
    web.window.removeEventListener('message', onReady);
  }
}
