import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

class DocxUtils {
  late Archive _archive;
  late XmlDocument _document;
  late String path;

  /// Load a .docx from disk.
  void load(String path) {
    this.path = path;
    final bytes = File(path).readAsBytesSync();
    _archive = ZipDecoder().decodeBytes(bytes);

    final docFile = _archive.files.firstWhere(
      (f) => f.name == 'word/document.xml',
      orElse: () => throw StateError('word/document.xml not found in archive'),
    );
    final xmlString = utf8.decode(docFile.content as List<int>);
    _document = XmlDocument.parse(xmlString);
  }

  /// Set the text of a single cell.
  ///
  /// [table], [row], [col] are 1-based by default (set [oneBased] = false for 0-based).
  /// NOTE: `findAllElements` is recursive, so nested tables also count toward the
  /// table list. Rows/cells are read as direct children, so they stay nested-safe.
  void setCell({
    required int table,
    required int row,
    required int col,
    required String text,
    bool oneBased = true,
  }) {
    final offset = oneBased ? 1 : 0;

    final tables = _document.rootElement
        .findAllElements('tbl', namespace: '*')
        .toList();
    final t = table - offset;
    if (t < 0 || t >= tables.length) {
      throw RangeError('table $table out of range (found ${tables.length})');
    }

    final rows = tables[t].childElements
        .where((e) => e.name.local == 'tr')
        .toList();
    final r = row - offset;
    if (r < 0 || r >= rows.length) {
      throw RangeError('row $row out of range (found ${rows.length})');
    }

    final cells = rows[r].childElements
        .where((e) => e.name.local == 'tc')
        .toList();
    final c = col - offset;
    if (c < 0 || c >= cells.length) {
      throw RangeError('col $col out of range (found ${cells.length})');
    }

    _writeText(cells[c], text);
  }

  /// Convenience: fill many cells at once.
  ///
  ///   filler.setCells([
  ///     (table: 1, row: 2, col: 3, text: 'hello'),
  ///     (table: 1, row: 3, col: 3, text: 'world'),
  ///   ]);
  void setCells(
    List<({int table, int row, int col, String text})> entries, {
    bool oneBased = true,
  }) {
    for (final e in entries) {
      setCell(
        table: e.table,
        row: e.row,
        col: e.col,
        text: e.text,
        oneBased: oneBased,
      );
    }
  }

  /// Insert a new row directly above an existing template row, cloning the
  /// structure of that template row (the last row by default) so column
  /// widths, borders, cell properties (tcPr), fonts, and RTL settings are
  /// preserved.
  ///
  /// [values] fill the new row's cells left-to-right. Cells with no matching
  /// value are emptied; values beyond the cell count are ignored.
  ///
  /// [templateRow] selects which existing row to clone (1-based by default,
  /// respecting [oneBased]) — this is also where the new row lands: it's
  /// inserted directly above that row. Defaults to the last row, in which
  /// case the new row ends up second-to-last (directly above the last row),
  /// not at the very end. Pass an explicit [templateRow] for any other
  /// position. To insert a copy *below* a row instead, use [duplicateRow].
  ///
  /// Returns the new row's index (1-based by default).
  int appendRow({
    required int table,
    List<String> values = const [],
    int? templateRow,
    bool oneBased = true,
  }) {
    final offset = oneBased ? 1 : 0;

    final tables = _document.rootElement
        .findAllElements('tbl', namespace: '*')
        .toList();
    final t = table - offset;
    if (t < 0 || t >= tables.length) {
      throw RangeError('table $table out of range (found ${tables.length})');
    }

    final tbl = tables[t];
    final rows = tbl.childElements.where((e) => e.name.local == 'tr').toList();
    if (rows.isEmpty) {
      throw StateError('table $table has no rows to use as a template');
    }

    final templateIdx = templateRow == null
        ? rows.length - 1
        : templateRow - offset;
    if (templateIdx < 0 || templateIdx >= rows.length) {
      throw RangeError(
        'templateRow ${templateRow ?? rows.length} out of range '
        '(found ${rows.length})',
      );
    }

    final templateRowElement = rows[templateIdx];

    // Deep-clone the template row so all structure/formatting carries over.
    final newRow = templateRowElement.copy();

    // Reset text in each cloned cell, then fill with the provided values.
    final cells = newRow.childElements
        .where((e) => e.name.local == 'tc')
        .toList();
    for (var i = 0; i < cells.length; i++) {
      _writeText(cells[i], i < values.length ? values[i] : '');
    }

    // Insert directly above the template row.
    final idx = tbl.children.indexOf(templateRowElement);
    tbl.children.insert(idx, newRow);

    return templateIdx + offset;
  }

  /// Insert several rows at once, each landing directly above [templateRow]
  /// (the last row by default), in the order given — so they end up stacked
  /// in order, immediately above that row.
  /// Each inner list fills one row's cells.
  /// Returns the new rows' indices (1-based by default).
  ///
  ///   filler.appendRows(1, [
  ///     ['Item A', '10', '5.00'],
  ///     ['Item B', '3',  '2.50'],
  ///   ]);
  List<int> appendRows(
    int table,
    List<List<String>> rowsValues, {
    int? templateRow,
    bool oneBased = true,
  }) {
    return [
      for (final values in rowsValues)
        appendRow(
          table: table,
          values: values,
          templateRow: templateRow,
          oneBased: oneBased,
        ),
    ];
  }

  /// Duplicate an existing row and insert the copy directly below it
  /// (rather than at the end of the table), cloning all structure and
  /// formatting (column widths, borders, cell properties, fonts, RTL, etc.)
  /// from that row. Every row after it shifts down by one.
  ///
  /// [table] selects which table; [row] selects which existing row to
  /// duplicate (1-based by default, respecting [oneBased]) — this is both
  /// the row whose formatting is cloned and the row the copy is inserted
  /// below.
  ///
  /// [values] fill the new row's cells left-to-right. Cells with no
  /// matching value are emptied; values beyond the cell count are ignored.
  /// If [values] is omitted, the duplicate keeps the same text as the
  /// source row.
  ///
  /// Returns the new row's index (1-based by default).
  int duplicateRow({
    required int table,
    required int row,
    List<String>? values,
    bool oneBased = true,
  }) {
    final offset = oneBased ? 1 : 0;

    final tables = _document.rootElement
        .findAllElements('tbl', namespace: '*')
        .toList();
    final t = table - offset;
    if (t < 0 || t >= tables.length) {
      throw RangeError('table $table out of range (found ${tables.length})');
    }

    final tbl = tables[t];
    final rows = tbl.childElements.where((e) => e.name.local == 'tr').toList();
    if (rows.isEmpty) {
      throw StateError('table $table has no rows to duplicate');
    }

    final sourceIdx = row - offset;
    if (sourceIdx < 0 || sourceIdx >= rows.length) {
      throw RangeError('row $row out of range (found ${rows.length})');
    }

    final sourceRow = rows[sourceIdx];

    // Deep-clone the selected row so all structure/formatting carries over.
    final newRow = sourceRow.copy();

    // Only overwrite text if explicit values were given; otherwise the
    // clone keeps the source row's text untouched.
    if (values != null) {
      final cells = newRow.childElements
          .where((e) => e.name.local == 'tc')
          .toList();
      for (var i = 0; i < cells.length; i++) {
        _writeText(cells[i], i < values.length ? values[i] : '');
      }
    }

    // Insert right after the source row, pushing subsequent rows down.
    final idx = tbl.children.indexOf(sourceRow);
    tbl.children.insert(idx + 1, newRow);

    return row + 1;
  }

  /// Duplicate the same source row multiple times, inserting each copy in
  /// order directly below that row (so they appear immediately after it,
  /// in the same order as [rowsValues], pushing the table's later rows
  /// further down).
  ///
  /// [row] selects which existing row to duplicate (1-based by default,
  /// respecting [oneBased]); its formatting is cloned for every new row.
  ///
  ///   filler.duplicateRows(table: 1, row: 2, rowsValues: [
  ///     ['Item A', '10', '5.00'],
  ///     ['Item B', '3',  '2.50'],
  ///   ]);
  ///
  /// Returns the new rows' indices (1-based by default).
  List<int> duplicateRows({
    required int table,
    required int row,
    required List<List<String>> rowsValues,
    bool oneBased = true,
  }) {
    final offset = oneBased ? 1 : 0;

    final tables = _document.rootElement
        .findAllElements('tbl', namespace: '*')
        .toList();
    final t = table - offset;
    if (t < 0 || t >= tables.length) {
      throw RangeError('table $table out of range (found ${tables.length})');
    }

    final tbl = tables[t];
    final rows = tbl.childElements.where((e) => e.name.local == 'tr').toList();
    if (rows.isEmpty) {
      throw StateError('table $table has no rows to duplicate');
    }

    final sourceIdx = row - offset;
    if (sourceIdx < 0 || sourceIdx >= rows.length) {
      throw RangeError('row $row out of range (found ${rows.length})');
    }

    final sourceRow = rows[sourceIdx];
    var insertAfter = sourceRow;
    final newIndices = <int>[];

    for (var i = 0; i < rowsValues.length; i++) {
      final newRow = sourceRow.copy();
      final cells = newRow.childElements
          .where((e) => e.name.local == 'tc')
          .toList();
      final values = rowsValues[i];
      for (var c = 0; c < cells.length; c++) {
        _writeText(cells[c], c < values.length ? values[c] : '');
      }

      final idx = tbl.children.indexOf(insertAfter);
      tbl.children.insert(idx + 1, newRow);

      insertAfter = newRow;
      newIndices.add(row + i + 1);
    }

    return newIndices;
  }

  /// Save the modified document to disk.
  ///
  /// IMPORTANT: never pass [path] (the original template's load path) here
  /// — that overwrites the template itself. Always save to a disposable
  /// copy in a temp folder (see `PrintUtils.prepareFromTemplate`); that
  /// temp path is the only thing that should ever be opened/printed.
  void save(String path) {
    final newXml = _document.toXmlString();
    final out = Archive();

    for (final f in _archive.files) {
      if (f.name == 'word/document.xml') {
        final data = utf8.encode(newXml);
        out.addFile(ArchiveFile('word/document.xml', data.length, data));
      } else {
        out.addFile(f); // copy every other part untouched
      }
    }

    final encoded = ZipEncoder().encode(out);
    if (encoded == null) throw StateError('Failed to encode .docx');
    File(path).writeAsBytesSync(encoded);
  }

  // ---- internals -----------------------------------------------------------

  XmlElement _el(String prefix, String local) =>
      XmlElement(XmlName(local, prefix));

  /// Replace the cell's text while preserving the first run's formatting (rPr)
  /// and the paragraph properties (pPr) — fonts, bold, RTL, alignment, etc.
  void _writeText(XmlElement cell, String text) {
    // Reuse the first paragraph; drop any extra paragraphs in the cell.
    final paragraphs = cell.childElements
        .where((e) => e.name.local == 'p')
        .toList();

    XmlElement p;
    if (paragraphs.isEmpty) {
      p = _el('w', 'p');
      cell.children.add(p);
    } else {
      p = paragraphs.first;
      for (final extra in paragraphs.skip(1)) {
        extra.remove();
      }
    }

    // Capture formatting from the first existing run, then remove all runs.
    final runs = p.childElements.where((e) => e.name.local == 'r').toList();
    XmlElement? rPr;
    if (runs.isNotEmpty) {
      final firstRpr = runs.first.childElements
          .where((e) => e.name.local == 'rPr')
          .toList();
      if (firstRpr.isNotEmpty) rPr = firstRpr.first.copy();
      for (final run in runs) {
        run.remove();
      }
    }

    // Build the replacement run: <w:r>[<w:rPr/>]<w:t xml:space="preserve">text</w:t></w:r>
    final newRun = _el('w', 'r');
    if (rPr != null) newRun.children.add(rPr);

    final t = _el('w', 't');
    t.attributes.add(XmlAttribute(XmlName('space', 'xml'), 'preserve'));
    t.children.add(XmlText(text));
    newRun.children.add(t);

    // Insert the run right after pPr (if present), otherwise at the end.
    final pPr = p.childElements.where((e) => e.name.local == 'pPr').toList();
    if (pPr.isNotEmpty) {
      final idx = p.children.indexOf(pPr.first);
      p.children.insert(idx + 1, newRun);
    } else {
      p.children.add(newRun);
    }
  }
}
