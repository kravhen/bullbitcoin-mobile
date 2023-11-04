// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_SettingsState _$$_SettingsStateFromJson(Map<String, dynamic> json) =>
    _$_SettingsState(
      unitsInSats: json['unitsInSats'] as bool? ?? false,
      notifications: json['notifications'] as bool? ?? false,
      privacyView: json['privacyView'] as bool? ?? false,
      currency: json['currency'] == null
          ? null
          : Currency.fromJson(json['currency'] as Map<String, dynamic>),
      currencyList: (json['currencyList'] as List<dynamic>?)
          ?.map((e) => Currency.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastUpdatedCurrency: json['lastUpdatedCurrency'] == null
          ? null
          : DateTime.parse(json['lastUpdatedCurrency'] as String),
      loadingCurrency: json['loadingCurrency'] as bool? ?? false,
      errLoadingCurrency: json['errLoadingCurrency'] as String? ?? '',
      reloadWalletTimer: json['reloadWalletTimer'] as int? ?? 20,
      language: json['language'] as String?,
      languageList: (json['languageList'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      loadingLanguage: json['loadingLanguage'] as bool? ?? false,
      errLoadingLanguage: json['errLoadingLanguage'] as String? ?? '',
      fees: json['fees'] as int?,
      feesList:
          (json['feesList'] as List<dynamic>?)?.map((e) => e as int).toList(),
      selectedFeesOption: json['selectedFeesOption'] as int? ?? 2,
      tempFees: json['tempFees'] as int?,
      tempSelectedFeesOption: json['tempSelectedFeesOption'] as int?,
      feesSaved: json['feesSaved'] as bool? ?? false,
      loadingFees: json['loadingFees'] as bool? ?? false,
      errLoadingFees: json['errLoadingFees'] as String? ?? '',
      defaultRBF: json['defaultRBF'] as bool? ?? true,
    );

Map<String, dynamic> _$$_SettingsStateToJson(_$_SettingsState instance) =>
    <String, dynamic>{
      'unitsInSats': instance.unitsInSats,
      'notifications': instance.notifications,
      'privacyView': instance.privacyView,
      'currency': instance.currency,
      'currencyList': instance.currencyList,
      'lastUpdatedCurrency': instance.lastUpdatedCurrency?.toIso8601String(),
      'loadingCurrency': instance.loadingCurrency,
      'errLoadingCurrency': instance.errLoadingCurrency,
      'reloadWalletTimer': instance.reloadWalletTimer,
      'language': instance.language,
      'languageList': instance.languageList,
      'loadingLanguage': instance.loadingLanguage,
      'errLoadingLanguage': instance.errLoadingLanguage,
      'fees': instance.fees,
      'feesList': instance.feesList,
      'selectedFeesOption': instance.selectedFeesOption,
      'tempFees': instance.tempFees,
      'tempSelectedFeesOption': instance.tempSelectedFeesOption,
      'feesSaved': instance.feesSaved,
      'loadingFees': instance.loadingFees,
      'errLoadingFees': instance.errLoadingFees,
      'defaultRBF': instance.defaultRBF,
    };
