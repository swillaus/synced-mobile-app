import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:synced/main.dart';
import 'package:synced/screens/expenses/create_expense.dart';
import 'package:synced/screens/home/expenses_tab_screen.dart';
import 'package:synced/screens/home/transactions_tab_screen.dart';
import 'package:synced/utils/api_services.dart';
import 'package:synced/utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final PersistentTabController _controller = PersistentTabController();
  List organisations = [];
  bool showSpinner = false;
  List reviewExpenses = [];
  List processedExpenses = [];
  late TabController tabController;

  List<DropdownMenuItem> getDropdownEntries() {
    List<DropdownMenuItem> entries = [];
    for (var org in organisations) {
      entries.add(DropdownMenuItem(
          value: org['organisationID'], child: Text(org['organisationName'])));
    }
    return entries;
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    ScrollController scrollController1 = ScrollController();
    ScrollController scrollController2 = ScrollController();
    ScrollController scrollController3 = ScrollController();

    return [
      PersistentBottomNavBarItem(
        icon: Image.asset(
            _controller.index == 0
                ? 'assets/nav_bar/expenses-yellow.png'
                : 'assets/nav_bar/expenses-grey.png',
            height: 60,
            width: 60),
        scrollController: scrollController1,
        routeAndNavigatorSettings: RouteAndNavigatorSettings(
          initialRoute: "/expenses",
          routes: {
            "/expenses": (final context) => getExpensesWidget(
                context,
                reviewExpenses,
                processedExpenses,
                showSpinner,
                setState,
                tabController),
            "/create-expense": (final context) => const CreateExpense(),
            "/transactions": (final context) => const TransactionsTabScreen(),
          },
        ),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.add, color: Colors.white, size: 35),
        activeColorPrimary: clickableColor,
        inactiveColorPrimary: textColor,
        scrollController: scrollController2,
        routeAndNavigatorSettings: RouteAndNavigatorSettings(
          initialRoute: "/expenses",
          routes: {
            "/expenses": (final context) => getExpensesWidget(
                context,
                reviewExpenses,
                processedExpenses,
                showSpinner,
                setState,
                tabController),
            "/create-expense": (final context) => const CreateExpense(),
            "/transactions": (final context) => const TransactionsTabScreen(),
          },
        ),
      ),
      PersistentBottomNavBarItem(
        icon: Image.asset(
            _controller.index == 2
                ? 'assets/nav_bar/transactions-yellow.png'
                : 'assets/nav_bar/transactions-grey.png',
            height: 75,
            width: 75),
        scrollController: scrollController3,
        routeAndNavigatorSettings: RouteAndNavigatorSettings(
          initialRoute: "/expenses",
          routes: {
            "/expenses": (final context) => getExpensesWidget(
                context,
                reviewExpenses,
                processedExpenses,
                showSpinner,
                setState,
                tabController),
            "/create-expense": (final context) => const CreateExpense(),
            "/transactions": (final context) => const TransactionsTabScreen(),
          },
        ),
      ),
    ];
  }

  getUnprocessedExpenses() async {
    final resp = await ApiService.getExpenses(false, selectedOrgId, '');
    if (resp.isNotEmpty) {
      reviewExpenses = resp['invoices'];
    }

    setState(() {
      showSpinner = false;
    });

    for (var exp in reviewExpenses) {
      final invoiceResp =
          await ApiService.downloadInvoice(exp['invoicePdfUrl'], selectedOrgId);
      setState(() {
        exp['invoice_path'] = invoiceResp['path'];
      });
      if (kDebugMode) {
        print(invoiceResp);
      }
    }
  }

  getProcessedExpenses() async {
    final resp = await ApiService.getExpenses(true, selectedOrgId, '');
    if (resp.isNotEmpty) {
      processedExpenses = resp['invoices'];
    }

    for (var exp in processedExpenses) {
      final invoiceResp =
          await ApiService.downloadInvoice(exp['invoicePdfUrl'], selectedOrgId);
      setState(() {
        exp['invoice_path'] = invoiceResp['path'];
      });
      if (kDebugMode) {
        print(invoiceResp);
      }
    }
  }

  @override
  void initState() {
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(() {
      setState(() {});
    });
    super.initState();
    getOrganisations();
  }

  getOrganisations() async {
    setState(() {
      showSpinner = true;
    });

    final resp = await ApiService.getOrganisations();
    if (!resp['failed']) {
      organisations = resp['data'];
      if (selectedOrgId.isEmpty) {
        selectedOrgId = organisations[0]['organisationID'];
      }
    }
    getUnprocessedExpenses();
    getProcessedExpenses();
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
        inAsyncCall: showSpinner,
        progressIndicator: CircularProgressIndicator(
          color: clickableColor,
        ),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: const Color(0xfffbfbfb),
          appBar: AppBar(
            backgroundColor: Colors.white,
            centerTitle: true,
            title: DropdownButtonHideUnderline(
                child: DropdownButton2(
                    onChanged: (value) {
                      setState(() {
                        selectedOrgId = value!;
                      });
                    },
                    items: getDropdownEntries(),
                    value: selectedOrgId)),
            bottom: TabBar(
                indicatorColor: clickableColor,
                labelColor: clickableColor,
                unselectedLabelColor: textColor,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(
                    text: 'For Review',
                  ),
                  Tab(
                    text: 'Processed',
                  ),
                ],
                controller: tabController),
          ),
          body: PersistentTabView(
            context,
            controller: _controller,
            screens: [
              getExpensesWidget(context, reviewExpenses, processedExpenses,
                  showSpinner, setState, tabController),
              const CreateExpense(),
              const TransactionsTabScreen()
            ],
            items: _navBarsItems(),
            handleAndroidBackButtonPress: false,
            resizeToAvoidBottomInset: true,
            stateManagement: true,
            hideNavigationBarWhenKeyboardAppears: true,
            popBehaviorOnSelectedNavBarItemPress: PopBehavior.all,
            padding: const EdgeInsets.all(5),
            backgroundColor: Colors.white,
            isVisible: true,
            animationSettings: const NavBarAnimationSettings(
              navBarItemAnimation: ItemAnimationSettings(
                // Navigation Bar's items animation properties.
                duration: Duration(milliseconds: 400),
                curve: Curves.ease,
              ),
              screenTransitionAnimation: ScreenTransitionAnimationSettings(
                // Screen transition animation on change of selected tab.
                animateTabTransition: true,
                duration: Duration(milliseconds: 200),
                screenTransitionAnimationType:
                    ScreenTransitionAnimationType.fadeIn,
              ),
            ),
            confineToSafeArea: true,
            navBarHeight: MediaQuery.of(context).size.height * 0.1,
            navBarStyle: NavBarStyle.style15,
            onItemSelected: (index) {
              setState(() {});
            },
          ),
        ));
  }
}
