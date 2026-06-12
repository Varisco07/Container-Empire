import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'player_service.dart';

// ─── Product IDs ─────────────────────────────────────────────────────────────
// Questi ID devono corrispondere ESATTAMENTE a quelli creati su:
//   • App Store Connect  (iOS)
//   • Google Play Console (Android)

class IapProducts {
  static const gems50    = 'container_empire_gems_50';
  static const gems150   = 'container_empire_gems_150';
  static const gems350   = 'container_empire_gems_350';
  static const gems800   = 'container_empire_gems_800';
  static const gems2000  = 'container_empire_gems_2000';
  static const gems5000  = 'container_empire_gems_5000';
  static const vipMonthly = 'container_empire_vip_monthly';

  // Quante gemme dà ogni prodotto
  static const gemRewards = <String, int>{
    gems50:   50,
    gems150:  150,
    gems350:  350,
    gems800:  800,
    gems2000: 2000,
    gems5000: 5000,
  };

  static const allIds = {
    gems50, gems150, gems350, gems800, gems2000, gems5000, vipMonthly,
  };
}

// ─── Stato IAP ────────────────────────────────────────────────────────────────

enum IapStatus { loading, available, unavailable, purchasing, error }

class IapState {
  final IapStatus status;
  final Map<String, ProductDetails> products;
  final String? errorMessage;

  const IapState({
    this.status = IapStatus.loading,
    this.products = const {},
    this.errorMessage,
  });

  IapState copyWith({IapStatus? status, Map<String, ProductDetails>? products, String? errorMessage}) =>
      IapState(
        status: status ?? this.status,
        products: products ?? this.products,
        errorMessage: errorMessage,
      );
}

// ─── Servizio IAP ─────────────────────────────────────────────────────────────

class IapService {
  final InAppPurchase _iap = InAppPurchase.instance;
  final PlayerService _playerService;

  final _stateController = StreamController<IapState>.broadcast();
  Stream<IapState> get stateStream => _stateController.stream;

  IapState _state = const IapState();
  IapState get currentState => _state;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  IapService(this._playerService);

  // ── Inizializzazione ──────────────────────────────────────────────────────

  Future<void> init() async {
    // Su web gli IAP non sono supportati
    if (kIsWeb) {
      _emit(_state.copyWith(status: IapStatus.unavailable,
          errorMessage: 'Acquisti disponibili su iOS e Android'));
      return;
    }

    final available = await _iap.isAvailable();
    if (!available) {
      _emit(_state.copyWith(status: IapStatus.unavailable,
          errorMessage: 'Store non disponibile su questo dispositivo'));
      return;
    }

    // Ascolta aggiornamenti acquisti
    _purchaseSub = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (e) => _emit(_state.copyWith(
          status: IapStatus.error, errorMessage: e.toString())),
    );

    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    _emit(_state.copyWith(status: IapStatus.loading));
    final response = await _iap.queryProductDetails(IapProducts.allIds);

    if (response.error != null) {
      _emit(_state.copyWith(
          status: IapStatus.error,
          errorMessage: response.error!.message));
      return;
    }

    if (response.productDetails.isEmpty) {
      _emit(_state.copyWith(
          status: IapStatus.error,
          errorMessage: 'Nessun prodotto trovato. Verifica la configurazione sullo store.'));
      return;
    }

    final map = <String, ProductDetails>{
      for (final p in response.productDetails) p.id: p,
    };

    _emit(_state.copyWith(status: IapStatus.available, products: map));
  }

  // ── Acquisto ──────────────────────────────────────────────────────────────

  Future<void> buyProduct(String productId) async {
    if (kIsWeb) {
      _emit(_state.copyWith(
          status: IapStatus.unavailable,
          errorMessage: 'Acquisti disponibili solo su iOS/Android'));
      return;
    }

    final product = _state.products[productId];
    if (product == null) return;

    _emit(_state.copyWith(status: IapStatus.purchasing));

    final isSubscription = productId == IapProducts.vipMonthly;
    final param = isSubscription
        ? PurchaseParam(productDetails: product)
        : PurchaseParam(productDetails: product);

    if (isSubscription) {
      await _iap.buyNonConsumable(purchaseParam: param);
    } else {
      await _iap.buyConsumable(purchaseParam: param);
    }
  }

  // ── Ripristina acquisti (per VIP / non consumable) ────────────────────────

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  // ── Gestione aggiornamenti acquisto ───────────────────────────────────────

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _emit(_state.copyWith(status: IapStatus.purchasing));

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _deliverProduct(purchase);
          await _iap.completePurchase(purchase);
          _emit(_state.copyWith(status: IapStatus.available));

        case PurchaseStatus.error:
          await _iap.completePurchase(purchase);
          _emit(_state.copyWith(
              status: IapStatus.error,
              errorMessage: purchase.error?.message ?? 'Errore durante l\'acquisto'));

        case PurchaseStatus.canceled:
          _emit(_state.copyWith(status: IapStatus.available));
      }
    }
  }

  // ── Consegna prodotto ─────────────────────────────────────────────────────

  Future<void> _deliverProduct(PurchaseDetails purchase) async {
    final productId = purchase.productID;

    // Gemme
    final gems = IapProducts.gemRewards[productId];
    if (gems != null) {
      await _playerService.addGems(gems);
      return;
    }

    // VIP
    if (productId == IapProducts.vipMonthly) {
      await _playerService.activateVip();
      return;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────

  void _emit(IapState state) {
    _state = state;
    if (!_stateController.isClosed) _stateController.add(state);
  }

  void dispose() {
    _purchaseSub?.cancel();
    _stateController.close();
  }
}
