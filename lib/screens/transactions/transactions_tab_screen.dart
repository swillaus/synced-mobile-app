import 'package:flutter/material.dart';

Widget getTransactionsWidget(context, setState, tabController, mounted) {
  Widget noTransactionWidget = Container(
    padding: const EdgeInsets.all(20),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/no-transactions.png',
            height: MediaQuery.of(context).size.height * 0.25),
        const SizedBox(height: 30),
        const Text('No Transaction yet!',
            style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        const Text('Currently there are no transactions assigned to \nyou.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Color(0XFF667085),
                fontSize: 14,
                fontWeight: FontWeight.w400)),
      ],
    ),
  );

  Widget getPageContent() {
    return noTransactionWidget;
  }

  return getPageContent();
}
