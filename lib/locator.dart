import 'package:bb_mobile/_pkg/barcode.dart';
import 'package:bb_mobile/_pkg/boltz/swap.dart';
import 'package:bb_mobile/_pkg/bull_bitcoin_api.dart';
import 'package:bb_mobile/_pkg/clipboard.dart';
import 'package:bb_mobile/_pkg/deep_link.dart';
import 'package:bb_mobile/_pkg/file_picker.dart';
import 'package:bb_mobile/_pkg/file_storage.dart';
import 'package:bb_mobile/_pkg/launcher.dart';
import 'package:bb_mobile/_pkg/logger.dart';
import 'package:bb_mobile/_pkg/mempool_api.dart';
import 'package:bb_mobile/_pkg/mnemonic_word.dart';
import 'package:bb_mobile/_pkg/nfc.dart';
import 'package:bb_mobile/_pkg/storage/hive.dart';
import 'package:bb_mobile/_pkg/storage/secure_storage.dart';
import 'package:bb_mobile/_pkg/storage/storage.dart';
import 'package:bb_mobile/_pkg/wallet/address.dart';
import 'package:bb_mobile/_pkg/wallet/balance.dart';
import 'package:bb_mobile/_pkg/wallet/bdk/sync.dart';
import 'package:bb_mobile/_pkg/wallet/create.dart';
import 'package:bb_mobile/_pkg/wallet/lwk/sync.dart';
import 'package:bb_mobile/_pkg/wallet/network.dart';
import 'package:bb_mobile/_pkg/wallet/repository/network.dart';
import 'package:bb_mobile/_pkg/wallet/repository/storage.dart';
import 'package:bb_mobile/_pkg/wallet/repository/wallets.dart';
import 'package:bb_mobile/_pkg/wallet/sensitive/create.dart';
import 'package:bb_mobile/_pkg/wallet/sensitive/repository.dart';
import 'package:bb_mobile/_pkg/wallet/sensitive/transaction.dart';
import 'package:bb_mobile/_pkg/wallet/sync.dart';
import 'package:bb_mobile/_pkg/wallet/transaction.dart';
import 'package:bb_mobile/_pkg/wallet/update.dart';
import 'package:bb_mobile/_pkg/wallet/utxo.dart';
import 'package:bb_mobile/create/bloc/create_cubit.dart';
import 'package:bb_mobile/currency/bloc/currency_cubit.dart';
import 'package:bb_mobile/home/bloc/home_cubit.dart';
import 'package:bb_mobile/import/bloc/words_cubit.dart';
import 'package:bb_mobile/network/bloc/network_cubit.dart';
import 'package:bb_mobile/network_fees/bloc/network_fees_cubit.dart';
import 'package:bb_mobile/settings/bloc/lighting_cubit.dart';
import 'package:bb_mobile/settings/bloc/settings_cubit.dart';
import 'package:bb_mobile/swap/bloc/watchtxs_bloc.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

const bbVersion = '0.1.98-1.1';

GetIt locator = GetIt.instance;

Future setupLocator({bool fromTest = false}) async {
  await _setupStorage(fromTest: fromTest);

  await _setupAPIs(fromTest: fromTest);
  await _setupRepositories(fromTest: fromTest);

  await _setupAppServices(fromTest: fromTest);
  await _setupWalletServices(fromTest: fromTest);
  await _setupBlocs(fromTest: fromTest);
}

Future _setupStorage({bool fromTest = false}) async {
  if (!fromTest) {
    final (secureStorage, hiveStorage) = await setupStorage();
    locator.registerSingleton<SecureStorage>(secureStorage);
    locator.registerSingleton<HiveStorage>(hiveStorage);
    locator.registerSingleton<IStorage>(locator<HiveStorage>());
  }
}

Future _setupRepositories({bool fromTest = false}) async {
  if (!fromTest) {
    locator.registerSingleton<WalletsRepository>(WalletsRepository());
    locator.registerSingleton<NetworkRepository>(NetworkRepository());
    locator.registerSingleton<WalletsStorageRepository>(
      WalletsStorageRepository(hiveStorage: locator<HiveStorage>()),
    );
  }
}

Future _setupAPIs({bool fromTest = false}) async {
  if (!fromTest) {
    locator.registerSingleton<Dio>(Dio());
    locator.registerSingleton<BullBitcoinAPI>(BullBitcoinAPI(locator<Dio>()));
    locator.registerSingleton<MempoolAPI>(MempoolAPI(locator<Dio>()));
  }
}

Future _setupWalletServices({bool fromTest = false}) async {
  if (!fromTest) {
    locator.registerFactory<BDKSync>(() => BDKSync());
    locator.registerFactory<LWKSync>(() => LWKSync());

    locator.registerFactory<WalletSync>(
      () => WalletSync(
        bdkSync: locator<BDKSync>(),
        lwkSync: locator<LWKSync>(),
        walletsRepository: locator<WalletsRepository>(),
        networkRepository: locator<NetworkRepository>(),
      ),
    );

    locator.registerSingleton<WalletUpdate>(WalletUpdate());
    locator.registerSingleton<WalletBalance>(WalletBalance());

    locator.registerSingleton<WalletTx>(WalletTx());
    locator.registerSingleton<WalletAddress>(WalletAddress());
    locator.registerSingleton<WalletUtxo>(WalletUtxo());
    locator.registerSingleton<SwapBoltz>(SwapBoltz(secureStorage: locator<SecureStorage>()));
    locator.registerSingleton<WalletNetwork>(
      WalletNetwork(
        networkRepository: locator<NetworkRepository>(),
      ),
    );

    locator.registerSingleton<WalletSensitiveCreate>(WalletSensitiveCreate());
    locator.registerSingleton<WalletSensitiveTx>(WalletSensitiveTx());
    locator.registerSingleton<WalletSensitiveRepository>(WalletSensitiveRepository());

    locator.registerSingleton<WalletCreate>(WalletCreate());
  }
}

Future _setupAppServices({bool fromTest = false}) async {
  if (!fromTest) {
    final deepLink = DeepLink();
    locator.registerSingleton<DeepLink>(deepLink);
    locator.registerSingleton<Logger>(Logger());
    locator.registerSingleton<Lighting>(
      Lighting(
        hiveStorage: locator<HiveStorage>(),
      ),
    );

    locator.registerSingleton<Barcode>(Barcode());
    locator.registerSingleton<Launcher>(Launcher());
    locator.registerSingleton<NFCPicker>(NFCPicker());
    locator.registerSingleton<FilePick>(FilePick());
    locator.registerSingleton<Clippboard>(Clippboard());
    locator.registerSingleton<WordsCubit>(
      WordsCubit(
        mnemonicWords: MnemonicWords(),
      ),
    );

    locator.registerSingleton<FileStorage>(FileStorage());
  }
}

Future _setupBlocs({bool fromTest = false}) async {
  if (!fromTest) {
    final settings = SettingsCubit(
      walletSync: locator<WalletSync>(),
      hiveStorage: locator<HiveStorage>(),
      mempoolAPI: locator<MempoolAPI>(),
      bbAPI: locator<BullBitcoinAPI>(),
    );

    locator.registerSingleton<NetworkCubit>(
      NetworkCubit(
        hiveStorage: locator<HiveStorage>(),
        walletNetwork: locator<WalletNetwork>(),
      ),
    );

    locator.registerSingleton<NetworkFeesCubit>(
      NetworkFeesCubit(
        hiveStorage: locator<HiveStorage>(),
        mempoolAPI: locator<MempoolAPI>(),
        networkCubit: locator<NetworkCubit>(),
      ),
    );

    locator.registerSingleton<CurrencyCubit>(
      CurrencyCubit(
        hiveStorage: locator<HiveStorage>(),
        bbAPI: locator<BullBitcoinAPI>(),
      ),
    );

    final swap = WatchTxsBloc(
      hiveStorage: locator<HiveStorage>(),
      secureStorage: locator<SecureStorage>(),
      walletAddress: locator<WalletAddress>(),
      walletRepository: locator<WalletsStorageRepository>(),
      walletSensitiveRepository: WalletSensitiveRepository(),
      settingsCubit: settings,
      networkCubit: locator<NetworkCubit>(),
      swapBoltz: locator<SwapBoltz>(),
      walletTx: locator<WalletTx>(),
      walletTransaction: locator<WalletTx>(),
    );

    final homeCubit = HomeCubit(
      hiveStorage: locator<HiveStorage>(),
      createWalletCubit: CreateWalletCubit(
        walletCreate: locator<WalletCreate>(),
        walletSensCreate: locator<WalletSensitiveCreate>(),
        settingsCubit: settings,
        walletRepository: locator<WalletsStorageRepository>(),
        hiveStorage: locator<HiveStorage>(),
        secureStorage: locator<SecureStorage>(),
        walletSensRepository: locator<WalletSensitiveRepository>(),
        networkCubit: locator<NetworkCubit>(),
      ),
      walletRepository: locator<WalletsStorageRepository>(),
    );

    swap.homeCubit = homeCubit;
    locator.registerSingleton<WatchTxsBloc>(swap);

    settings.homeCubit = homeCubit;
    locator<NetworkCubit>().homeCubit = homeCubit;
    settings.loadTimer();

    locator.registerSingleton<SettingsCubit>(settings);

    locator.registerSingleton<HomeCubit>(homeCubit);
  }
}
