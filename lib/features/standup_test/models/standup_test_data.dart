class StandupTestData {
  StandupTestData();

  DateTime startedAt = DateTime.now();
  int supineDurationMinutes = 10;

  int? supineHr;
  int? supineSystolic;
  int? supineDiastolic;

  int? standing1MinHr;
  int? standing1MinSystolic;
  int? standing1MinDiastolic;

  int? standing3MinHr;
  int? standing3MinSystolic;
  int? standing3MinDiastolic;

  int? standing5MinHr;
  int? standing10MinHr;
  int? standing10MinSystolic;
  int? standing10MinDiastolic;

  String? notes;
}
