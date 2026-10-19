import 'package:flutter/foundation.dart';

import '../../../data_access/repositories/discovery_repository.dart';
import '../../../data_access/repositories/request_repository.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../models/connection_request.dart';

/// One investor request with the investor's display data.
class RequestRow {
  const RequestRow({
    required this.request,
    required this.name,
    required this.initials,
    required this.title,
  });

  final ConnectionRequest request;
  final String name;
  final String initials;

  /// "Angel Investor".
  final String title;

  /// "Angel Investor · 2h ago".
  String get sub {
    final when = request.whenLabel;
    return when == null || when.isEmpty ? title : '$title · $when';
  }
}

/// State of Manage startup -> Requests (docs/05 D3): the Pending / Accepted /
/// Declined filter and accept / decline. Follows [RequestRepository] changes.
class RequestsViewModel extends ChangeNotifier with SafeNotifier {
  RequestsViewModel({
    required this.startupId,
    RequestRepository? requests,
    DiscoveryRepository? discovery,
  }) : _requests = requests ?? RequestRepository.instance,
       _discovery = discovery ?? DiscoveryRepository.instance {
    _requests.inboxChanges.addListener(notifyListeners);
  }

  final String startupId;
  final RequestRepository _requests;
  final DiscoveryRepository _discovery;

  RequestStatus filter = RequestStatus.pending;

  void select(RequestStatus status) {
    if (status == filter) return;
    filter = status;
    notifyListeners();
  }

  int count(RequestStatus status) =>
      _requests.inboxFor(startupId).where((r) => r.status == status).length;

  /// The requests of the current filter, with investor names.
  List<RequestRow> get rows => [
    for (final r in _requests.inboxFor(startupId))
      if (r.status == filter) _row(r),
  ];

  RequestRow _row(ConnectionRequest r) {
    final investor = _discovery.investorById(r.investorId);
    return RequestRow(
      request: r,
      name: investor?.name ?? 'Investor',
      initials: investor?.initials ?? 'IN',
      title: investor?.title ?? 'Investor',
    );
  }

  /// Accepts a request; returns the investor's name for the toast.
  String accept(RequestRow row) {
    _requests.setStatus(row.request.id, RequestStatus.accepted);
    return row.name;
  }

  void decline(RequestRow row) =>
      _requests.setStatus(row.request.id, RequestStatus.declined);

  @override
  void dispose() {
    _requests.inboxChanges.removeListener(notifyListeners);
    super.dispose();
  }
}
