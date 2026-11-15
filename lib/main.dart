import 'package:flutter/material.dart';

void main() => runApp(const CyberScanApp());

const bg = Color(0xFF070B14);
const panel = Color(0xFF101827);
const cyan = Color(0xFF20E6F2);
const purple = Color(0xFF9B72FF);
const muted = Color(0xFF91A2B8);

class CyberScanApp extends StatelessWidget {
  const CyberScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CYBERSCAN X',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          primary: cyan,
          secondary: purple,
          surface: panel,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int selected = 0;
  final List<String> history = [];

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(onNavigate: (i) => setState(() => selected = i)),
      UrlScannerPage(onScanned: (value) {
        setState(() => history.insert(0, value));
      }),
      FileScannerPage(),
      HistoryPage(items: history),
      const SecurityPage(),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(),
            Expanded(child: IndexedStack(index: selected, children: pages)),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF0B1220),
        indicatorColor: cyan.withOpacity(.13),
        selectedIndex: selected,
        onDestinationSelected: (i) => setState(() => selected = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.link_rounded), label: 'الروابط'),
          NavigationDestination(icon: Icon(Icons.folder_copy_rounded), label: 'الملفات'),
          NavigationDestination(icon: Icon(Icons.history_rounded), label: 'السجل'),
          NavigationDestination(icon: Icon(Icons.shield_outlined), label: 'الحماية'),
        ],
      ),
    );
  }
}

class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
    child: Row(
      children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            gradient: const LinearGradient(colors: [cyan, purple]),
            boxShadow: [BoxShadow(color: cyan.withOpacity(.2), blurRadius: 18)],
          ),
          child: const Icon(Icons.shield_moon_rounded, color: bg, size: 25),
        ),
        const SizedBox(width: 11),
        const Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CYBERSCAN X', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.6)),
            Text('SECURITY INTELLIGENCE', style: TextStyle(fontSize: 9, color: muted, letterSpacing: 1.8)),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: cyan.withOpacity(.08),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: cyan.withOpacity(.3)),
          ),
          child: const Row(children: [
            Icon(Icons.circle, color: cyan, size: 7),
            SizedBox(width: 6),
            Text('SYSTEM READY', style: TextStyle(fontSize: 9, color: cyan, fontWeight: FontWeight.bold)),
          ]),
        ),
      ],
    ),
  );
}

class DashboardPage extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const DashboardPage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
    children: [
      const Text('مرحباً بك في مركز الحماية', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      const Text('أدوات مبسطة لمساعدتك على فهم المخاطر الرقمية.', style: TextStyle(color: muted, fontSize: 13)),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF123344), Color(0xFF17152F), Color(0xFF101827)]),
          border: Border.all(color: cyan.withOpacity(.35)),
          boxShadow: [BoxShadow(color: cyan.withOpacity(.07), blurRadius: 25)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.radar_rounded, color: cyan, size: 27),
            Spacer(),
            Text('CYBER DEFENSE / 01', style: TextStyle(color: cyan, fontSize: 9, letterSpacing: 1.4)),
          ]),
          const SizedBox(height: 16),
          const Text('ابقَ متيقظاً.\\nابقَ آمناً.', style: TextStyle(fontSize: 28, height: 1.2, fontWeight: FontWeight.w900)),
          const SizedBox(height: 9),
          const Text('افحص الروابط وتعلّم أساسيات السلامة الرقمية قبل التفاعل مع المحتوى المشبوه.', style: TextStyle(color: Color(0xFFB8C8D8), height: 1.5, fontSize: 12)),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => onNavigate(1),
            icon: const Icon(Icons.bolt_rounded),
            label: const Text('ابدأ فحص رابط'),
            style: FilledButton.styleFrom(backgroundColor: cyan, foregroundColor: bg),
          ),
        ]),
      ),
      const SizedBox(height: 20),
      const SectionHeading('مركز الأدوات', 'TOOLS'),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 11, crossAxisSpacing: 11, childAspectRatio: 1.48,
        children: [
          ToolTile(icon: Icons.link_rounded, title: 'فحص الروابط', subtitle: 'تحقق مبدئي من الرابط', color: cyan, onTap: () => onNavigate(1)),
          ToolTile(icon: Icons.insert_drive_file_outlined, title: 'فحص الملفات', subtitle: 'معلومات وإرشادات الملفات', color: purple, onTap: () => onNavigate(2)),
          ToolTile(icon: Icons.history_rounded, title: 'سجل الفحص', subtitle: 'عملياتك السابقة', color: const Color(0xFFFFC56E), onTap: () => onNavigate(3)),
          ToolTile(icon: Icons.school_outlined, title: 'مركز التوعية', subtitle: 'نصائح للحماية الرقمية', color: const Color(0xFF70E0A1), onTap: () => onNavigate(4)),
        ],
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFF201A12), borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFFFC56E).withOpacity(.28))),
        child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, color: Color(0xFFFFC56E)),
          SizedBox(width: 10),
          Expanded(child: Text('تنبيه: الإصدار الأول يقدم تحققاً محلياً مبدئياً ومواد توعوية، ولا يصدر حكماً موثوقاً بأن الرابط أو الملف خالٍ من البرمجيات الضارة.', style: TextStyle(color: Color(0xFFE6D5B8), fontSize: 11, height: 1.5))),
        ]),
      ),
    ],
  );
}

class SectionHeading extends StatelessWidget {
  final String title, tag;
  const SectionHeading(this.title, this.tag, {super.key});
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    const Spacer(),
    Text(tag, style: const TextStyle(color: muted, fontSize: 9, letterSpacing: 1.6)),
  ]);
}

class ToolTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const ToolTile({super.key, required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(17),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(17), border: Border.all(color: color.withOpacity(.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 25),
        const SizedBox(height: 9),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: muted, fontSize: 10)),
      ]),
    ),
  );
}

class UrlScannerPage extends StatefulWidget {
  final ValueChanged<String> onScanned;
  const UrlScannerPage({super.key, required this.onScanned});
  @override
  State<UrlScannerPage> createState() => _UrlScannerPageState();
}

class _UrlScannerPageState extends State<UrlScannerPage> {
  final controller = TextEditingController();
  String? result;
  bool valid = false;

  void check() {
    final raw = controller.text.trim();
    final uri = Uri.tryParse(raw);
    final ok = uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.contains('.');
    setState(() {
      valid = ok;
      result = ok
        ? 'صيغة الرابط تبدو صحيحة. هذا تحقق شكلي محلي فقط، ولم يتم فحص سمعة الموقع أو محتواه.'
        : 'صيغة الرابط غير مكتملة. أدخل رابطاً يبدأ بـ https:// أو http:// ويحتوي على اسم نطاق.';
    });
    if (ok) widget.onScanned(raw);
  }

  @override
  void dispose() { controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('URL SCANNER', style: TextStyle(color: cyan, letterSpacing: 2, fontSize: 11, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    const Text('فحص الروابط', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
    const SizedBox(height: 7),
    const Text('تحقق من تنسيق الرابط قبل فتحه. لا تفتح روابط لا تثق بمصدرها.', style: TextStyle(color: muted, fontSize: 12, height: 1.5)),
    const SizedBox(height: 22),
    Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(19), border: Border.all(color: cyan.withOpacity(.22))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.travel_explore_rounded, color: cyan, size: 32),
        const SizedBox(height: 14),
        const Text('أدخل عنوان URL', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 11),
        TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            hintText: 'https://example.com',
            hintStyle: const TextStyle(color: Color(0xFF65758A), fontSize: 12),
            filled: true, fillColor: bg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.link, color: cyan),
          ),
        ),
        const SizedBox(height: 13),
        SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: check,
          icon: const Icon(Icons.radar_rounded),
          label: const Text('تحقق من التنسيق'),
          style: FilledButton.styleFrom(backgroundColor: cyan, foregroundColor: bg, padding: const EdgeInsets.symmetric(vertical: 14)),
        )),
      ]),
    ),
    if (result != null) ...[
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: valid ? const Color(0xFF10271F) : const Color(0xFF2B1B20), borderRadius: BorderRadius.circular(15), border: Border.all(color: valid ? const Color(0xFF70E0A1) : const Color(0xFFFF8290).withOpacity(.5))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(valid ? Icons.info_outline : Icons.warning_amber_rounded, color: valid ? const Color(0xFF70E0A1) : const Color(0xFFFF8290)),
          const SizedBox(width: 10),
          Expanded(child: Text(result!, style: const TextStyle(fontSize: 12, height: 1.5))),
        ]),
      ),
    ],
    const SizedBox(height: 18),
    const InfoPanel(title: 'ما الذي يفعله هذا الإصدار؟', body: 'يتحقق محلياً من وجود بروتوكول HTTP/HTTPS واسم نطاق. لا يتصل بموقع خارجي ولا يكشف التصيد أو الفيروسات. سنضيف خدمة فحص سمعة الروابط في مرحلة لاحقة.'),
  ]);
}

class FileScannerPage extends StatelessWidget {
  const FileScannerPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('FILE INSPECTOR', style: TextStyle(color: purple, letterSpacing: 2, fontSize: 11, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    const Text('فحص الملفات', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
    const SizedBox(height: 7),
    const Text('تعرف على خطوات التعامل الآمن مع الملفات التي تصلك.', style: TextStyle(color: muted, fontSize: 12)),
    const SizedBox(height: 22),
    Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: purple.withOpacity(.3))),
      child: const Column(children: [
        Icon(Icons.folder_zip_outlined, size: 58, color: purple),
        SizedBox(height: 14),
        Text('ماسح الملفات قيد التجهيز', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('سيتم تفعيل اختيار الملفات وإرسالها إلى خدمة فحص موثوقة بعد إعداد الخادم وسياسة الخصوصية. لا يتم رفع أي ملف في هذا الإصدار.', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12, height: 1.6)),
      ]),
    ),
    const SizedBox(height: 16),
    const InfoPanel(title: 'نصيحة مهمة', body: 'لا تثبّت ملفات APK من مصادر مجهولة، وراجع اسم الناشر والأذونات المطلوبة قبل التثبيت.'),
  ]);
}

class HistoryPage extends StatelessWidget {
  final List<String> items;
  const HistoryPage({super.key, required this.items});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('SCAN HISTORY', style: TextStyle(color: cyan, letterSpacing: 2, fontSize: 11, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    const Text('سجل الفحص', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
    const SizedBox(height: 16),
    if (items.isEmpty)
      const InfoPanel(title: 'لا توجد عمليات بعد', body: 'عندما تتحقق من تنسيق رابط في قسم فحص الروابط، سيظهر هنا خلال جلسة التطبيق الحالية.')
    else
      ...items.map((item) => Container(
        margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(13), border: Border.all(color: cyan.withOpacity(.12))),
        child: Row(children: [
          const Icon(Icons.link, color: cyan),
          const SizedBox(width: 10),
          Expanded(child: Text(item, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
          const Icon(Icons.check_circle_outline, color: muted, size: 17),
        ]),
      )),
  ]);
}

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('SECURITY CENTER', style: TextStyle(color: const Color(0xFF70E0A1), letterSpacing: 2, fontSize: 11, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    const Text('مركز التوعية', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
    const SizedBox(height: 16),
    const InfoPanel(title: '1. تحقق من المرسل', body: 'لا تثق برسالة لمجرد أنها تحمل شعار شركة معروفة. تحقق من عنوان المرسل عبر قناة رسمية.'),
    const SizedBox(height: 10),
    const InfoPanel(title: '2. لا تشارك رموز التحقق', body: 'رموز التحقق وكلمات المرور معلومات خاصة. لا ترسلها لأي شخص يدّعي أنه من الدعم الفني.'),
    const SizedBox(height: 10),
    const InfoPanel(title: '3. حدّث تطبيقاتك', body: 'التحديثات الرسمية تصلح ثغرات أمنية وتحسن استقرار الجهاز.'),
    const SizedBox(height: 10),
    const InfoPanel(title: '4. راجع الأذونات', body: 'امنح التطبيق الأذونات التي يحتاجها فقط، وراجعها من إعدادات الهاتف.'),
  ]);
}

class InfoPanel extends StatelessWidget {
  final String title, body;
  const InfoPanel({super.key, required this.title, required this.body});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(.07))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: cyan, fontSize: 13)),
      const SizedBox(height: 7),
      Text(body, style: const TextStyle(color: muted, fontSize: 11, height: 1.6)),
    ]),
  );
}
