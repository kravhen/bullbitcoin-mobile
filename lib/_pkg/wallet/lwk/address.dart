import 'package:bb_mobile/_model/address.dart';
import 'package:bb_mobile/_model/wallet.dart';
import 'package:bb_mobile/_pkg/error.dart';
import 'package:lwk_dart/lwk_dart.dart' as lwk;

class LWKAddress {
  Future<(String?, Err?)> peekIndex(lwk.Wallet lwkWallet, int idx) async {
    try {
      final address = await lwkWallet.addressAtIndex(idx);
      return (address.confidential, null);
    } on Exception catch (e) {
      return (
        null,
        Err(
          e.message,
          title: 'Error occurred while getting address',
          solution: 'Please try again.',
        )
      );
    }
  }

  Future<(Wallet?, Err?)> loadLiquidAddresses({
    required Wallet wallet,
    required lwk.Wallet lwkWallet,
  }) async {
    try {
      final addressLastUnused = await lwkWallet.lastUnusedAddress();

      final List<Address> addresses = [...wallet.myAddressBook];

      for (var i = 0; i <= addressLastUnused.index; i++) {
        final address = await lwkWallet.addressAtIndex(i);
        final contain = wallet.myAddressBook.where(
          (element) => element.address == address.standard,
        );
        if (contain.isEmpty)
          addresses.add(
            Address(
              address: address.standard,
              confidential: address.confidential,
              index: address.index,
              kind: AddressKind.deposit,
              state: AddressStatus.unused,
            ),
          );
      }
      // Future.delayed(const Duration(milliseconds: 1600));
      addresses.sort((a, b) {
        final int indexA = a.index ?? 0;
        final int indexB = b.index ?? 0;
        return indexB.compareTo(indexA);
      });

      Wallet w;

      if (wallet.lastGeneratedAddress == null ||
          addressLastUnused.index >= wallet.lastGeneratedAddress!.index!)
        w = wallet.copyWith(
          myAddressBook: addresses,
          lastGeneratedAddress: Address(
            address: addressLastUnused.standard,
            confidential: addressLastUnused.confidential,
            index: addressLastUnused.index,
            kind: AddressKind.deposit,
            state: AddressStatus.unused,
          ),
        );
      else
        w = wallet.copyWith(
          myAddressBook: addresses,
        );
      return (w, null);
    } on Exception catch (e) {
      return (
        null,
        Err(
          e.message,
          title: 'Error occurred while loading addresses',
          solution: 'Please try again.',
        )
      );
    }
  }
}