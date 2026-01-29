import 'package:flutter/material.dart';

void main() {
  runApp(const InsuranceApp());
}

/* ================= MODELS ================= */

enum ClaimStatus { draft, submitted, approved, rejected, partiallySettled }

class Bill {
  final String description;
  final double amount;
  Bill(this.description, this.amount);
}

class Claim {
  final String patientName;
  List<Bill> bills = [];
  double advance = 0;
  double settlement = 0;
  ClaimStatus status = ClaimStatus.draft;

  Claim(this.patientName);

  double get totalBills =>
      bills.fold(0, (sum, b) => sum + b.amount);

  double get pending => totalBills - advance - settlement;
}

/* ================= APP ROOT ================= */

class InsuranceApp extends StatelessWidget {
  const InsuranceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Insurance Claims',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF4F6FB),
      ),
      home: const DashboardPage(),
    );
  }
}

/* ================= DASHBOARD ================= */

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final List<Claim> claims = [];

  Color statusColor(ClaimStatus s) {
    switch (s) {
      case ClaimStatus.approved:
        return Colors.green;
      case ClaimStatus.rejected:
        return Colors.red;
      case ClaimStatus.partiallySettled:
        return Colors.orange;
      case ClaimStatus.submitted:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void addClaim() async {
    final Claim? c = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateClaimPage()),
    );
    if (c != null) setState(() => claims.add(c));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insurance Claims Dashboard')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addClaim,
        icon: const Icon(Icons.add),
        label: const Text('New Claim'),
      ),
      body: claims.isEmpty
          ? const Center(child: Text('No claims yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: claims.length,
              itemBuilder: (_, i) {
                final c = claims[i];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          statusColor(c.status).withOpacity(0.15),
                      child: const Icon(Icons.person),
                    ),
                    title: Text(
                      c.patientName,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Total: ₹${c.totalBills.toStringAsFixed(2)}\nPending: ₹${c.pending.toStringAsFixed(2)}',
                    ),
                    trailing: Chip(
                      label: Text(c.status.name.toUpperCase()),
                      backgroundColor:
                          statusColor(c.status).withOpacity(0.2),
                      labelStyle:
                          TextStyle(color: statusColor(c.status)),
                    ),
                    isThreeLine: true,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClaimDetailPage(claim: c),
                        ),
                      );
                      setState(() {});
                    },
                  ),
                );
              },
            ),
    );
  }
}

/* ================= CREATE CLAIM ================= */

class CreateClaimPage extends StatefulWidget {
  const CreateClaimPage({super.key});

  @override
  State<CreateClaimPage> createState() => _CreateClaimPageState();
}

class _CreateClaimPageState extends State<CreateClaimPage> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Claim')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Patient Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(
                    context,
                    Claim(controller.text.trim()),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

/* ================= CLAIM DETAILS ================= */

class ClaimDetailPage extends StatefulWidget {
  final Claim claim;
  const ClaimDetailPage({super.key, required this.claim});

  @override
  State<ClaimDetailPage> createState() => _ClaimDetailPageState();
}

class _ClaimDetailPageState extends State<ClaimDetailPage> {
  final billDesc = TextEditingController();
  final billAmt = TextEditingController();
  final advCtrl = TextEditingController();
  final setCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final c = widget.claim;

    Color pendingColor() {
      if (c.pending < 0) return Colors.red;
      if (c.pending == 0) return Colors.green;
      return Colors.orange;
    }

    return Scaffold(
      appBar: AppBar(title: Text('Claim – ${c.patientName}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          summaryCard(c, pendingColor()),
          sectionCard(
            'Bills',
            Icons.receipt_long,
            Column(
              children: [
                if (c.bills.isEmpty)
                  const Text('No bills added yet'),
                for (var b in c.bills)
                  ListTile(
                    title: Text(b.description),
                    trailing: Text(
                        '₹${b.amount.toStringAsFixed(2)}'),
                  ),
                const Divider(),
                TextField(
                  controller: billDesc,
                  decoration: const InputDecoration(
                      labelText: 'Bill Description'),
                ),
                TextField(
                  controller: billAmt,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                          decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Amount'),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Bill'),
                  onPressed: () {
                    final desc = billDesc.text.trim();
                    final rawAmount =
                        billAmt.text.trim().replaceAll(',', '');

                    if (desc.isEmpty || rawAmount.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Please enter bill description and amount'),
                        ),
                      );
                      return;
                    }

                    final amt = double.tryParse(rawAmount);

                    if (amt == null || amt <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Enter a valid bill amount')),
                      );
                      return;
                    }

                    setState(() {
                      c.bills.add(Bill(desc, amt));
                    });

                    billDesc.clear();
                    billAmt.clear();
                  },
                ),
              ],
            ),
          ),
          sectionCard(
            'Financials',
            Icons.account_balance_wallet,
            Column(
              children: [
                TextField(
                  controller: advCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                          decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Advance'),
                ),
                TextField(
                  controller: setCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                          decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Settlement'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      c.advance =
                          double.tryParse(advCtrl.text) ??
                              c.advance;
                      c.settlement =
                          double.tryParse(setCtrl.text) ??
                              c.settlement;
                    });
                  },
                  child: const Text('Update Amounts'),
                ),
              ],
            ),
          ),
          sectionCard(
            'Claim Status',
            Icons.sync_alt,
            DropdownButton<ClaimStatus>(
              value: c.status,
              items: ClaimStatus.values
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.name.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => c.status = v!),
            ),
          ),
        ],
      ),
    );
  }

  Widget summaryCard(Claim c, Color pendingColor) {
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Summary',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            row('Total Bills', c.totalBills),
            row('Advance', c.advance),
            row('Settlement', c.settlement),
            const Divider(),
            row('Pending', c.pending,
                bold: true, color: pendingColor),
          ],
        ),
      ),
    );
  }

  Widget sectionCard(String title, IconData icon, Widget child) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget row(String label, double value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight:
                  bold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
