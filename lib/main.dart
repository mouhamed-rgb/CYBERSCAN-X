
import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String apiBaseUrl = 'https://cyberscan-x-backend.vercel.app';
const int maxFileBytes = 4 * 1024 * 1024;

void main() {
  runApp(const CyberScanApp());
}

class ScanRecord {
  final String name;
  final String type;
  final String status;
  final int malicious;
  final int suspicious;
  final int harmless;
  final DateTime date;

  const ScanRecord({
    required this.name,
    required this.type,
    required this.status,
    required this.malicious,
    required this.suspicious,
    required this.harmless,
    required this.date,
  });
}

class ScanResult {
  final String name;
  final String type;
  final String status;
  final Map<String, dynamic> stats;
  final Map<String, dynamic> results;
  final DateTime? date;

  const ScanResult({
    required this.name,
    required this.type,
    required this.status,
    required this.stats,
    required this.results,
    this.date,
  });

  int get malicious => number('malicious');
  int get suspicious => number('suspicious');
  int get harmless => number('harmless');
  int get undetected => number('undetected');
  int get timeout => number('timeout');

  int number(String key) {
    final value = stats[key];
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  int get detections => malicious + suspicious;
}

class CyberScanApp extends StatelessWidget {
  const CyberScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF22D3EE);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CYBERSCAN X',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080D18),
        colorScheme: ColorScheme.fromSeed(
          seedColor: cyan,
          brightness: Brightness.dark,
          surface: const Color(0xFF101827),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF111C2D),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF26364D)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF26364D)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: cyan, width: 1.5),
          ),
        ),
      ),
      home: const CyberHome(),
    );
  }
}

class CyberHome extends StatefulWidget {
  const CyberHome({super.key});

  @override
  State<CyberHome> createState() => _CyberHomeState();
}

class _CyberHomeState extends State<CyberHome> {
  int selectedTab = 0;
  bool busy = false;
  String progressMessage = '';
  ScanResult? latestResult;
  final List<ScanRecord> history = [];
  final TextEditingController urlController = TextEditingController();

  static const cyan = Color(0xFF22D3EE);
  static const purple = Color(0xFFA78BFA);

  @override
  void dispose() {
    urlController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> decodeResponse(
    http.Response response,
  ) async {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('The server returned an invalid response.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected server response.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        decoded['error']?.toString() ??
            'Server error (${response.statusCode}).',
      );
    }
    return decoded;
  }

  Future<void> scanUrl() async {
    final value = urlController.text.trim();

    if (value.isEmpty) {
      showMessage('Please enter a website URL.');
      return;
    }

    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasAuthority ||
        !['http', 'https'].contains(uri.scheme.toLowerCase())) {
      showMessage('Enter a complete URL beginning with https:// or http://');
      return;
    }

    await runScan(
      name: value,
      type: 'URL',
      submit: () async {
        final response = await http
            .post(
              Uri.parse('$apiBaseUrl/api/scan-url'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'url': value}),
            )
            .timeout(const Duration(seconds: 30));

        return decodeResponse(response);
      },
    );
  }

  Future<void> pickAndScanFile() async {
    if (busy) return;

    try {
      final selection = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true,
      );

      if (selection == null || selection.files.isEmpty) return;

      final file = selection.files.first;
      final bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        showMessage('Could not read this file. Please choose another.');
        return;
      }

      if (bytes.length > maxFileBytes) {
        showMessage('The file is larger than the 4 MB limit.');
        return;
      }

      await runScan(
        name: file.name,
        type: 'FILE',
        submit: () async {
          final request = http.MultipartRequest(
            'POST',
            Uri.parse('$apiBaseUrl/api/scan-file'),
          );

          request.files.add(
            http.MultipartFile.fromBytes(
              'file',
              bytes,
              filename: file.name,
            ),
          );

          final streamed = await request.send().timeout(
                const Duration(seconds: 60),
              );
          final response = await http.Response.fromStream(streamed);
          return decodeResponse(response);
        },
      );
    } catch (error) {
      showMessage(cleanError(error));
    }
  }

  Future<void> runScan({
    required String name,
    required String type,
    required Future<Map<String, dynamic>> Function() submit,
  }) async {
    if (busy) return;

    setState(() {
      busy = true;
      latestResult = null;
      progressMessage = 'Connecting to CYBERSCAN X backend...';
    });

    try {
      final submitted = await submit();
      final analysisId = submitted['analysisId']?.toString() ?? '';

      if (analysisId.isEmpty) {
        throw Exception('The server did not return an analysis ID.');
      }

      Map<String, dynamic>? analysis;
      const maxAttempts = 5;

      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        if (!mounted) return;

        setState(() {
          progressMessage =
              'VirusTotal analysis in progress... (${attempt + 1}/$maxAttempts)';
        });

        await Future.delayed(const Duration(seconds: 3));

        final uri = Uri.parse(
          '$apiBaseUrl/api/analysis',
        ).replace(queryParameters: {'id': analysisId});

        final response = await http
            .get(uri)
            .timeout(const Duration(seconds: 30));

        analysis = await decodeResponse(response);

        final status = analysis['status']?.toString().toLowerCase() ?? '';

        if (status == 'completed') {
          break;
        }

        if (status == 'queued' || status == 'in-progress') {
          continue;
        }

        if (status == 'failed') {
          throw Exception('VirusTotal could not complete this analysis.');
        }
      }

      if (analysis == null ||
          analysis['status']?.toString().toLowerCase() != 'completed') {
        throw Exception(
          'The analysis is taking longer than expected. Please try again later.',
        );
      }

      final rawStats = analysis['stats'];
      final rawResults = analysis['results'];

      final stats = rawStats is Map
          ? Map<String, dynamic>.from(rawStats)
          : <String, dynamic>{};

      final results = rawResults is Map
          ? Map<String, dynamic>.from(rawResults)
          : <String, dynamic>{};

      final result = ScanResult(
        name: name,
        type: type,
        status: analysis['status']?.toString() ?? 'completed',
        stats: stats,
        results: results,
        date: DateTime.now(),
      );

      if (!mounted) return;

      setState(() {
        latestResult = result;
        history.insert(
          0,
          ScanRecord(
            name: name,
            type: type,
            status: result.detections > 0 ? 'DETECTED' : 'CLEAN',
            malicious: result.malicious,
            suspicious: result.suspicious,
            harmless: result.harmless,
            date: DateTime.now(),
          ),
        );
        selectedTab = 0;
      });

      showMessage('Analysis completed successfully.');
    } catch (error) {
      showMessage(cleanError(error));
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          progressMessage = '';
        });
      }
    }
  }

  String cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('ClientException: ', '');
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF18263A),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF080D18),
        title: const Row(
          children: [
            Icon(Icons.shield_moon, color: cyan, size: 27),
            SizedBox(width: 9),
            Text(
              'CYBERSCAN X',
              style: TextStyle(
                color: cyan,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'ONLINE',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: selectedTab,
          children: [
            dashboard(),
            urlScanner(),
            fileScanner(),
            historyPage(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (index) {
          setState(() => selectedTab = index);
        },
        backgroundColor: const Color(0xFF101827),
        indicatorColor: cyan.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: cyan),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.language),
            selectedIcon: Icon(Icons.language, color: cyan),
            label: 'URL',
          ),
          NavigationDestination(
            icon: Icon(Icons.insert_drive_file_outlined),
            selectedIcon: Icon(Icons.insert_drive_file, color: purple),
            label: 'Files',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history, color: cyan),
            label: 'History',
          ),
        ],
      ),
    );
  }

  Widget dashboard() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const SizedBox(height: 10),
        const Text(
          'SECURITY CENTER',
          style: TextStyle(
            color: Colors.white,
            fontSize: 27,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Advanced threat analysis powered by VirusTotal.',
          style: TextStyle(color: Colors.white60),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFF12334A), Color(0xFF241B45)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: cyan.withValues(alpha: 0.4)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.security, color: cyan, size: 42),
              SizedBox(height: 14),
              Text(
                'YOUR DIGITAL\\nSAFETY STARTS HERE',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.3,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Scan suspicious links and files with multiple security engines.',
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: scannerCard(
                icon: Icons.language,
                title: 'URL SCANNER',
                subtitle: 'Check website links',
                color: cyan,
                onTap: () => setState(() => selectedTab = 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: scannerCard(
                icon: Icons.file_present,
                title: 'FILE SCANNER',
                subtitle: 'Files up to 4 MB',
                color: purple,
                onTap: () => setState(() => selectedTab = 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        sectionTitle('LATEST SCAN'),
        const SizedBox(height: 10),
        if (latestResult == null)
          emptyCard('No scans yet. Choose a scanner to begin.')
        else
          resultCard(latestResult!),
        const SizedBox(height: 22),
        sectionTitle('SECURITY ENGINE'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: panelDecoration(),
          child: const Row(
            children: [
              Icon(Icons.cloud_done, color: Colors.greenAccent, size: 30),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vercel Backend',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Connected service endpoint',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                'READY',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Note: VirusTotal results are security signals, not a guarantee that a file or website is safe.',
          style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.5),
        ),
      ],
    );
  }

  Widget urlScanner() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        sectionTitle('URL SCANNER'),
        const SizedBox(height: 8),
        const Text(
          'Analyze a public website address using VirusTotal.',
          style: TextStyle(color: Colors.white60),
        ),
        const SizedBox(height: 22),
        const Icon(Icons.travel_explore, color: cyan, size: 66),
        const SizedBox(height: 18),
        TextField(
          controller: urlController,
          enabled: !busy,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'https://example.com',
            prefixIcon: Icon(Icons.link, color: cyan),
          ),
        ),
        const SizedBox(height: 14),
        actionButton(
          label: 'ANALYZE URL',
          icon: Icons.radar,
          color: cyan,
          onPressed: busy ? null : scanUrl,
        ),
        const SizedBox(height: 18),
        if (busy) progressCard(),
        if (latestResult != null && latestResult!.type == 'URL')
          resultCard(latestResult!),
        const SizedBox(height: 20),
        const Text(
          'Only submit public URLs. Avoid private, confidential, or sensitive links.',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }

  Widget fileScanner() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        sectionTitle('FILE SCANNER'),
        const SizedBox(height: 8),
        const Text(
          'Choose a file to submit for VirusTotal analysis.',
          style: TextStyle(color: Colors.white60),
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: purple.withValues(alpha: 0.55),
              width: 1.3,
            ),
          ),
          child: const Column(
            children: [
              Icon(Icons.cloud_upload_outlined, color: purple, size: 76),
              SizedBox(height: 18),
              Text(
                'SELECT FILE TO SCAN',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Maximum upload size: 4 MB',
                style: TextStyle(color: Colors.white54),
              ),
              SizedBox(height: 6),
              Text(
                'One file per scan',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        actionButton(
          label: 'CHOOSE FILE',
          icon: Icons.folder_open,
          color: purple,
          onPressed: busy ? null : pickAndScanFile,
        ),
        const SizedBox(height: 18),
        if (busy) progressCard(),
        if (latestResult != null && latestResult!.type == 'FILE')
          resultCard(latestResult!),
        const SizedBox(height: 20),
        const Text(
          'Do not upload private or confidential files. Submitted samples may be shared under VirusTotal policies.',
          style: TextStyle(color: Colors.orangeAccent, fontSize: 12, height: 1.5),
        ),
      ],
    );
  }

  Widget historyPage() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        sectionTitle('SCAN HISTORY'),
        const SizedBox(height: 8),
        Text(
          '${history.length} scan(s) in this session',
          style: const TextStyle(color: Colors.white54),
        ),
        const SizedBox(height: 16),
        if (history.isEmpty)
          emptyCard('Your completed scans will appear here.')
        else
          ...history.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(15),
              decoration: panelDecoration(),
              child: Row(
                children: [
                  Icon(
                    item.type == 'URL' ? Icons.language : Icons.insert_drive_file,
                    color: item.type == 'URL' ? cyan : purple,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${item.type} • ${item.date.toLocal()}',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Malicious: ${item.malicious}  |  Suspicious: ${item.suspicious}  |  Harmless: ${item.harmless}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    item.status == 'CLEAN' ? Icons.check_circle : Icons.warning,
                    color: item.status == 'CLEAN'
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget resultCard(ScanResult result) {
    final dangerous = result.malicious > 0 || result.suspicious > 0;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: dangerous
              ? Colors.redAccent.withValues(alpha: 0.7)
              : cyan.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                dangerous ? Icons.warning_amber : Icons.verified_user,
                color: dangerous ? Colors.redAccent : Colors.greenAccent,
                size: 27,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  dangerous ? 'THREATS DETECTED' : 'NO DETECTIONS REPORTED',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: dangerous ? Colors.redAccent : Colors.greenAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            result.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 17),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.5,
            crossAxisSpacing: 9,
            mainAxisSpacing: 9,
            children: [
              statTile('Malicious', result.malicious, Colors.redAccent),
              statTile('Suspicious', result.suspicious, Colors.orangeAccent),
              statTile('Harmless', result.harmless, Colors.greenAccent),
              statTile('Undetected', result.undetected, cyan),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Analysis status: ${result.status}',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 8),
          const Text(
            'A clean result does not guarantee that an item is completely safe.',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget statTile(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF192538),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget progressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: panelDecoration(),
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: cyan,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              progressMessage,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget scannerCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 34),
            const SizedBox(height: 13),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 53,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.18),
          foregroundColor: color,
          disabledBackgroundColor: Colors.white10,
          disabledForegroundColor: Colors.white38,
          side: BorderSide(color: color.withValues(alpha: 0.65)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget emptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: panelDecoration(),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54),
        ),
      ),
    );
  }

  BoxDecoration panelDecoration() {
    return BoxDecoration(
      color: const Color(0xFF111827),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF26364D)),
    );
  }
}
