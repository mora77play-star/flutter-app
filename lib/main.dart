
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  runApp(const SanterApp());
}

const bg = Color(0xFF0B1020);
const panel = Color(0xFF151D32);
const blue = Color(0xFF6385FF);
const purple = Color(0xFF9B7BFF);
const green = Color(0xFF35D6A0);
const red = Color(0xFFFF6685);

class Store {
  static late SharedPreferences prefs;

  static final Map<String, List<Map<String, dynamic>>> data = {
    'students': [],
    'teachers': [],
    'attendance': [],
    'recitations': [],
    'payments': [],
  };

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();

    for (final key in data.keys.toList()) {
      try {
        final raw = prefs.getString(key) ?? '[]';
        final decoded = jsonDecode(raw);

        if (decoded is List) {
          data[key] = decoded
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        } else if (key == 'attendance' && decoded is Map) {
          data[key] = decoded.values
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      } catch (_) {
        data[key] = [];
      }
    }
  }

  static Future<void> save(String key) async {
    await prefs.setString(key, jsonEncode(data[key]));
  }

  static String get password =>
      prefs.getString('admin_password') ?? '123456';

  static Future<void> setPassword(String value) async {
    await prefs.setString('admin_password', value);
  }

  static double sum(String key, String field) {
    return data[key]!.fold<double>(
      0,
      (total, item) =>
          total + ((item[field] as num?)?.toDouble() ?? 0),
    );
  }
}

class SanterApp extends StatelessWidget {
  const SanterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SANTER PRO | 𝗠𝗢𝗥𝗔',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: blue,
          brightness: Brightness.dark,
        ),
        cardColor: panel,
        appBarTheme: const AppBarTheme(
          backgroundColor: panel,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: bg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final controller = TextEditingController();
  String error = '';

  void login() {
    if (controller.text != Store.password) {
      setState(() => error = 'كلمة المرور غير صحيحة');
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.school_rounded,
                    size: 75, color: blue),
                const SizedBox(height: 18),
                const Text(
                  'SANTER PRO',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('نظام إدارة السنتر التعليمي'),
                const SizedBox(height: 10),
                const Text(
                  '𝗠𝗢𝗥𝗔',
                  style: TextStyle(
                    color: blue,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: controller,
                  obscureText: true,
                  onSubmitted: (_) => login(),
                  decoration: const InputDecoration(
                    labelText: 'كلمة مرور الإدارة',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                if (error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      error,
                      style: const TextStyle(color: red),
                    ),
                  ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: login,
                    child: const Text('تسجيل الدخول'),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'كلمة المرور الأولية: 123456',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int page = 0;

  final titles = const [
    'الرئيسية',
    'الطلاب',
    'المدرسون',
    'الحضور والغياب',
    'التسميع',
    'المصروفات',
    'الإعدادات',
  ];

  final keys = const [
    '',
    'students',
    'teachers',
    'attendance',
    'recitations',
    'payments',
    '',
  ];

  final icons = const [
    Icons.dashboard_rounded,
    Icons.people_alt_rounded,
    Icons.cast_for_education_rounded,
    Icons.fact_check_rounded,
    Icons.menu_book_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.settings_rounded,
  ];

  void message(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  Future<String?> ask(
    String title, {
    String initial = '',
    bool numeric = false,
  }) async {
    final c = TextEditingController(text: initial);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: panel,
          title: Text(title),
          content: TextField(
            controller: c,
            autofocus: true,
            keyboardType: numeric
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            decoration: const InputDecoration(
              hintText: 'اكتب هنا',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    c.dispose();
    return result;
  }

  Future<void> addRecord() async {
    if (page < 1 || page > 5) return;

    final key = keys[page];
    final name = await ask(
      page == 2 ? 'اسم المدرس' : 'اسم الطالب',
    );

    if (!mounted || name == null || name.isEmpty) return;

    final item = <String, dynamic>{
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'name': name,
      'date': DateTime.now().toIso8601String(),
    };

    if (page == 1) {
      final grade = await ask('الصف الدراسي');
      if (!mounted || grade == null) return;

      final phone = await ask('رقم ولي الأمر');
      if (!mounted || phone == null) return;

      final amountText = await ask(
        'المصروفات المطلوبة بالجنيه',
        numeric: true,
      );
      if (!mounted || amountText == null) return;

      final amount = double.tryParse(amountText);
      if (amount == null || amount < 0) {
        message('اكتب مبلغًا صحيحًا');
        return;
      }

      item.addAll({
        'grade': grade,
        'phone': phone,
        'fees': amount,
      });
    } else if (page == 2) {
      final subject = await ask('المادة الدراسية');
      if (!mounted || subject == null) return;

      final phone = await ask('رقم الهاتف');
      if (!mounted || phone == null) return;

      item.addAll({
        'subject': subject,
        'phone': phone,
      });
    } else if (page == 3) {
      final status = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: panel,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final value in ['حاضر', 'غائب', 'متأخر'])
                ListTile(
                  title: Text(value),
                  onTap: () => Navigator.pop(ctx, value),
                ),
            ],
          ),
        ),
      );

      if (!mounted || status == null) return;
      item['status'] = status;
    } else if (page == 4) {
      final details = await ask('درجة التسميع والملاحظات');
      if (!mounted || details == null) return;
      item['details'] = details;
    } else if (page == 5) {
      final amountText = await ask(
        'المبلغ المدفوع بالجنيه',
        numeric: true,
      );
      if (!mounted || amountText == null) return;

      final amount = double.tryParse(amountText);
      if (amount == null || amount <= 0) {
        message('اكتب مبلغًا صحيحًا');
        return;
      }

      item['amount'] = amount;
    }

    Store.data[key]!.add(item);
    await Store.save(key);

    if (!mounted) return;
    setState(() {});
    message('تم الحفظ على الجهاز');
  }

  Future<void> deleteRecord(int index) async {
    final key = keys[page];
    final list = Store.data[key]!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: panel,
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تريد حذف هذا السجل؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    list.removeAt(index);
    await Store.save(key);

    if (!mounted) return;
    setState(() {});
    message('تم حذف السجل');
  }

  Future<void> changePassword() async {
    final oldPass = await ask('كلمة المرور الحالية');
    if (!mounted || oldPass == null) return;

    if (oldPass != Store.password) {
      message('كلمة المرور الحالية غير صحيحة');
      return;
    }

    final newPass = await ask('كلمة المرور الجديدة');
    if (!mounted || newPass == null) return;

    if (newPass.length < 6) {
      message('كلمة المرور يجب ألا تقل عن 6 أحرف');
      return;
    }

    await Store.setPassword(newPass);
    if (mounted) message('تم تغيير كلمة المرور');
  }

  Widget stat(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }

  Widget dashboard() {
    final students = Store.data['students']!;
    final teachers = Store.data['teachers']!;
    final fees = Store.sum('students', 'fees');
    final paid = Store.sum('payments', 'amount');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'أهلاً بيك في الإدارة 👋',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'كل تفاصيل السنتر في مكان واحد',
          style: TextStyle(color: Colors.white60),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: GridView.count(
            crossAxisCount: 2,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.25,
            children: [
              stat('الطلاب', '${students.length}',
                  Icons.people, blue),
              stat('المدرسون', '${teachers.length}',
                  Icons.school, purple),
              stat('المطلوب', '${fees.toStringAsFixed(0)} ج.م',
                  Icons.account_balance_wallet, green),
              stat('المحصل', '${paid.toStringAsFixed(0)} ج.م',
                  Icons.payments, Colors.orange),
            ],
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ملخص الحسابات',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text('المطلوب: ${fees.toStringAsFixed(2)} جنيه'),
                Text('المحصل: ${paid.toStringAsFixed(2)} جنيه'),
                Text(
                  'المتبقي: ${(fees - paid).clamp(0, double.infinity).toStringAsFixed(2)} جنيه',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (int i = 1; i < titles.length; i++)
          Card(
            child: ListTile(
              leading: Icon(icons[i], color: blue),
              title: Text(titles[i]),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => setState(() => page = i),
            ),
          ),
      ],
    );
  }

  Widget recordsPage() {
    final list = Store.data[keys[page]]!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  titles[page],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: addRecord,
                icon: const Icon(Icons.add),
                label: const Text('إضافة'),
              ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد بيانات حتى الآن',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];

                    String subtitle;
                    switch (page) {
                      case 1:
                        subtitle =
                            '${item['grade'] ?? ''} • ${item['phone'] ?? ''} • ${item['fees'] ?? 0} ج.م';
                        break;
                      case 2:
                        subtitle =
                            '${item['subject'] ?? ''} • ${item['phone'] ?? ''}';
                        break;
                      case 3:
                        subtitle =
                            '${item['status'] ?? ''} • ${item['date'] ?? ''}';
                        break;
                      case 4:
                        subtitle = '${item['details'] ?? ''}';
                        break;
                      case 5:
                        subtitle = '${item['amount'] ?? 0} ج.م';
                        break;
                      default:
                        subtitle = '';
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: blue.withAlpha(40),
                          child: Icon(icons[page], color: blue),
                        ),
                        title: Text('${item['name'] ?? ''}'),
                        subtitle: Text(subtitle),
                        trailing: IconButton(
                          onPressed: () => deleteRecord(index),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: red,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'SANTER PRO • 𝗠𝗢𝗥𝗔',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          actions: [
            IconButton(
              tooltip: 'تسجيل الخروج',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginPage(),
                  ),
                );
              },
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: panel,
          child: SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.school, size: 50, color: blue),
                      SizedBox(height: 10),
                      Text(
                        'إدارة السنتر',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '𝗠𝗢𝗥𝗔',
                        style: TextStyle(
                          color: blue,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: titles.length,
                    itemBuilder: (context, index) => ListTile(
                      selected: page == index,
                      leading: Icon(icons[index]),
                      title: Text(titles[index]),
                      onTap: () {
                        setState(() => page = index);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: page == 0
            ? dashboard()
            : page == 6
                ? Center(
                    child: FilledButton.icon(
                      onPressed: changePassword,
                      icon: const Icon(Icons.lock_reset),
                      label: const Text('تغيير كلمة المرور'),
                    ),
                  )
                : recordsPage(),
      ),
    );
  }
}