import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:bb_mobile/_model/swap.dart';
import 'package:bb_mobile/_model/wallet.dart';
import 'package:bb_mobile/_pkg/boltz/types.dart';
import 'package:bb_mobile/_pkg/consts/configs.dart';
import 'package:bb_mobile/_pkg/error.dart';
import 'package:bb_mobile/_pkg/storage/secure_storage.dart';
import 'package:bb_mobile/_pkg/storage/storage.dart';
import 'package:bb_mobile/_pkg/wallet/repository/network.dart';
import 'package:boltz_dart/boltz_dart.dart';
import 'package:convert/convert.dart';
import 'package:dio/dio.dart';
import 'package:lwk_dart/lwk_dart.dart' as lwk;

class SwapBoltz {
  SwapBoltz({
    required SecureStorage secureStorage,
    required Dio dio,
    required NetworkRepository networkRepository,
  })  : _secureStorage = secureStorage,
        _networkRepository = networkRepository,
        _dio = dio;

  final SecureStorage _secureStorage;
  final Dio _dio;
  final NetworkRepository _networkRepository;

  Future<(Invoice?, Err?)> decodeInvoice({
    required String invoice,
    String? boltzUrl,
  }) async {
    try {
      final res = await DecodedInvoice.fromString(
        s: invoice,
        boltzUrl: boltzUrl,
      );
      final inv = Invoice.fromDecodedInvoice(res, invoice);
      return (inv, null);
    } catch (e) {
      return (null, Err(e.toString()));
    }
  }

  Future<(Fees?, Err?)> getFeesAndLimits({
    required String boltzUrl,
  }) async {
    try {
      final res = Fees(
        boltzUrl: 'https://' + boltzUrl,
      );
      return (res, null);
    } catch (e) {
      return (null, Err(e.toString()));
    }
  }

  Future<(BoltzApi?, Err?)> initializeBoltzApi(bool isTestnet) async {
    try {
      final api = await BoltzApi.newBoltzApi(
        isTestnet ? boltzTestnetUrl : boltzMainnetUrl,
      );

      return (api, null);
    } catch (e) {
      return (null, Err(e.toString()));
    }
  }

  Future<(SwapStatusResponse?, Err?)> getSwapStatus(
    String id,
    bool isTestnet,
  ) async {
    try {
      final url = isTestnet ? boltzTestnetUrl : boltzMainnetUrl;
      final urlWithoutVersion = url.endsWith('/v2') ? url.split('/')[0] : url;

      final res = await _dio
          .post('https://$urlWithoutVersion/swapstatus', data: {'id': id});

      final data = res.data['status'] as String;
      final status = getSwapStatusFromString(data);
      final resp = SwapStatusResponse(status: status);

      return (resp, null);
    } catch (e) {
      return (null, Err(e.toString()));
    }
  }

  Future<Err?> deleteSwapSensitive({required String id}) async {
    try {
      final err = await _secureStorage
          .deleteValue(StorageKeys.swapTxSensitive + '_' + id);
      if (err != null) throw err;
      return null;
    } catch (e) {
      return Err(e.toString());
    }
  }

  ///
  ///
  /// ------------------------- V2 ------------------------------
  ///
  ///
  Future<(SwapTx?, Err?)> receive({
    required String mnemonic,
    required int index,
    required int outAmount,
    required Chain network,
    required String electrumUrl,
    required String boltzUrl,
    required bool isLiquid,
    required String claimAddress,
  }) async {
    try {
      late SwapTx swapTx;
      if (!isLiquid) {
        final res = await BtcLnSwap.newReverse(
          mnemonic: mnemonic,
          index: index,
          outAmount: outAmount,
          network: network,
          electrumUrl: electrumUrl,
          boltzUrl: boltzUrl,
          outAddress: claimAddress,
        );
        // final obj = res;

        final swapSensitive = res.createSwapSensitiveFromBtcLnSwap();
        // SwapTxSensitive.fromBtcLnSwap(res);
        final err = await _secureStorage.saveValue(
          key: StorageKeys.swapTxSensitive + '_' + res.id,
          value: jsonEncode(swapSensitive.toJson()),
        );
        if (err != null) throw err;
        swapTx =
            res.createSwapFromBtcLnSwap().copyWith(claimAddress: claimAddress);
        // SwapTx.fromBtcLnSwap(res);
      } else {
        final res = await LbtcLnSwap.newReverse(
          mnemonic: mnemonic,
          index: index,
          outAmount: outAmount,
          network: network,
          electrumUrl: electrumUrl,
          boltzUrl: boltzUrl,
          outAddress: claimAddress,
        );
        // final obj = res;

        final swapSensitive = res.createSwapSensitiveFromLbtcLnSwap();
        // SwapTxSensitive.fromLbtcLnSwap(res);
        final err = await _secureStorage.saveValue(
          key: StorageKeys.swapTxSensitive + '_' + res.id,
          value: jsonEncode(swapSensitive.toJson()),
        );
        if (err != null) throw err;
        swapTx =
            res.createSwapFromLbtcLnSwap().copyWith(claimAddress: claimAddress);
        // SwapTx.fromLbtcLnSwap(res);
      }

      return (swapTx, null);
    } catch (e) {
      return (null, Err(e.toString()));
    }
  }

  Future<(SwapTx?, Err?)> send({
    required String mnemonic,
    required int index,
    required String invoice,
    required Chain network,
    required String electrumUrl,
    required String boltzUrl,
    required bool isLiquid,
  }) async {
    try {
      if (isLiquid) {
        final res = await LbtcLnSwap.newSubmarine(
          mnemonic: mnemonic,
          index: index,
          invoice: invoice,
          network: network,
          electrumUrl: electrumUrl,
          boltzUrl: boltzUrl,
        );

        final swapSensitive = res.createSwapSensitiveFromLbtcLnSwap();

        //SwapTxSensitive.fromBtcLnSwap(res);
        final err = await _secureStorage.saveValue(
          key: StorageKeys.swapTxSensitive + '_' + res.id,
          value: jsonEncode(swapSensitive.toJson()),
        );
        if (err != null) throw err;
        final swap = res.createSwapFromLbtcLnSwap();

        // SwapTx.fromBtcLnSwap(res);

        return (swap, null);
      } else {
        final res = await BtcLnSwap.newSubmarine(
          mnemonic: mnemonic,
          index: index,
          invoice: invoice,
          network: network,
          electrumUrl: electrumUrl,
          boltzUrl: boltzUrl,
        );

        final swapSensitive = res.createSwapSensitiveFromBtcLnSwap();

        //SwapTxSensitive.fromBtcLnSwap(res);
        final err = await _secureStorage.saveValue(
          key: StorageKeys.swapTxSensitive + '_' + res.id,
          value: jsonEncode(swapSensitive.toJson()),
        );
        if (err != null) throw err;
        final swap = res.createSwapFromBtcLnSwap();
        // SwapTx.fromBtcLnSwap(res);

        return (swap, null);
      }
    } catch (e) {
      return (null, Err(e.toString()));
    }
  }

  Future<(String?, Err?)> broadcast({
    required SwapTx swapTx,
    required String signedHex,
  }) async {
    try {
      if (!swapTx.isLiquid()) throw 'Only Liquid';

      final (swapSensitiveStr, err) = await _secureStorage.getValue(
        StorageKeys.swapTxSensitive + '_' + swapTx.id,
      );
      if (err != null) throw err;

      log('-----swap json\n' + swapSensitiveStr.toString() + '\n ------');

      String txid = '';
      if (swapTx.isChainSwap()) {
        final swapSensitive = ChainSwapTxSensitive.fromJson(
          jsonDecode(swapSensitiveStr!) as Map<String, dynamic>,
        );
        final swap = swapTx.toChainSwap(swapSensitive);
        // TODO: How to broadcast this.
        // txid = await swap.broadcastTx(signedBytes: signedBytes);
      } else {
        final swapSensitive = LnSwapTxSensitive.fromJson(
          jsonDecode(swapSensitiveStr!) as Map<String, dynamic>,
        );
        final swap = swapTx.toLbtcLnSwap(swapSensitive);
        txid = await swap.broadcastBoltz(signedHex: signedHex);
      }

      return (txid, null);
    } catch (e) {
      return (null, Err(e.toString()));
    }
  }

  Future<(String?, Err?)> claimReverseSwap({
    required SwapTx swapTx,
    required Wallet wallet,
    required bool tryCooperate,
    bool broadcastViaBoltz = false,
  }) async {
    try {
      final address = wallet.lastGeneratedAddress?.address;
      if (address == null || address.isEmpty) throw 'Address not found';

      final isLiquid = wallet.isLiquid();

      final (swapSentive, err) = await _secureStorage.getValue(
        StorageKeys.swapTxSensitive + '_' + swapTx.id,
      );
      if (err != null) throw err;

      final swapSensitive = LnSwapTxSensitive.fromJson(
        jsonDecode(swapSentive!) as Map<String, dynamic>,
      );

      if (isLiquid) {
        final (blockchain, err) = _networkRepository.liquidUrl;
        if (err != null) throw err;

        // final claimFeesEstimate = fees?.lbtcReverse.claimFeesEstimate;
        // if (claimFeesEstimate == null) throw 'Fees estimate not found';
        final swap = swapTx.toLbtcLnSwap(swapSensitive);
        // .copyWith(electrumUrl: 'blockstream.info:995');

        // await Future.delayed(5.seconds);
        final signedHex = await swap.claim(
          outAddress: address,
          absFee: swapTx.claimFees!,
          tryCooperate: tryCooperate,
        );
        // locator<Logger>()
        //     .log('------${swapTx.id}-----\n$signedHex------signed-claim-----');
        if (broadcastViaBoltz) {
          final txid = await swap.broadcastBoltz(
            signedHex: signedHex,
          );
          return (txid, null);
        } else {
          try {
            final txid = await lwk.Wallet.broadcastTx(
              electrumUrl: blockchain!,
              txBytes: Uint8List.fromList(hex.decode(signedHex)),
            );
            return (txid, null);
          } catch (e) {
            // print('Failed to broadcast transaction: $e');
            await Future.delayed(
              const Duration(
                seconds: 5,
              ),
            ); // this non-blocking delay is to accomodate mempool propogation if the first try failed.
            final txid = await lwk.Wallet.broadcastTx(
              electrumUrl: blockchain!,
              txBytes: Uint8List.fromList(hex.decode(signedHex)),
            );
            return (txid, null);
          }
        }
      } else {
        final boltzurl = wallet.network == BBNetwork.Testnet
            ? boltzTestnetUrl
            : boltzMainnetUrl;

        final (fees, errFees) = await getFeesAndLimits(
          boltzUrl: boltzurl,
        );
        if (errFees != null) {
          throw errFees;
        }

        final reverseFees = await fees?.reverse();

        // final claimFeesEstimate = fees?.btcReverse.claimFeesEstimate;
        final claimFeesEstimate = reverseFees?.btcFees.minerFees;
        if (claimFeesEstimate == null) throw 'Fees estimate not found';

        final swap = swapTx.toBtcLnSwap(swapSensitive);

        final signedHex = await swap.claim(
          outAddress: address,
          absFee: claimFeesEstimate.claim,
          tryCooperate: tryCooperate,
        );
        final txid = await swap.broadcastLocal(signedHex: signedHex);
        return (txid, null);
      }
    } catch (e) {
      return (null, Err(e.toString()));
    }
  }

  Future<(String?, Err?)> refundSubmarineSwap({
    required SwapTx swapTx,
    required Wallet wallet,
    required bool tryCooperate,
    bool broadcastViaBoltz = false,
  }) async {
    try {
      final address = wallet.lastGeneratedAddress?.address;
      if (address == null || address.isEmpty) throw 'Address not found';

      final boltzurl = wallet.network == BBNetwork.Testnet
          ? boltzTestnetUrl
          : boltzMainnetUrl;

      final (fees, errFees) = await getFeesAndLimits(
        boltzUrl: boltzurl,
      );
      if (errFees != null) {
        throw errFees;
      }

      final isLiquid = wallet.isLiquid();

      final (swapSentive, err) = await _secureStorage.getValue(
        StorageKeys.swapTxSensitive + '_' + swapTx.id,
      );
      if (err != null) throw err;

      final swapSensitive = LnSwapTxSensitive.fromJson(
        jsonDecode(swapSentive!) as Map<String, dynamic>,
      );

      final submarineFees = await fees?.submarine();
      if (isLiquid) {
        // final refundFeesEstimate = fees?.lbtcSubmarine.claimFees;
        final refundFeesEstimate = submarineFees?.lbtcFees.minerFees;
        if (refundFeesEstimate == null) throw 'Fees estimate not found';

        final swap = swapTx.toLbtcLnSwap(swapSensitive);
        // waiting on PR to add cooperative refund
        // final resp = await swap.refund(
        //   outAddress: address,
        //   absFee: refundFeesEstimate,
        //   tryCooperate: tryCooperate,
        // );

        // return (resp, null);

        final signedHex = await swap.refund(
          outAddress: address,
          absFee: refundFeesEstimate,
          tryCooperate: tryCooperate,
        );
        // locator<Logger>()
        //     .log('------${swapTx.id}-----\n$signedHex------signed-refund-----');
        final (blockchain, err) = _networkRepository.liquidUrl;
        if (err != null) throw err;
        if (broadcastViaBoltz) {
          final txid = await swap.broadcastBoltz(
            signedHex: signedHex,
          );
          return (txid, null);
        } else {
          try {
            final txid = await lwk.Wallet.broadcastTx(
              electrumUrl: blockchain!,
              txBytes: Uint8List.fromList(hex.decode(signedHex)),
            );
            return (txid, null);
          } catch (e) {
            print('Failed to broadcast transaction: $e');
            await Future.delayed(
              const Duration(
                seconds: 5,
              ),
            ); // this non-blocking delay is to accomodate mempool propogation if the first try failed.
            final txid = await lwk.Wallet.broadcastTx(
              electrumUrl: blockchain!,
              txBytes: Uint8List.fromList(hex.decode(signedHex)),
            );
            return (txid, null);
          }
        }
      } else {
        // final refundFeesEstimate = fees?.btcSubmarine.claimFees;
        final submarineFees = await fees?.submarine();
        final refundFeesEstimate = submarineFees?.btcFees.minerFees;
        if (refundFeesEstimate == null) throw 'Fees estimate not found';

        final swap = swapTx.toBtcLnSwap(swapSensitive);

        final signedHex = await swap.refund(
          outAddress: address,
          absFee: refundFeesEstimate,
          tryCooperate: tryCooperate,
        );
        final txid = await swap.broadcastLocal(signedHex: signedHex);
        return (txid, null);
      }
    } catch (e) {
      return (null, Err(e.toString()));
    }
  }

  Future<Err?> cooperativeSubmarineClose({
    required SwapTx swapTx,
    required Wallet wallet,
  }) async {
    try {
      final isLiquid = wallet.isLiquid();

      final (swapSentive, err) = await _secureStorage.getValue(
        StorageKeys.swapTxSensitive + '_' + swapTx.id,
      );
      if (err != null) throw err;

      final swapSensitive = LnSwapTxSensitive.fromJson(
        jsonDecode(swapSentive!) as Map<String, dynamic>,
      );

      if (isLiquid) {
        final swap = swapTx.toLbtcLnSwap(swapSensitive);
        await swap.coopCloseSubmarine();
        return null;
      } else {
        final swap = swapTx.toBtcLnSwap(swapSensitive);
        await swap.coopCloseSubmarine();
        return null;
      }
    } catch (e) {
      return Err(e.toString());
    }
  }

  Future<(String?, Err?)> refundChainSwap({
    required SwapTx swapTx,
    required Wallet
        wallet, // do we need to send the entire wallet into this function?
    required bool tryCooperate,
    bool broadcastViaBoltz = false,
  }) async {
    try {
      String address;
      if (swapTx.isChainReceive()) {
        address = swapTx.refundAddress ?? '';
      } else {
        address = wallet.lastGeneratedAddress?.address ?? '';
      }
      // TODO: (or) swapTx.refundAddress
      if (address.isEmpty) throw 'Address not found';

      final boltzurl = wallet.network == BBNetwork.Testnet
          ? boltzTestnetUrl
          : boltzMainnetUrl;

      final (fees, errFees) = await getFeesAndLimits(
        boltzUrl: boltzurl,
      );
      if (errFees != null) {
        throw errFees;
      }

      final isLiquid =
          swapTx.isChainReceive() ? !wallet.isLiquid() : wallet.isLiquid();

      final (swapSentive, err) = await _secureStorage.getValue(
        StorageKeys.swapTxSensitive + '_' + swapTx.id,
      );
      if (err != null) throw err;

      final swapSensitive = ChainSwapTxSensitive.fromJson(
        jsonDecode(swapSentive!) as Map<String, dynamic>,
      );

      final chainFees = await fees?.chain();
      final refundFeesEstimate = isLiquid
          ? chainFees?.lbtcFees.userClaim
          : chainFees?.btcFees.userClaim;
      if (refundFeesEstimate == null) throw 'Fees estimate not found';

      final swap = swapTx.toChainSwap(swapSensitive);

      final resp = await swap.refund(
        refundAddress: address,
        absFee: refundFeesEstimate,
        tryCooperate: tryCooperate,
      );

      return (resp, null);
    } catch (e) {
      return (null, Err(e.toString()));
    }
  }

  Future<(String?, Err?)> claimChainSwap({
    required SwapTx swapTx,
    required Wallet wallet,
    required bool tryCooperate,
  }) async {
    try {
      final (swapSentive, err) = await _secureStorage.getValue(
        StorageKeys.swapTxSensitive + '_' + swapTx.id,
      );
      if (err != null) throw err;

      log(swapSentive!);

      final swapSensitive = ChainSwapTxSensitive.fromJson(
        jsonDecode(swapSentive) as Map<String, dynamic>,
      );

      final boltzurl = wallet.network == BBNetwork.Testnet
          ? boltzTestnetUrl
          : boltzMainnetUrl;

      final (fees, errFees) = await getFeesAndLimits(
        // refundAddress: swap.direction == ChainSwapDirection.btcToLbtc
        //     ? 'tb1qlmj5w2upndhhc9rgd9jg07vcuafg3jydef7uvz'
        //     : 'tlq1qqd8f92dfedpvsydxxk54l8glwa5m8e84ygqz7n5dgyujp37v3n60pjzfrc2xu4a9fla6snzgznn9tjpwc99d7kn2s472sw2la',
        // TODO:Onchain
        boltzUrl: boltzurl,
      );
      if (errFees != null) {
        throw errFees;
      }

      final onchainFees = await fees?.chain();

      final claimFeesEstimate =
          swapTx.chainSwapDetails!.direction == ChainSwapDirection.btcToLbtc
              ? onchainFees?.lbtcFees.userClaim
              : onchainFees?.btcFees.userClaim;
      if (claimFeesEstimate == null) throw 'Fees estimate not found';

      final swap = swapTx.toChainSwap(swapSensitive);
      final resp = await swap.claim(
        outAddress: swapTx.claimAddress!,
        refundAddress: swapTx.refundAddress!,
        absFee: claimFeesEstimate,
        tryCooperate: tryCooperate,
      );

      return (resp, null);
    } catch (e) {
      return (null, Err(e.toString()));
    }
  }

  Future<(String?, Err?)> chainUserLockup({
    required SwapTx swapTx,
    required Wallet wallet,
  }) async {
    try {
      final (swapSentive, err) = await _secureStorage.getValue(
        StorageKeys.swapTxSensitive + '_' + swapTx.id,
      );
      if (err != null) throw err;

      log(swapSentive!);

      final swapSensitive = ChainSwapTxSensitive.fromJson(
        jsonDecode(swapSentive) as Map<String, dynamic>,
      );

      final boltzurl = wallet.network == BBNetwork.Testnet
          ? boltzTestnetUrl
          : boltzMainnetUrl;

      final swap = swapTx.toChainSwap(swapSensitive);

      final resp = await swap.getUserLockup();

      return (resp, null);
    } catch (e) {
      return (null, Err(e.toString()));
    }
  }

  Future<(SwapTx?, Err?)> chainSwap({
    required String mnemonic,
    required int index,
    required ChainSwapDirection direction,
    required OnChainSwapType onChainSwapType,
    required int amount,
    required Chain network,
    required String btcElectrumUrl,
    required String lbtcElectrumUrl,
    required String boltzUrl,
    // required bool isLiquid,
    required String toWalletId,
  }) async {
    try {
      final res = await ChainSwap.newSwap(
        direction: direction,
        mnemonic: mnemonic,
        index: index,
        amount: amount,
        isTestnet:
            network == Chain.bitcoinTestnet || network == Chain.liquidTestnet,
        btcElectrumUrl: btcElectrumUrl,
        lbtcElectrumUrl: lbtcElectrumUrl,
        boltzUrl: boltzUrl,
      );

      final swapSensitive = res.createSwapSensitiveFromChainSwap();

      //SwapTxSensitive.fromBtcLnSwap(res);
      final err = await _secureStorage.saveValue(
        key: StorageKeys.swapTxSensitive + '_' + res.id,
        value: jsonEncode(swapSensitive.toJson()),
      );
      if (err != null) throw err;
      final swap = res.createSwapFromChainSwap(toWalletId, onChainSwapType);
      // SwapTx.fromBtcLnSwap(res);

      return (swap, null);
    } catch (e) {
      return (null, Err(e.toString()));
    }
  }
}
