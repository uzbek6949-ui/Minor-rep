import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:minor_rep/services/id3_reader.dart';

/// ID3v2.4 "synchsafe" o'lcham.
List<int> _synchSafe(int size) => <int>[
  (size >> 21) & 0x7F,
  (size >> 14) & 0x7F,
  (size >> 7) & 0x7F,
  size & 0x7F,
];

List<int> _bigEndian32(int size) => <int>[
  (size >> 24) & 0xFF,
  (size >> 16) & 0xFF,
  (size >> 8) & 0xFF,
  size & 0xFF,
];

/// ID3v2.3 freymi: id(4) + o'lcham(4) + flaglar(2) + tana.
List<int> _frame(String id, List<int> body) => <int>[
  ...latin1.encode(id),
  ..._bigEndian32(body.length),
  0,
  0,
  ...body,
];

List<int> _utf16leWithBom(String text) {
  final bytes = <int>[0xFF, 0xFE];
  for (final unit in text.codeUnits) {
    bytes.add(unit & 0xFF);
    bytes.add((unit >> 8) & 0xFF);
  }
  return bytes;
}

List<int> _latin1Padded(String text, int length) {
  final bytes = latin1.encode(text).take(length).toList();
  return <int>[...bytes, ...List<int>.filled(length - bytes.length, 0)];
}

Future<File> _writeTempFile(String name, List<int> bytes) async {
  final dir = await Directory.systemTemp.createTemp('minor_rep_id3');
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

void main() {
  group('Id3Reader — ID3v2.3', () {
    test(
      'nom, ijrochi, albom, janr, davomiylik, matn va rasmni o’qiydi',
      () async {
        final frames = <int>[
          ..._frame('TIT2', <int>[0x00, ...latin1.encode('Tungi Yulduz')]),
          ..._frame('TPE1', <int>[0x01, ..._utf16leWithBom('Ijrochi Café')]),
          ..._frame('TALB', <int>[0x00, ...latin1.encode('Tungi Albom')]),
          // "(13)" — ID3v1 janr raqami, "Pop" ga aylanishi kerak.
          ..._frame('TCON', <int>[0x00, ...latin1.encode('(13)')]),
          ..._frame('TLEN', <int>[0x00, ...latin1.encode('215000')]),
          ..._frame('USLT', <int>[
            0x00,
            ...latin1.encode('uzb'),
            0x00, // tavsif (descriptor) bo'sh
            ...latin1.encode('Birinchi qator\r\nIkkinchi qator'),
          ]),
          ..._frame('APIC', <int>[
            0x00,
            ...latin1.encode('image/jpeg'),
            0x00,
            0x03, // front cover
            0x00, // tavsif bo'sh
            0xFF, 0xD8, 0xFF, 0xD9, // "rasm" baytlari
          ]),
          // to'ldirish (padding)
          ...List<int>.filled(16, 0),
        ];

        final bytes = <int>[
          ...latin1.encode('ID3'),
          0x03, 0x00, // 2.3.0
          0x00, // flaglar
          ..._synchSafe(frames.length),
          ...frames,
          ...List<int>.filled(64, 0x55), // "audio" ma'lumoti
        ];

        final tags = await Id3Reader.read(
          await _writeTempFile('v23.mp3', bytes),
        );

        expect(tags.title, 'Tungi Yulduz');
        expect(tags.artist, 'Ijrochi Café');
        expect(tags.album, 'Tungi Albom');
        expect(tags.genre, 'Pop');
        expect(tags.durationMs, 215000);
        expect(tags.lyrics, 'Birinchi qator\nIkkinchi qator');
        expect(tags.artwork, isNotNull);
        expect(tags.artwork!.length, 4);
        expect(tags.artworkExtension, 'jpg');
      },
    );

    test('UTF-8 va PNG rasm bilan ishlaydi', () async {
      final frames = <int>[
        ..._frame('TIT2', <int>[0x03, ...utf8.encode('Qo’shiq — 1')]),
        ..._frame('APIC', <int>[
          0x00,
          ...latin1.encode('image/png'),
          0x00,
          0x00, // boshqa tur (front cover emas)
          0x00,
          0x89, 0x50, 0x4E, 0x47,
        ]),
      ];
      final bytes = <int>[
        ...latin1.encode('ID3'),
        0x03,
        0x00,
        0x00,
        ..._synchSafe(frames.length),
        ...frames,
      ];

      final tags = await Id3Reader.read(
        await _writeTempFile('utf8.mp3', bytes),
      );
      expect(tags.title, 'Qo’shiq — 1');
      expect(tags.artworkExtension, 'png');
      expect(tags.artwork!.length, 4);
    });
  });

  group('Id3Reader — ID3v1', () {
    test('v2 tegi bo’lmasa, oxiridagi TAG bloki o’qiladi', () async {
      final bytes = <int>[
        ...List<int>.filled(256, 0x41), // "audio"
        ...latin1.encode('TAG'),
        ..._latin1Padded('Eski Qoshiq', 30),
        ..._latin1Padded('Eski Ijrochi', 30),
        ..._latin1Padded('Eski Albom', 30),
        ..._latin1Padded('1999', 4),
        ..._latin1Padded('', 30),
        17, // Rock
      ];

      final tags = await Id3Reader.read(await _writeTempFile('v1.mp3', bytes));
      expect(tags.title, 'Eski Qoshiq');
      expect(tags.artist, 'Eski Ijrochi');
      expect(tags.album, 'Eski Albom');
      expect(tags.genre, 'Rock');
      expect(tags.artwork, isNull);
    });
  });

  group('Id3Reader — xatoliklarga chidamlilik', () {
    test('tegsiz fayl bo’sh natija beradi', () async {
      final file = await _writeTempFile(
        'plain.mp3',
        List<int>.filled(512, 0x33),
      );
      final tags = await Id3Reader.read(file);
      expect(tags.title, isNull);
      expect(tags.artist, isNull);
      expect(tags.artwork, isNull);
    });

    test('juda kichik / buzilgan fayl istisno tashlamaydi', () async {
      final file = await _writeTempFile('tiny.mp3', <int>[0x49, 0x44, 0x33]);
      final tags = await Id3Reader.read(file);
      expect(tags.title, isNull);
    });

    test('mavjud bo’lmagan fayl bo’sh natija beradi', () async {
      final tags = await Id3Reader.read(File('/does/not/exist.mp3'));
      expect(tags.title, isNull);
      expect(tags.durationMs, isNull);
    });
  });
}
