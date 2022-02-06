library flutter_google_places_hoc081098.src;

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:http/http.dart';
import 'package:listenable_stream/listenable_stream.dart';
import 'package:rxdart_ext/state_stream.dart';

class PlacesAutocompleteWidget extends StatefulWidget {
  final String? apiKey;
  final Mode mode;
  final String? hint;

  final String? startText;
  final BorderRadius? overlayBorderRadius;
  final Location? location;
  final Location? origin;
  final num? offset;
  final num? radius;
  final String? language;
  final String? sessionToken;
  final List<String>? types;
  final List<Component>? components;
  final bool? strictbounds;
  final String? region;
  final Widget? logo;
  final ValueChanged<PlacesAutocompleteResponse>? onError;
  final Duration? debounce;
  final Map<String, String>? headers;

  /// This defines the space between the screen's edges and the dialog.
  /// This is only used in Mode.overlay.
  final EdgeInsets? insetPadding;
  final Widget? backArrowIcon;

  /// Decoration for search text field
  final InputDecoration? textDecoration;

  /// Text style for search text field
  final TextStyle? textStyle;

  final Color? cursorColor;

  /// optional - sets 'proxy' value in google_maps_webservice
  ///
  /// In case of using a proxy the baseUrl can be set.
  /// The apiKey is not required in case the proxy sets it.
  /// (Not storing the apiKey in the app is good practice)
  final String? proxyBaseUrl;

  /// optional - set 'client' value in google_maps_webservice
  ///
  /// In case of using a proxy url that requires authentication
  /// or custom configuration
  final Client? httpClient;

  PlacesAutocompleteWidget(
      {Key? key,
      required this.apiKey,
      this.mode = Mode.fullscreen,
      this.hint = 'Search',
      this.insetPadding,
      this.backArrowIcon,
      this.overlayBorderRadius,
      this.offset,
      this.location,
      this.origin,
      this.radius,
      this.language,
      this.sessionToken,
      this.types,
      this.components,
      this.strictbounds,
      this.region,
      this.logo,
      this.onError,
      this.proxyBaseUrl,
      this.httpClient,
      this.startText,
      this.debounce,
      this.headers,
      this.textDecoration,
      this.textStyle,
      this.cursorColor})
      : super(key: key) {
    if (apiKey == null && proxyBaseUrl == null) {
      throw ArgumentError(
          'One of `apiKey` and `proxyBaseUrl` fields is required');
    }
  }

  @override
  // ignore: no_logic_in_create_state
  State<PlacesAutocompleteWidget> createState() => mode == Mode.fullscreen
      ? _PlacesAutocompleteScaffoldState()
      : _PlacesAutocompleteOverlayState();

  static PlacesAutocompleteState of(BuildContext context) =>
      context.findAncestorStateOfType<PlacesAutocompleteState>()!;
}

class _PlacesAutocompleteScaffoldState extends PlacesAutocompleteState {
  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      title: AppBarPlacesAutoCompleteTextField(
        textDecoration: widget.textDecoration,
        textStyle: widget.textStyle,
        cursorColor: widget.cursorColor,
      ),
    );
    final body = PlacesAutocompleteResult(
      onTap: Navigator.of(context).pop,
      logo: widget.logo,
    );
    return Scaffold(appBar: appBar, body: body);
  }
}

class _PlacesAutocompleteOverlayState extends PlacesAutocompleteState {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final headerTopLeftBorderRadius =
        widget.overlayBorderRadius?.topLeft ?? const Radius.circular(2);

    final headerTopRightBorderRadius =
        widget.overlayBorderRadius?.topRight ?? const Radius.circular(2);

    final header = Column(children: <Widget>[
      Material(
          color: theme.dialogBackgroundColor,
          borderRadius: BorderRadius.only(
              topLeft: headerTopLeftBorderRadius,
              topRight: headerTopRightBorderRadius),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              IconButton(
                padding: const EdgeInsets.all(8.0).copyWith(top: 12.0),
                color: theme.brightness == Brightness.light
                    ? Colors.black45
                    : null,
                icon: _iconBack,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0, left: 10.0),
                  child: _textField(context),
                ),
              ),
            ],
          )),
      const Divider(),
    ]);

    final bodyBottomLeftBorderRadius =
        widget.overlayBorderRadius?.bottomLeft ?? const Radius.circular(2);

    final bodyBottomRightBorderRadius =
        widget.overlayBorderRadius?.bottomRight ?? const Radius.circular(2);

    final container = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 30.0),
      child: Stack(
        children: <Widget>[
          header,
          Padding(
            padding: const EdgeInsets.only(top: 48.0),
            child: StreamBuilder<_SearchState>(
              stream: _state$,
              initialData: _state$.value,
              builder: (context, snapshot) {
                final state = snapshot.requireData;
                final response = state.response;

                if (state.isSearching) {
                  return Stack(
                    alignment: FractionalOffset.bottomCenter,
                    children: <Widget>[_Loader()],
                  );
                } else if (state.text.isEmpty ||
                    response == null ||
                    response.predictions.isEmpty) {
                  return Material(
                    color: theme.dialogBackgroundColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: bodyBottomLeftBorderRadius,
                      bottomRight: bodyBottomRightBorderRadius,
                    ),
                    
                  );
                } else {
                  return SingleChildScrollView(
                    child: Material(
                      borderRadius: BorderRadius.only(
                        bottomLeft: bodyBottomLeftBorderRadius,
                        bottomRight: bodyBottomRightBorderRadius,
                      ),
                      color: theme.dialogBackgroundColor,
                      child: ListBody(
                        children: response.predictions
                            .map(
                              (p) => PredictionTile(
                                prediction: p,
                                onTap: Navigator.of(context).pop,
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );

    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return Padding(
          padding: widget.insetPadding ?? const EdgeInsets.only(top: 8.0),
          child: container);
    }

    return Padding(
      padding: widget.insetPadding ?? EdgeInsets.zero,
      child: container,
    );
  }

  Widget get _iconBack {
    if (widget.backArrowIcon != null) return widget.backArrowIcon!;
    return Theme.of(context).platform == TargetPlatform.iOS
        ? const Icon(Icons.arrow_back_ios)
        : const Icon(Icons.arrow_back);
  }

  Widget _textField(BuildContext context) => TextField(
        controller: _queryTextController,
        autofocus: true,
        style: TextStyle(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.black87
                : null,
            fontSize: 16.0),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.black45
                : null,
            fontSize: 16.0,
          ),
          border: InputBorder.none,
        ),
      );
}

class _Loader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 2.0),
      child: LinearProgressIndicator(
        color: Theme.of(context).colorScheme.secondary,
      ),
    );
  }
}

class PlacesAutocompleteResult extends StatelessWidget {
  final ValueChanged<Prediction> onTap;
  final Widget? logo;

  const PlacesAutocompleteResult(
      {Key? key, required this.onTap, required this.logo})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = PlacesAutocompleteWidget.of(context);

    return StreamBuilder<_SearchState>(
      stream: state._state$,
      initialData: state._state$.value,
      builder: (context, snapshot) {
        final state = snapshot.requireData;
        final response = state.response;

        if (state.text.isEmpty ||
            response == null ||
            response.predictions.isEmpty) {
          return Stack(
            children: [
              _Loader()
            ],
          );
        }
        return PredictionsListView(
          predictions: response.predictions,
          onTap: onTap,
        );
      },
    );
  }
}

class AppBarPlacesAutoCompleteTextField extends StatefulWidget {
  final InputDecoration? textDecoration;
  final TextStyle? textStyle;
  final Color? cursorColor;

  const AppBarPlacesAutoCompleteTextField({
    Key? key,
    required this.textDecoration,
    required this.textStyle,
    required this.cursorColor,
  }) : super(key: key);

  @override
  _AppBarPlacesAutoCompleteTextFieldState createState() =>
      _AppBarPlacesAutoCompleteTextFieldState();
}

class _AppBarPlacesAutoCompleteTextFieldState
    extends State<AppBarPlacesAutoCompleteTextField> {
  @override
  Widget build(BuildContext context) {
    final state = PlacesAutocompleteWidget.of(context);

    return Container(
        alignment: Alignment.topLeft,
        margin: const EdgeInsets.only(top: 2.0),
        child: TextField(
          controller: state._queryTextController,
          autofocus: true,
          style: widget.textStyle ?? _defaultStyle(),
          decoration:
              widget.textDecoration ?? _defaultDecoration(state.widget.hint),
          cursorColor: widget.cursorColor,
        ));
  }

  InputDecoration _defaultDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Theme.of(context).brightness == Brightness.light
          ? Colors.white30
          : Colors.black38,
      hintStyle: TextStyle(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.black38
            : Colors.white30,
        fontSize: 16.0,
      ),
      border: InputBorder.none,
    );
  }

  TextStyle _defaultStyle() {
    return TextStyle(
      color: Theme.of(context).brightness == Brightness.light
          ? Colors.black.withOpacity(0.9)
          : Colors.white.withOpacity(0.9),
      fontSize: 16.0,
    );
  }
}

class PoweredByGoogleImage extends StatelessWidget {
  final _poweredByGoogleWhite =
      'packages/flutter_google_places_hoc081098/assets/google_white.png';
  final _poweredByGoogleBlack =
      'packages/flutter_google_places_hoc081098/assets/google_black.png';

  const PoweredByGoogleImage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
      Padding(
          padding: const EdgeInsets.all(16.0),
          child: Image.asset(
            Theme.of(context).brightness == Brightness.light
                ? _poweredByGoogleWhite
                : _poweredByGoogleBlack,
            scale: 2.5,
          ))
    ]);
  }
}

class PredictionsListView extends StatelessWidget {
  final List<Prediction> predictions;
  final ValueChanged<Prediction> onTap;

  const PredictionsListView(
      {Key? key, required this.predictions, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: predictions
          .map((Prediction p) => PredictionTile(prediction: p, onTap: onTap))
          .toList(growable: false),
    );
  }
}

class PredictionTile extends StatelessWidget {
  final Prediction prediction;
  final ValueChanged<Prediction> onTap;

  const PredictionTile(
      {Key? key, required this.prediction, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.location_on),
      title: Text(prediction.description ?? ''),
      onTap: () => onTap(prediction),
    );
  }
}

enum Mode { overlay, fullscreen }

abstract class PlacesAutocompleteState extends State<PlacesAutocompleteWidget> {
  late final TextEditingController _queryTextController =
      TextEditingController(text: widget.startText)
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.startText?.length ?? 0,
        );

  late final StateConnectableStream<_SearchState> _state$;
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();

    _state$ = Rx.fromCallable(const GoogleApiHeaders().getHeaders)
        .exhaustMap(createGoogleMapsPlaces)
        .exhaustMap(
          (places) => _queryTextController
              .toValueStream(replayValue: true)
              .map((v) => v.text)
              .debounceTime(
                  widget.debounce ?? const Duration(milliseconds: 300))
              .where((s) => s.isNotEmpty)
              .distinct()
              .switchMap((s) => doSearch(s, places)),
        )
        .publishState(const _SearchState(false, null, ''));
    _subscription = _state$.connect();
  }

  Stream<GoogleMapsPlaces> createGoogleMapsPlaces(Map<String, String> headers) {
    assert(() {
      debugPrint('[flutter_google_places_hoc081098] headers=$headers');
      return true;
    }());

    return Rx.using(
      () => GoogleMapsPlaces(
        apiKey: widget.apiKey,
        baseUrl: widget.proxyBaseUrl,
        httpClient: widget.httpClient,
        apiHeaders: <String, String>{
          ...headers,
          ...?widget.headers,
        },
      ),
      (GoogleMapsPlaces places) =>
          Rx.never<GoogleMapsPlaces>().startWith(places),
      (GoogleMapsPlaces places) {
        assert(() {
          debugPrint('[flutter_google_places_hoc081098] disposed');
          return true;
        }());
        return places.dispose();
      },
    );
  }

  Stream<_SearchState> doSearch(String value, GoogleMapsPlaces places) async* {
    yield _SearchState(true, null, value);

    assert(() {
      debugPrint(
          '[flutter_google_places_hoc081098] input=$value location=${widget.location} origin=${widget.origin}');
      return true;
    }());

    try {
      final res = await places.autocomplete(
        value,
        offset: widget.offset,
        location: widget.location,
        radius: widget.radius,
        language: widget.language,
        sessionToken: widget.sessionToken,
        types: widget.types ?? const [],
        components: widget.components ?? const [],
        strictbounds: widget.strictbounds ?? false,
        region: widget.region,
        origin: widget.origin,
      );

      if (res.errorMessage?.isNotEmpty == true ||
          res.status == 'REQUEST_DENIED') {
        assert(() {
          debugPrint('[flutter_google_places_hoc081098] REQUEST_DENIED $res');
          return true;
        }());
        onResponseError(res);
      }

      yield _SearchState(
        false,
        PlacesAutocompleteResponse(
          status: res.status,
          errorMessage: res.errorMessage,
          predictions: _sorted(res.predictions),
        ),
        value,
      );
    } catch (e, s) {
      assert(() {
        debugPrint('[flutter_google_places_hoc081098] ERROR $e $s');
        return true;
      }());
      yield _SearchState(false, null, value);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _queryTextController.dispose();

    super.dispose();
  }

  @mustCallSuper
  void onResponseError(PlacesAutocompleteResponse res) {
    if (!mounted) return;
    widget.onError?.call(res);
  }

  @mustCallSuper
  void onResponse(PlacesAutocompleteResponse res) {}

  static List<Prediction> _sorted(List<Prediction> predictions) {
    if (predictions.isEmpty ||
        predictions.every((e) => e.distanceMeters == null)) {
      return predictions;
    }

    final sorted = predictions.sortedBy<num>((e) => e.distanceMeters ?? 0);

    assert(() {
      debugPrint(
          '[flutter_google_places_hoc081098] sorted=${sorted.map((e) => e.distanceMeters).toList(growable: false)}');
      return true;
    }());

    return sorted;
  }
}

class _SearchState {
  final String text;
  final bool isSearching;
  final PlacesAutocompleteResponse? response;

  const _SearchState(this.isSearching, this.response, this.text);

  @override
  String toString() =>
      '_SearchState{text: $text, isSearching: $isSearching, response: $response}';
}

abstract class PlacesAutocomplete {
  static Future<Prediction?> show(
      {required BuildContext context,
      required String? apiKey,
      Mode mode = Mode.fullscreen,
      String? hint = 'Search',
      BorderRadius? overlayBorderRadius,
      num? offset,
      Location? location,
      num? radius,
      String? language,
      String? sessionToken,
      List<String>? types,
      List<Component>? components,
      bool? strictbounds,
      String? region,
      Widget? logo,
      ValueChanged<PlacesAutocompleteResponse>? onError,
      String? proxyBaseUrl,
      Client? httpClient,
      String? startText,
      Duration? debounce,
      Location? origin,
      Map<String, String>? headers,
      InputDecoration? textDecoration,
      TextStyle? textStyle,
      Color? cursorColor,
      EdgeInsets? insetPadding,
      Widget? backArrowIcon}) {
    PlacesAutocompleteWidget builder(BuildContext context) =>
        PlacesAutocompleteWidget(
          apiKey: apiKey,
          mode: mode,
          overlayBorderRadius: overlayBorderRadius,
          language: language,
          sessionToken: sessionToken,
          components: components,
          types: types,
          location: location,
          radius: radius,
          strictbounds: strictbounds,
          region: region,
          offset: offset,
          hint: hint,
          logo: logo,
          onError: onError,
          proxyBaseUrl: proxyBaseUrl,
          httpClient: httpClient,
          startText: startText,
          debounce: debounce,
          origin: origin,
          headers: headers,
          textDecoration: textDecoration,
          textStyle: textStyle,
          cursorColor: cursorColor,
          insetPadding: insetPadding,
          backArrowIcon: backArrowIcon,
        );

    if (mode == Mode.overlay) {
      return showDialog<Prediction>(context: context, builder: builder);
    }
    return Navigator.push<Prediction>(
        context, MaterialPageRoute(builder: builder));
  }
}
