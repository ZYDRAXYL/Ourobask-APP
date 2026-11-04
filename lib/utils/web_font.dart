import 'package:flutter/foundation.dart' show kIsWeb;

/// ฟอนต์ไทยสำรองบน web/Electron (`assets/fonts/NotoSansThai.ttf`)
///
/// `ThemeData.fontFamilyFallback` ใส่ให้เฉพาะ text theme — สไตล์ที่ตั้งเองตรง ๆ
/// (`titleTextStyle` ของ AppBar, `textStyle` ใน `styleFrom`) ไม่ได้รับต่อ
/// ต้องใส่ค่านี้เอง ไม่งั้นข้อความไทยเป็นกล่องสี่เหลี่ยมตอนออฟไลน์
const List<String>? thaiFallback = kIsWeb ? <String>['NotoSansThai'] : null;
