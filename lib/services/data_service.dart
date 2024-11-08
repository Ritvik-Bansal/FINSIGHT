import 'package:csv/csv.dart';
import 'package:finsight/models/account_balance.dart';
import 'package:finsight/models/monthly_spending.dart';
import 'package:finsight/models/transaction.dart';
import 'package:finsight/models/credit_card.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class DataService {
  Future<List<AccountBalance>> getAccountBalances() async {
    try {
      final String data =
          await rootBundle.loadString('assets/data/account_balances.csv');

      List<List<dynamic>> csvTable = const CsvToListConverter().convert(
        data,
        eol: '\n',
        fieldDelimiter: ',',
      );

      List<AccountBalance> balances = [];
      if (csvTable.length > 1) {
        for (var i = 1; i < csvTable.length; i++) {
          try {
            var row = csvTable[i];
            if (row.length >= 6) {
              balances.add(AccountBalance(
                date: DateTime.parse(row[0].toString()),
                checking: double.parse(row[1].toString()),
                creditCardBalance: double.parse(row[2].toString()),
                savings: double.parse(row[3].toString()),
                investmentAccount: double.parse(row[4].toString()),
                netWorth: double.parse(row[5].toString()),
              ));
            }
          } catch (e) {
            print('Error parsing row $i: $e');
            continue;
          }
        }
      }

      return balances;
    } catch (e) {
      print('Error loading account balances: $e');
      return [];
    }
  }

  Future<List<Transaction>> getTransactions() async {
    try {
      final String data =
          await rootBundle.loadString('assets/data/transactions.csv');

      List<List<dynamic>> csvTable = const CsvToListConverter().convert(
        data,
        eol: '\n',
        fieldDelimiter: ',',
      );

      List<Transaction> transactions = [];
      if (csvTable.length > 1) {
        for (var i = 1; i < csvTable.length; i++) {
          try {
            var row = csvTable[i];
            if (row.length >= 6) {
              transactions.add(Transaction(
                date: DateTime.parse(row[0].toString()),
                description: row[1].toString(),
                category: row[2].toString(),
                amount: double.parse(row[3].toString()),
                account: row[4].toString(),
                transactionType: row[5].toString(),
                cardId: row.length >= 7 ? row[6].toString() : null,
              ));
            }
          } catch (e) {
            print('Error parsing row $i: $e');
            continue;
          }
        }
      }

      return transactions;
    } catch (e) {
      print('Error loading transactions: $e');
      return [];
    }
  }

  List<CreditCard> getCreditCards(
      List<Transaction> transactions, AccountBalance balance) {
    final secondaryTransactions = transactions
        .where((t) => t.account == 'Credit Card' && t.cardId == 'secondary')
        .toList();

    double secondaryBalance = 0;
    if (secondaryTransactions.isNotEmpty) {
      secondaryBalance = secondaryTransactions
          .map((t) => t.transactionType == 'Debit' ? t.amount : -t.amount)
          .reduce((a, b) => a + b);
    }

    final cards = [CreditCard.primary(balance.creditCardBalance)];

    if (secondaryTransactions.isNotEmpty) {
      cards.add(CreditCard.secondary(secondaryBalance));
    }

    return cards;
  }

  Future<List<MonthlySpending>> getMonthlySpending() async {
    try {
      final String data = await rootBundle
          .loadString('assets/data/monthly_spending_categories.csv');

      print('Raw CSV data:');
      print(data);

      List<List<dynamic>> csvTable = const CsvToListConverter().convert(
        data,
        eol: '\n',
        fieldDelimiter: ',',
        shouldParseNumbers: false,
      );

      print('Parsed CSV table length: ${csvTable.length}');
      if (csvTable.isNotEmpty) {
        print('Headers: ${csvTable[0]}');
      }

      List<MonthlySpending> monthlySpending = [];

      if (csvTable.isEmpty) {
        print('Error: CSV table is empty');
        return [];
      }

      if (csvTable[0].length != 11) {
        print(
            'Error: Invalid number of columns. Expected 11, got ${csvTable[0].length}');
        return [];
      }

      for (var i = 1; i < csvTable.length; i++) {
        try {
          var row = csvTable[i];
          if (row.length != 11) {
            continue;
          }

          monthlySpending.add(MonthlySpending(
            date: DateFormat('yyyy-MM').parse(row[0].toString().trim()),
            groceries: _parseDouble(row[1].toString().trim()),
            utilities: _parseDouble(row[2].toString().trim()),
            rent: _parseDouble(row[3].toString().trim()),
            transportation: _parseDouble(row[4].toString().trim()),
            entertainment: _parseDouble(row[5].toString().trim()),
            diningOut: _parseDouble(row[6].toString().trim()),
            shopping: _parseDouble(row[7].toString().trim()),
            healthcare: _parseDouble(row[8].toString().trim()),
            insurance: _parseDouble(row[9].toString().trim()),
            miscellaneous: _parseDouble(row[10].toString().trim()),
          ));
        } catch (e) {
          print('Error parsing row $i: $e');
          continue;
        }
      }

      return monthlySpending;
    } catch (e) {
      print('Error loading monthly spending: $e');
      return [];
    }
  }

  double _parseDouble(String value) {
    try {
      return double.parse(value);
    } catch (e) {
      print('Error parsing double value "$value": $e');
      return 0.0;
    }
  }
}
