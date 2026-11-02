import 'package:charcoal/charcoal.dart';

part 'book_loan.charcoal.g.dart';

@immutable
@Charcoal()
final class const BookLoan._(this.reader, this.days) with BookLoanCharcoal {
  final String reader;
  final int days;

  factory(String reader, int days) {
    if (days <= 0) {
      throw ArgumentError.value(days, 'days');
    }
    return BookLoan._(reader, days);
  }
}
