import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/models/feature_documentation.dart';

/// All app features with comprehensive documentation
class DocumentationData {
  static List<FeatureDocumentation> getAllFeatures() {
    return [
      // Transactions
      FeatureDocumentation(
        id: 'transactions',
        title: 'Transactions',
        description:
            'Track all your income and expenses in one place. Add, edit, and categorize transactions to understand your spending patterns.',
        icon: Icons.receipt_long,
        color: AppColors.lightPrimary,
        category: 'Core Features',
        steps: const [
          FeatureStep(
            title: 'Open Transactions',
            description: 'Tap the receipt icon in the bottom navigation bar to view all your transactions.',
            icon: Icons.receipt_long,
          ),
          FeatureStep(
            title: 'Add New Transaction',
            description: 'Tap the + button at the bottom. Select Income or Expense type.',
            icon: Icons.add_circle,
          ),
          FeatureStep(
            title: 'Fill Transaction Details',
            description: 'Enter amount, select category, account, date, and add optional notes or attachments.',
            icon: Icons.edit,
          ),
          FeatureStep(
            title: 'Save Transaction',
            description: 'Tap Save to record your transaction. It will appear in your transaction list.',
            icon: Icons.save,
          ),
        ],
        examples: const [
          FeatureExample(
            title: 'Grocery Shopping',
            description: 'Record your weekly grocery expense of ₹2,500 under Food & Dining category.',
            scenario: 'You just came back from the supermarket. Open the app, add an expense transaction, enter ₹2,500, select Food & Dining category, choose your payment account (e.g., Credit Card), and save.',
          ),
          FeatureExample(
            title: 'Salary Credit',
            description: 'Record your monthly salary of ₹50,000 as income under Salary category.',
            scenario: 'Your salary got credited to your bank account. Add an income transaction, enter ₹50,000, select Salary category, choose your bank account, and save.',
          ),
        ],
        tips: const [
          'Add transactions immediately to avoid forgetting',
          'Use categories consistently for better insights',
          'Attach receipts for important purchases',
          'Review your transactions weekly to stay on track',
        ],
      ),

      // Budgets
      FeatureDocumentation(
        id: 'budgets',
        title: 'Budgets',
        description:
            'Set spending limits for different categories to control your expenses. Track progress and get alerts when approaching limits.',
        icon: Icons.pie_chart,
        color: Colors.orange,
        category: 'Core Features',
        steps: const [
          FeatureStep(
            title: 'Access Budgets',
            description: 'From home screen, scroll to the Budgets section and tap "View All Budgets".',
            icon: Icons.pie_chart,
          ),
          FeatureStep(
            title: 'Create Budget',
            description: 'Tap the + button. Select a category you want to budget for.',
            icon: Icons.add,
          ),
          FeatureStep(
            title: 'Set Limit & Period',
            description: 'Enter your budget amount and choose the period (monthly, weekly, etc.).',
            icon: Icons.tune,
          ),
          FeatureStep(
            title: 'Monitor Progress',
            description: 'View your spending progress with visual indicators. Get notified when nearing limits.',
            icon: Icons.trending_up,
          ),
        ],
        examples: const [
          FeatureExample(
            title: 'Monthly Food Budget',
            description: 'Set a ₹10,000/month budget for Food & Dining to control restaurant expenses.',
            scenario: 'You want to limit dining out expenses. Create a budget for Food & Dining category with ₹10,000 monthly limit. The app will track your spending and alert you when you reach 80% of your budget.',
          ),
          FeatureExample(
            title: 'Entertainment Budget',
            description: 'Allocate ₹5,000/month for Entertainment to manage movie tickets and subscriptions.',
            scenario: 'You spend a lot on movies and streaming services. Set a ₹5,000 monthly budget for Entertainment. Track expenses like Netflix subscription, movie tickets against this limit.',
          ),
        ],
        tips: const [
          'Start with realistic budgets based on past spending',
          'Review and adjust budgets monthly',
          'Focus on 3-5 key categories first',
          'Check budget status before making purchases',
        ],
      ),

      // Recurring Transactions
      FeatureDocumentation(
        id: 'recurring',
        title: 'Recurring Transactions',
        description:
            'Automate tracking of regular income and expenses like salary, rent, subscriptions. Set it once and let the app handle the rest.',
        icon: Icons.loop,
        color: Colors.blue,
        category: 'Core Features',
        steps: const [
          FeatureStep(
            title: 'Access Recurring',
            description: 'From home screen, tap "Recurring Transactions" or access from side menu.',
            icon: Icons.loop,
          ),
          FeatureStep(
            title: 'Add Recurring Item',
            description: 'Tap +, select Income or Expense, and fill in transaction details.',
            icon: Icons.add,
          ),
          FeatureStep(
            title: 'Set Recurrence',
            description: 'Choose frequency (daily, weekly, monthly, yearly) and set start/end dates.',
            icon: Icons.calendar_today,
          ),
          FeatureStep(
            title: 'Auto-Creation',
            description: 'Transactions will be created automatically on scheduled dates.',
            icon: Icons.auto_awesome,
          ),
        ],
        examples: const [
          FeatureExample(
            title: 'Monthly Rent',
            description: 'Set up a recurring expense of ₹15,000 for rent, due on the 1st of every month.',
            scenario: 'Your rent is ₹15,000 due on 1st of each month. Create a recurring expense, set amount, category as Housing, frequency as Monthly, and start date as 1st. The app will automatically create the transaction each month.',
          ),
          FeatureExample(
            title: 'Netflix Subscription',
            description: 'Track your ₹649 monthly Netflix subscription automatically.',
            scenario: 'Netflix charges ₹649 every month on the 15th. Add a recurring expense for ₹649, category as Entertainment, monthly frequency starting on the 15th.',
          ),
        ],
        tips: const [
          'Set up all subscriptions as recurring to never miss tracking them',
          'Review recurring transactions quarterly',
          'Cancel unused subscriptions you discover',
          'Use end dates for limited-period commitments',
        ],
      ),

      // EMI Management
      FeatureDocumentation(
        id: 'emi',
        title: 'EMI Management',
        description:
            'Track all your loans and EMIs in one place. Monitor outstanding amounts, interest rates, and payment schedules.',
        icon: Icons.payments,
        color: Colors.red,
        category: 'Core Features',
        steps: const [
          FeatureStep(
            title: 'Access EMI Section',
            description: 'From home screen tap "EMIs" or go to Settings > Manage EMIs.',
            icon: Icons.payments,
          ),
          FeatureStep(
            title: 'Add New EMI',
            description: 'Tap +, enter loan details: principal amount, interest rate, tenure, and EMI amount.',
            icon: Icons.add,
          ),
          FeatureStep(
            title: 'Set Payment Schedule',
            description: 'Choose start date and payment frequency (usually monthly).',
            icon: Icons.schedule,
          ),
          FeatureStep(
            title: 'Track Payments',
            description: 'View remaining EMIs, total paid, and outstanding balance at a glance.',
            icon: Icons.trending_down,
          ),
        ],
        examples: const [
          FeatureExample(
            title: 'Car Loan',
            description: 'Track a 5-year car loan of ₹5,00,000 at 8.5% interest with EMI of ₹10,270.',
            scenario: 'You took a car loan of ₹5 lakhs at 8.5% for 5 years. Add EMI with principal ₹5,00,000, rate 8.5%, tenure 60 months, EMI ₹10,270, starting from your first payment date.',
          ),
          FeatureExample(
            title: 'Home Loan',
            description: 'Manage a 20-year home loan of ₹30,00,000 at 7% interest.',
            scenario: 'For your ₹30 lakh home loan at 7% for 20 years, add EMI details. The app will show you total interest payable, principal remaining, and payment schedule.',
          ),
        ],
        tips: const [
          'Update EMI status after each payment',
          'Check total interest payable to understand true loan cost',
          'Consider prepayment options when you have surplus',
          'Set reminders for EMI due dates',
        ],
      ),

      // Scheduled Payments
      FeatureDocumentation(
        id: 'scheduled',
        title: 'Scheduled Payments',
        description:
            'Track one-time future payments like credit card bills, utility bills, or any upcoming payment obligations.',
        icon: Icons.event_note,
        color: Colors.purple,
        category: 'Core Features',
        steps: const [
          FeatureStep(
            title: 'Create Scheduled Payment',
            description: 'Go to Settings > Scheduled Payments and tap + to add a new payment.',
            icon: Icons.add_circle_outline,
          ),
          FeatureStep(
            title: 'Enter Payment Details',
            description: 'Add payment title, amount, due date, category, and optionally attach reminder notes.',
            icon: Icons.edit,
          ),
          FeatureStep(
            title: 'Get Reminders',
            description: 'The app will remind you about upcoming payments based on due dates.',
            icon: Icons.notifications,
          ),
          FeatureStep(
            title: 'Mark as Paid',
            description: 'When paid, mark the payment as complete or update status to partial if needed.',
            icon: Icons.check_circle,
          ),
        ],
        examples: const [
          FeatureExample(
            title: 'Credit Card Bill',
            description: 'Schedule your ₹25,000 credit card payment due on 15th of the month.',
            scenario: 'Your credit card bill of ₹25,000 is due on the 15th. Create a scheduled payment for this amount, set due date, and category as Credit Card Payment. Get reminded 3 days before.',
          ),
          FeatureExample(
            title: 'Insurance Premium',
            description: 'Track quarterly insurance premium of ₹8,000 due next month.',
            scenario: 'Your health insurance premium of ₹8,000 is due quarterly. Add a scheduled payment with due date, category as Insurance, so you don\'t miss the payment.',
          ),
        ],
        tips: const [
          'Add payments as soon as you receive bills',
          'Set early reminders to arrange funds',
          'Use notes to add bill reference numbers',
          'Review overdue payments weekly',
        ],
      ),

      // Profiles
      FeatureDocumentation(
        id: 'profiles',
        title: 'Profiles',
        description:
            'Create separate financial profiles for different purposes. Manage personal, business, or family finances independently.',
        icon: Icons.switch_account,
        color: Colors.teal,
        category: 'Organization',
        steps: const [
          FeatureStep(
            title: 'Access Profile Management',
            description: 'Go to Settings > Manage Profiles to see all your profiles.',
            icon: Icons.settings,
          ),
          FeatureStep(
            title: 'Create New Profile',
            description: 'Tap + to create a new profile. Give it a meaningful name and optional description.',
            icon: Icons.person_add,
          ),
          FeatureStep(
            title: 'Switch Between Profiles',
            description: 'Tap on any profile to switch. All data (transactions, budgets, etc.) will change accordingly.',
            icon: Icons.swap_horiz,
          ),
          FeatureStep(
            title: 'Manage Independently',
            description: 'Each profile has its own accounts, categories, transactions, and budgets.',
            icon: Icons.dashboard,
          ),
        ],
        examples: const [
          FeatureExample(
            title: 'Personal & Business',
            description: 'Separate your personal expenses from business expenses with two profiles.',
            scenario: 'You run a freelance business. Create a "Personal" profile for home expenses and a "Business" profile for client payments and business costs. Switch between them as needed.',
          ),
          FeatureExample(
            title: 'Family Budget',
            description: 'Create a joint profile with your spouse to track shared household expenses.',
            scenario: 'Create a "Family" profile to track joint expenses like groceries, utilities, rent. Keep your personal shopping in "Personal" profile.',
          ),
        ],
        tips: const [
          'Start with one profile, add more only when needed',
          'Use clear, descriptive names for profiles',
          'Regularly switch to update all profiles',
          'Consider separate profiles for different financial goals',
        ],
      ),

      // Accounts
      FeatureDocumentation(
        id: 'accounts',
        title: 'Accounts',
        description:
            'Manage all your financial accounts - bank accounts, credit cards, cash, digital wallets. Track balances and transactions per account.',
        icon: Icons.account_balance_wallet,
        color: Colors.green,
        category: 'Organization',
        steps: const [
          FeatureStep(
            title: 'Open Account Management',
            description: 'Go to Settings > Manage Accounts to view all accounts.',
            icon: Icons.account_balance_wallet,
          ),
          FeatureStep(
            title: 'Add New Account',
            description: 'Tap +, select account type (Bank, Cash, Credit Card, etc.), and enter details.',
            icon: Icons.add,
          ),
          FeatureStep(
            title: 'Set Initial Balance',
            description: 'Enter the current balance of the account to start tracking.',
            icon: Icons.currency_rupee,
          ),
          FeatureStep(
            title: 'Use in Transactions',
            description: 'When adding transactions, select which account was used for payment/receipt.',
            icon: Icons.receipt,
          ),
        ],
        examples: const [
          FeatureExample(
            title: 'Multiple Bank Accounts',
            description: 'Add your HDFC savings account, ICICI salary account, and SBI credit card.',
            scenario: 'You have multiple accounts. Add each one: HDFC Savings (₹50,000), ICICI Salary (₹1,20,000), SBI Credit Card (₹-5,000). Track which account you use for each transaction.',
          ),
          FeatureExample(
            title: 'Cash & Digital Wallets',
            description: 'Track cash in hand, Paytm wallet, and PhonePe balance separately.',
            scenario: 'Add Cash (₹5,000), Paytm (₹1,200), PhonePe (₹800) as separate accounts. When you pay via Paytm, select that account in your transaction.',
          ),
        ],
        tips: const [
          'Add all accounts you regularly use',
          'Update balances monthly to match bank statements',
          'Use account colors to distinguish them visually',
          'Archive unused accounts instead of deleting',
        ],
      ),

      // Categories
      FeatureDocumentation(
        id: 'categories',
        title: 'Categories',
        description:
            'Organize transactions into categories for better analysis. Customize categories to match your lifestyle and spending patterns.',
        icon: Icons.category,
        color: Colors.indigo,
        category: 'Organization',
        steps: const [
          FeatureStep(
            title: 'View Categories',
            description: 'Go to Settings > Manage Categories to see all income and expense categories.',
            icon: Icons.list,
          ),
          FeatureStep(
            title: 'Create Custom Category',
            description: 'Tap + to add a new category. Choose name, icon, color, and type (Income/Expense).',
            icon: Icons.add,
          ),
          FeatureStep(
            title: 'Edit or Delete',
            description: 'Tap on any category to edit its details or remove it if no longer needed.',
            icon: Icons.edit,
          ),
          FeatureStep(
            title: 'Use in Transactions',
            description: 'Select appropriate category when recording transactions for better insights.',
            icon: Icons.check,
          ),
        ],
        examples: const [
          FeatureExample(
            title: 'Freelance Income',
            description: 'Create a "Freelance Work" category to track project payments separately from salary.',
            scenario: 'You do freelance work alongside your job. Create a "Freelance" income category. Use it when recording client payments to see how much you earn from freelancing.',
          ),
          FeatureExample(
            title: 'Pet Expenses',
            description: 'Add "Pet Care" category for tracking expenses on your pet\'s food, vet visits, and supplies.',
            scenario: 'You have a pet and want to track related costs. Create "Pet Care" expense category. Use it for dog food, vet bills, grooming to see monthly pet expenses.',
          ),
        ],
        tips: const [
          'Use broad categories, avoid too many specific ones',
          'Common categories: Food, Transport, Shopping, Bills, Healthcare',
          'Review category spending monthly in Analytics',
          'Merge similar categories to simplify tracking',
        ],
      ),

      // Analytics
      FeatureDocumentation(
        id: 'analytics',
        title: 'Analytics',
        description:
            'Visualize your financial data with charts and reports. Understand spending patterns, identify trends, and make informed decisions.',
        icon: Icons.analytics,
        color: Colors.deepOrange,
        category: 'Insights',
        steps: const [
          FeatureStep(
            title: 'Open Analytics',
            description: 'Tap the Analytics icon in the bottom navigation bar.',
            icon: Icons.bar_chart,
          ),
          FeatureStep(
            title: 'Select Time Period',
            description: 'Choose the period you want to analyze: month, quarter, year, or custom range.',
            icon: Icons.date_range,
          ),
          FeatureStep(
            title: 'View Charts',
            description: 'Explore spending breakdown by category, income vs expense trends, and budget utilization.',
            icon: Icons.pie_chart,
          ),
          FeatureStep(
            title: 'Identify Patterns',
            description: 'Look for unusual spikes, top spending categories, and areas to optimize.',
            icon: Icons.insights,
          ),
        ],
        examples: const [
          FeatureExample(
            title: 'Monthly Review',
            description: 'Check last month\'s spending to identify where your money went.',
            scenario: 'At month end, open Analytics, select last month. See that Food & Dining was ₹12,000 (25% of expenses), higher than budgeted. Decide to cook more at home.',
          ),
          FeatureExample(
            title: 'Yearly Comparison',
            description: 'Compare this year\'s spending with last year to spot trends.',
            scenario: 'Review yearly analytics. Notice transport costs increased 40% due to fuel prices. Consider carpooling or public transport to reduce costs.',
          ),
        ],
        tips: const [
          'Review analytics weekly to stay aware of spending',
          'Focus on top 3-5 spending categories for optimization',
          'Look for seasonal patterns in your expenses',
          'Use insights to adjust budgets and goals',
        ],
      ),

      // Biometric Authentication
      FeatureDocumentation(
        id: 'biometric',
        title: 'Biometric Lock',
        description:
            'Secure your financial data with fingerprint or Face ID. Quick access while keeping your information private.',
        icon: Icons.fingerprint,
        color: Colors.cyan,
        category: 'Security',
        steps: const [
          FeatureStep(
            title: 'Check Device Support',
            description: 'Ensure your device has fingerprint sensor or Face ID enabled in system settings.',
            icon: Icons.security,
          ),
          FeatureStep(
            title: 'Enable in Settings',
            description: 'Go to Settings > Security > Biometric Authentication and toggle it on.',
            icon: Icons.toggle_on,
          ),
          FeatureStep(
            title: 'Complete Verification',
            description: 'Authenticate once with your biometric to enable the feature.',
            icon: Icons.verified_user,
          ),
          FeatureStep(
            title: 'Unlock App',
            description: 'Next time you open the app, use biometric instead of PIN for quick access.',
            icon: Icons.lock_open,
          ),
        ],
        examples: const [
          FeatureExample(
            title: 'Quick Access',
            description: 'Use fingerprint to unlock app quickly when checking expenses in public.',
            scenario: 'You\'re at a store and want to check your budget. Instead of typing PIN, just use your fingerprint to unlock the app instantly and securely.',
          ),
          FeatureExample(
            title: 'Enhanced Security',
            description: 'Keep financial data secure even if someone knows your phone unlock PIN.',
            scenario: 'Your phone unlock and finance app use different security. Even if someone gets your phone PIN, they can\'t access your financial data without your biometric.',
          ),
        ],
        tips: const [
          'Enable biometric for faster app access',
          'Keep PIN as backup in case biometric fails',
          'Re-register biometric if not working reliably',
          'Biometric data never leaves your device',
        ],
      ),

      // Dark Mode
      FeatureDocumentation(
        id: 'darkmode',
        title: 'Dark Mode',
        description:
            'Switch to dark theme for comfortable viewing in low light and reduced eye strain. Modern sage and tan color scheme.',
        icon: Icons.dark_mode,
        color: Colors.blueGrey,
        category: 'Personalization',
        steps: const [
          FeatureStep(
            title: 'Open Settings',
            description: 'Go to Settings screen from the bottom navigation.',
            icon: Icons.settings,
          ),
          FeatureStep(
            title: 'Toggle Dark Mode',
            description: 'In the Appearance section, toggle the Dark Mode switch.',
            icon: Icons.brightness_4,
          ),
          FeatureStep(
            title: 'See Changes',
            description: 'The app will instantly switch to dark theme with sage and tan colors.',
            icon: Icons.palette,
          ),
          FeatureStep(
            title: 'Automatic Adjustment',
            description: 'All screens will adapt to dark mode including charts and forms.',
            icon: Icons.auto_awesome,
          ),
        ],
        examples: const [
          FeatureExample(
            title: 'Night Time Usage',
            description: 'Enable dark mode before bed to reduce eye strain while checking finances.',
            scenario: 'It\'s 11 PM and you want to check your daily expenses. Enable dark mode for comfortable viewing without harsh bright screens affecting your sleep.',
          ),
          FeatureExample(
            title: 'Battery Saving',
            description: 'Use dark mode on OLED screens to save battery life.',
            scenario: 'On your OLED iPhone, enable dark mode. The black backgrounds consume less power, extending your battery life during the day.',
          ),
        ],
        tips: const [
          'Dark mode is easier on eyes in low light',
          'Can help reduce battery drain on OLED screens',
          'Try both modes to see which you prefer',
          'Screenshots in dark mode look modern and sleek',
        ],
      ),

      // Income/Expense Filter
      FeatureDocumentation(
        id: 'income-expense-filter',
        title: 'Income/Expense Filter',
        description:
            'Filter your home screen summary cards by date range. View income and expenses for specific periods like this month, this year, or custom dates.',
        icon: Icons.filter_list,
        color: AppColors.accent,
        category: 'Features',
        steps: const [
          FeatureStep(
            title: 'Access Filter',
            description: 'On home screen, tap the filter icon near Income/Expense cards.',
            icon: Icons.filter_alt,
          ),
          FeatureStep(
            title: 'Select Period',
            description: 'Choose from All Time, This Month, This Year, Last Year, or Custom Range.',
            icon: Icons.date_range,
          ),
          FeatureStep(
            title: 'Custom Range',
            description: 'For custom dates, select start date then end date using the step-by-step picker.',
            icon: Icons.edit_calendar,
          ),
          FeatureStep(
            title: 'View Filtered Data',
            description: 'Income and Expense cards update to show totals for your selected period.',
            icon: Icons.visibility,
          ),
        ],
        examples: const [
          FeatureExample(
            title: 'Monthly Review',
            description: 'Check how much you earned and spent this month.',
            scenario: 'It\'s month end. Tap filter on home screen, select "This Month" to see your income (₹55,000) and expenses (₹42,000) for the current month only.',
          ),
          FeatureExample(
            title: 'Tax Calculation',
            description: 'Get yearly income total for tax filing by filtering for the financial year.',
            scenario: 'Filing taxes? Select "Custom Range" with April 1 to March 31 of the fiscal year to see your total annual income for tax purposes.',
          ),
        ],
        tips: const [
          'Filter only affects Income/Expense cards, not other sections',
          'Use "This Month" regularly to track monthly targets',
          'Custom range is useful for quarterly reviews',
          'Filter persists until you change it',
        ],
      ),
    ];
  }

  /// Get features grouped by category
  static Map<String, List<FeatureDocumentation>> getFeaturesByCategory() {
    final features = getAllFeatures();
    final Map<String, List<FeatureDocumentation>> grouped = {};

    for (final feature in features) {
      if (!grouped.containsKey(feature.category)) {
        grouped[feature.category] = [];
      }
      grouped[feature.category]!.add(feature);
    }

    return grouped;
  }

  /// Search features by keyword
  static List<FeatureDocumentation> searchFeatures(String query) {
    if (query.isEmpty) return getAllFeatures();

    final lowerQuery = query.toLowerCase();
    return getAllFeatures().where((feature) {
      return feature.title.toLowerCase().contains(lowerQuery) ||
          feature.description.toLowerCase().contains(lowerQuery) ||
          feature.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
