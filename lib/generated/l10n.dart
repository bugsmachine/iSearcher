// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `iSearcher`
  String get app_title {
    return Intl.message(
      'iSearcher',
      name: 'app_title',
      desc: '',
      args: [],
    );
  }

  /// `Unrecorded files`
  String get unrecorded_title {
    return Intl.message(
      'Unrecorded files',
      name: 'unrecorded_title',
      desc: '',
      args: [],
    );
  }

  /// `Current folder: `
  String get current_folder {
    return Intl.message(
      'Current folder: ',
      name: 'current_folder',
      desc: '',
      args: [],
    );
  }

  /// `File detected: `
  String get file_detected {
    return Intl.message(
      'File detected: ',
      name: 'file_detected',
      desc: '',
      args: [],
    );
  }

  /// `Size: `
  String get size {
    return Intl.message(
      'Size: ',
      name: 'size',
      desc: '',
      args: [],
    );
  }

  /// `Last Modified time: `
  String get last_modified_time {
    return Intl.message(
      'Last Modified time: ',
      name: 'last_modified_time',
      desc: '',
      args: [],
    );
  }

  /// `Edit file detail`
  String get edit_file_detail {
    return Intl.message(
      'Edit file detail',
      name: 'edit_file_detail',
      desc: '',
      args: [],
    );
  }

  /// `File name`
  String get file_name {
    return Intl.message(
      'File name',
      name: 'file_name',
      desc: '',
      args: [],
    );
  }

  /// `File path`
  String get file_path {
    return Intl.message(
      'File path',
      name: 'file_path',
      desc: '',
      args: [],
    );
  }

  /// `Select file type`
  String get select_file_type {
    return Intl.message(
      'Select file type',
      name: 'select_file_type',
      desc: '',
      args: [],
    );
  }

  /// `Movie poster`
  String get movie_poster {
    return Intl.message(
      'Movie poster',
      name: 'movie_poster',
      desc: '',
      args: [],
    );
  }

  /// `Subtitle: `
  String get subtitle {
    return Intl.message(
      'Subtitle: ',
      name: 'subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Overview: `
  String get overview {
    return Intl.message(
      'Overview: ',
      name: 'overview',
      desc: '',
      args: [],
    );
  }

  /// `Genres:`
  String get genres {
    return Intl.message(
      'Genres:',
      name: 'genres',
      desc: '',
      args: [],
    );
  }

  /// `Tags: `
  String get tags {
    return Intl.message(
      'Tags: ',
      name: 'tags',
      desc: '',
      args: [],
    );
  }

  /// `Main cast: `
  String get main_cast {
    return Intl.message(
      'Main cast: ',
      name: 'main_cast',
      desc: '',
      args: [],
    );
  }

  /// `Edit overview`
  String get edit_overview {
    return Intl.message(
      'Edit overview',
      name: 'edit_overview',
      desc: '',
      args: [],
    );
  }

  /// `Add a new genre`
  String get add_genre {
    return Intl.message(
      'Add a new genre',
      name: 'add_genre',
      desc: '',
      args: [],
    );
  }

  /// `Add a new tag`
  String get add_tag {
    return Intl.message(
      'Add a new tag',
      name: 'add_tag',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get save {
    return Intl.message(
      'Save',
      name: 'save',
      desc: '',
      args: [],
    );
  }

  /// `Submit`
  String get submit {
    return Intl.message(
      'Submit',
      name: 'submit',
      desc: '',
      args: [],
    );
  }

  /// `Movie`
  String get movie {
    return Intl.message(
      'Movie',
      name: 'movie',
      desc: '',
      args: [],
    );
  }

  /// `TV Show`
  String get tv_show {
    return Intl.message(
      'TV Show',
      name: 'tv_show',
      desc: '',
      args: [],
    );
  }

  /// `Video`
  String get video {
    return Intl.message(
      'Video',
      name: 'video',
      desc: '',
      args: [],
    );
  }

  /// `Delete poster`
  String get delete_poster {
    return Intl.message(
      'Delete poster',
      name: 'delete_poster',
      desc: '',
      args: [],
    );
  }

  /// `Upload subtitle`
  String get upload_subtitle {
    return Intl.message(
      'Upload subtitle',
      name: 'upload_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Search`
  String get search {
    return Intl.message(
      'Search',
      name: 'search',
      desc: '',
      args: [],
    );
  }

  /// `Search subtitle`
  String get search_subtitle {
    return Intl.message(
      'Search subtitle',
      name: 'search_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Searching movie detail...`
  String get searching_movie_detail {
    return Intl.message(
      'Searching movie detail...',
      name: 'searching_movie_detail',
      desc: '',
      args: [],
    );
  }

  /// `Loading...`
  String get loading {
    return Intl.message(
      'Loading...',
      name: 'loading',
      desc: '',
      args: [],
    );
  }

  /// `Loading overview...`
  String get loading_overview {
    return Intl.message(
      'Loading overview...',
      name: 'loading_overview',
      desc: '',
      args: [],
    );
  }

  /// `Loading genres...`
  String get loading_genres {
    return Intl.message(
      'Loading genres...',
      name: 'loading_genres',
      desc: '',
      args: [],
    );
  }

  /// `Loading tags...`
  String get loading_tags {
    return Intl.message(
      'Loading tags...',
      name: 'loading_tags',
      desc: '',
      args: [],
    );
  }

  /// `Loading main cast...`
  String get loading_main_cast {
    return Intl.message(
      'Loading main cast...',
      name: 'loading_main_cast',
      desc: '',
      args: [],
    );
  }

  /// `User score`
  String get user_score {
    return Intl.message(
      'User score',
      name: 'user_score',
      desc: '',
      args: [],
    );
  }

  /// `Click to view `
  String get click_to_view {
    return Intl.message(
      'Click to view ',
      name: 'click_to_view',
      desc: '',
      args: [],
    );
  }

  /// `'s profile`
  String get s_profile {
    return Intl.message(
      '\'s profile',
      name: 's_profile',
      desc: '',
      args: [],
    );
  }

  /// `Group: `
  String get group {
    return Intl.message(
      'Group: ',
      name: 'group',
      desc: '',
      args: [],
    );
  }

  /// `Add a new group`
  String get add_new_group {
    return Intl.message(
      'Add a new group',
      name: 'add_new_group',
      desc: '',
      args: [],
    );
  }

  /// `Manage groups`
  String get manage_group {
    return Intl.message(
      'Manage groups',
      name: 'manage_group',
      desc: '',
      args: [],
    );
  }

  /// `Fitters: `
  String get fitters {
    return Intl.message(
      'Fitters: ',
      name: 'fitters',
      desc: '',
      args: [],
    );
  }

  /// `Custom `
  String get custom {
    return Intl.message(
      'Custom ',
      name: 'custom',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'zh'),
      Locale.fromSubtags(languageCode: 'zh', countryCode: 'TW'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
