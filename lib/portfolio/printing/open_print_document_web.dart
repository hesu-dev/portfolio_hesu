import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

import '../data/portfolio_data.dart';
import 'portfolio_pdf_document.dart';
import 'portfolio_print_document.dart';

/// Opens the tab before any await to retain the click's popup permission.
Future<bool> openPrintDocument(PortfolioData data) async {
  web.Window? preview;
  try {
    preview = web.window.open('', '_blank');
    if (preview == null) return false;
    preview.opener = null;
    _write(preview, '''<!doctype html><html lang="ko"><head>
<meta charset="utf-8"><title>${const HtmlEscape().convert(data.name)} 포트폴리오</title>
<style>body { margin:0; display:grid; place-items:center; min-height:100vh;
background:#292a2d; color:#fff; font:16px system-ui,sans-serif; }</style>
</head><body><p role="status">PDF를 준비하고 있습니다…</p></body></html>''');

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
          introduction: data.identity.biography,
        );
        if (preview.closed) return true;
        final pdf = web.Blob(
          [bytes.toJS].toJS,
          web.BlobPropertyBag(type: 'application/pdf'),
        );
        final url = web.URL.createObjectURL(pdf);
        preview.location.replace('$url#toolbar=1&navpanes=1&view=FitH');
        // Keep the URL alive for the viewer's later save/print operations.
        final viewer = preview;
        Timer.periodic(const Duration(seconds: 30), (timer) {
          if (viewer.closed) {
            web.URL.revokeObjectURL(url);
            timer.cancel();
          }
        });
        return true;
      } catch (_) {
        // Font loading or PDF rendering failure still leaves a printable copy.
      }
    }
    if (preview.closed) return true;
    _write(
      preview,
      buildPortfolioPrintDocument(data, introduction: data.identity.biography),
    );
    return true;
  } catch (_) {
    preview?.close();
    return false;
  }
}

void _write(web.Window window, String html) {
  window.document.open();
  window.document.write(html.toJS);
  window.document.close();
}
