import 'package:flutter/material.dart';
// or use Icons.money, Icons.credit_card

void showPaymentOptions(BuildContext context, void Function(String method) onSelected) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Choose Payment Method",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),

          // 🟢 Cash Option
          PaymentOptionTile(
            icon: Icons.money,
            title: "Cash on Service",
            subtitle: "Pay directly to the service provider",
            onTap: () {
              Navigator.pop(context);
              onSelected("cash");
            },
          ),
          const SizedBox(height: 12),

          // 🔵 Online Option
          PaymentOptionTile(
            icon: Icons.credit_card,
            title: "Pay Online",
            subtitle: "Use Razorpay, UPI, Card or Wallet",
            onTap: () {
              Navigator.pop(context);
              onSelected("online");
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

Future<bool?> showCashConfirmationDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Confirm Payment Method"),
        content: const Text(
          "Please pay to the service provider.\n\nOnce confirmed, this action cannot be undone.",
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // User canceled
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // User confirmed
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

class PaymentOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const PaymentOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(icon, color: Colors.black87),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}
