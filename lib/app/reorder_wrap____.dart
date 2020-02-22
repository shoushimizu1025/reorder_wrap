import 'package:flutter/material.dart';

/// コールバック
typedef ReorderCallback = void Function(List<Widget>, List<int>);
/// コールバック
typedef ReorderContentCallback = void Function(List<Widget>, List<int>);



/// Widget縦横並べ替え可能Wrap
/// 複数のWidgetの配置を並べ替えて結果をコールバックする
/// ただし、使用できるWidgetリストの条件は、全て同じ縦横幅のものとする
class ReorderWrap extends StatefulWidget {

  ReorderWrap({
    Key key,
    @required this.children,
    @required this.reorderCallback,
    @required this.height,
    @required this.width
  }) : super(key: key);

  /// 並べ替え後のWidgetListとIndexListを取得できる
  final ReorderCallback reorderCallback;
  /// Widgetリスト
  final List<Widget> children;
  /// Widget１つ分の縦幅
  final double height;
  /// Widget１つ分の横幅
  final double width;

  @override
  _ReorderWrapState createState() => _ReorderWrapState();
}

class _ReorderWrapState extends State<ReorderWrap> {

  GlobalKey _globalKey = GlobalKey();

  /// Widgetリスト
  List<Widget> _items;
  /// WidgetList１つ分の縦幅
  double _itemHeight;
  /// WidgetList１つ分の横幅
  double _itemWidth;
  /// ドラッグラップ有効化フラグ
  bool _dragWrapFlag;

  @override
  void initState() {
    super.initState();
    _items = widget.children;
    _itemWidth = widget.width;
    _itemHeight = widget.height;
    _dragWrapFlag = false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: _dragOrNomalWidget(),
      )
    );
  }

  Widget _dragOrNomalWidget() {
    // ドラッグラップにラッピングして返す
    return _ReorderWrapContent(
      height: _itemHeight,
      width: _itemWidth,
      reorderWrapModeFlag: _dragWrapFlag,
      children: _items,
      reorderContentCallback: (newItemList, newIndexList){
        debugPrint('');
        widget.reorderCallback(newItemList, newIndexList);
        setState(() {
          _dragWrapFlag = false;
        });
      },
    );
  }
}

/// ReorderWrap機能本体
class _ReorderWrapContent extends StatefulWidget {

  _ReorderWrapContent({
    Key key,
    @required this.children,
    @required this.reorderContentCallback,
    @required this.height,
    @required this.width,
    @required this.reorderWrapModeFlag,
  }) : super(key: key);

  /// ReorderWrapモードフラグ
  final bool reorderWrapModeFlag;
  /// 並べ替え後のWidgetListとIndexListを取得できる
  final ReorderContentCallback reorderContentCallback;
  /// Widgetリスト
  final List<Widget> children;
  /// Widget１つ分の縦幅
  final double height;
  /// Widget１つ分の横幅
  final double width;

  @override
  _ReorderWrapContentState createState() => _ReorderWrapContentState();
}

class _ReorderWrapContentState extends State<_ReorderWrapContent> {

  GlobalKey _globalKey = GlobalKey();

  /// reorderモードフラグ
  bool _reorderWrapModeFlag;
  /// 並べ替え成功フラグ
  bool _isSuccessful = false;
  /// Widgetインデックスリスト
  List<int> _itemIndex;
  /// Widgetリスト
  List<Widget> _items;
  /// Animation
  Duration _itemMoveDuration;
  //List<Offset> _beginningItemPosition;
  List<Offset> _currentItemPosition;
  /// ドラッグ中のリアルタイムIndex
  int _draggingIndex;
  /// ドラッグ中のパターン保持
  String _dragPattern;
  /// WidgetList１つ分の縦幅
  double _itemHeight;
  /// WidgetList１つ分の横幅
  double _itemWidth;
  /// （アニメーション計算用）移動行の切り替わった各行のIndex値保持
  List<int> _rowChangeIndexs;
  /// 移動行の切り替わった各行のIndex値リスト初期化フラグ
  bool _rowChangeIndexsInitFlag = false;

  @override
  void initState() {
    super.initState();
    _reorderWrapModeFlag = widget.reorderWrapModeFlag;
    _items = widget.children;
    _itemWidth = widget.width;
    _itemHeight = widget.height;
    _initAnimationContent();
  }

  /// アニメーション初期化
  void _initAnimationContent() {
    _itemMoveDuration = Duration(milliseconds: 0);
    _draggingIndex = 0;
    _dragPattern = "";
    _rowChangeIndexsInitFlag = false;
    _itemIndex = List.generate(_items.length, (i)=>i);
    _currentItemPosition = List.generate(
      _items.length, (i)=>Offset.zero
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: _reorderWrapModeFlag? _dragWrap() : _wrap(),
      )
    );
  }

  Widget _dragWrap() {
    return Wrap(
      key: _globalKey,
      children: List<Widget>.generate(
        _items.length,
        _dragTargetWrap
      ),
    );
  }

  Widget _wrap() {
    return Wrap(
      key: _globalKey,
      children: List.generate(
        _items.length,
        _longPressWrap
      ),
    );
  }

  Widget _longPressWrap(int index) {
    return GestureDetector(
      child: _items[index],
      onLongPress: () {
        
      },
    );
  }

  Widget _animatedContainerWrap(int index) {
    return AnimatedContainer(
      duration: _itemMoveDuration,
      transform: _itemMoveTransform(index),
      child: _draggableWrap(index),
    );
  }

  Matrix4 _itemMoveTransform(int index) {
    return Matrix4.translationValues(
      _currentItemPosition[index].dx,
      _currentItemPosition[index].dy,
      0.0
    );
  }

  /// Widgetの移動アニメーション処理
  void _moveItems(int oldIndex, int newIndex, int originallIndex) {
    /// アニメーションスピード
    _itemMoveDuration = Duration(milliseconds: 100);
    /// ドラッグパターン
    const String patternNext = "Next";
    const String patternPreview = "Preview";
    const String patternNeutral = "Neutral";
    /// reorderWidget全体の大きさ取得
    final Size reorderWidgetSize = _globalKey.currentContext.size;
    /// 最大カラム数
    final int maxColumn = (reorderWidgetSize.width / _itemWidth).floor();
    /// 最大行数
    final int maxRow = (_items.length / maxColumn).ceil();
    /// （計算用）特定のIndexが配置されている行数
    int currentRow;
    /// （計算用）特定のIndexが配置されている行の最小Index
    int currentMinIndex;
    /// （計算用）特定のIndexが配置されている行の最大Index
    int currentMaxIndex;
    /// （計算用）行間移動時のループ条件Index
    int loopIndex;
    /// （計算用）行間移動時のループ終了条件Index
    int loopEndIndex;
    /// 移動させるWidgetのデータ
    int itemIndex;
    /// 次の座標値X
    double nextX;
    /// 次の座標値Y
    double nextY;

    // 行状態リスト初期化
    if (_rowChangeIndexsInitFlag == false) {
      _rowChangeIndexs = List.generate(maxRow, (i)=>0);
      _rowChangeIndexsInitFlag = true;
    }

    // 移動パターン設定
    if (_dragPattern == "") {
      if (oldIndex < newIndex) {
        _dragPattern = patternNext;
      }
      if (oldIndex > newIndex) {
        _dragPattern = patternPreview;
      }
      if (_dragPattern == "") {
        _dragPattern = patternNeutral;
      }
    }
    debugPrint(_dragPattern);

    setState(() {
      // 右１左１右１＋左１＋の４パターンのうち、当てはまる動作を
      // 設定する
      // 右１************************************************************
      if ((oldIndex < newIndex) && ((newIndex - oldIndex) == 1)) {
        itemIndex = newIndex;
        if (_dragPattern == patternPreview) {
          itemIndex = oldIndex;
        }
        if ((oldIndex < originallIndex) && (oldIndex < newIndex)) {
          itemIndex = oldIndex;
        }
        if ((oldIndex >= originallIndex) && (_dragPattern == patternPreview)) {
          itemIndex = newIndex;
        }
        // 座標設定
        if (_currentItemPosition[itemIndex].dx == 0.0) {
          nextX = 0.0 - _itemWidth;
          nextY = 0.0;
        } else {
          nextX = 0.0;
          nextY = 0.0;
        }
        _currentItemPositionChange(itemIndex, nextX, nextY);
      }

      // 左１************************************************************
      if ((newIndex < oldIndex) && ((oldIndex - newIndex) == 1)) {
        itemIndex = newIndex;
        if (_dragPattern == patternNext) {
          itemIndex = oldIndex;
        }
        if ((oldIndex > originallIndex) && (oldIndex > newIndex)) {
          itemIndex = oldIndex;
        }
        if ((oldIndex <= originallIndex) && (_dragPattern == patternNext)) {
          itemIndex = newIndex;
        }
        // 座標設定
        if (_currentItemPosition[itemIndex].dx == 0.0) {
          nextX = 0.0 + _itemWidth;
          nextY = 0.0;
        } else {
          nextX = 0.0;
          nextY = 0.0;
        }
        _currentItemPositionChange(itemIndex, nextX, nextY);
      }

      // 右１＋（上段から下段移動含む）************************************************************
      if ((oldIndex < newIndex) && ((newIndex - oldIndex) > 1)) {
        // newIndexがある行の情報を取得
        currentRow = ((newIndex + 1) / maxColumn).ceil();
        // newIndexがある行の最大Index値
        currentMaxIndex = ((maxColumn * currentRow) - 1);
        // newIndexがある行の最小Index値
        currentMinIndex = currentMaxIndex - (maxColumn - 1);
        // ループ開始Index値設定
        loopIndex = newIndex;
        // ループ終了Index値設定
        loopEndIndex = oldIndex;
        // 左移動→下行移動
        if ((_dragPattern == patternPreview) && 
            (currentRow == (((oldIndex + 1) / maxColumn).ceil() + 1))) {
          loopIndex = newIndex;
          // 移動する先が動いているか
          if ((_rowChangeIndexs[currentRow - 1] == 1) &&
              (_currentItemPosition[newIndex].dx != 0.0)) {
            loopIndex = newIndex - 1;
            _rowChangeIndexs[currentRow - 1] = 0;
          }
        }
        // 右移動→下行移動
        if ((_dragPattern == patternNext) && 
            (currentRow == (((oldIndex + 1) / maxColumn).ceil() + 1)) &&
            (newIndex < currentMaxIndex)) {
          loopIndex = newIndex;
          // 移動する先が動いているか
          if ((_rowChangeIndexs[currentRow - 1] == 1) &&
              (_currentItemPosition[newIndex].dx != 0.0)) {
            loopIndex = newIndex - 1;
            _rowChangeIndexs[currentRow - 1] = 0;
          }
        }
        // 行末尾から下行末尾へ移動（元行が移動済の場合）
        if ((oldIndex == ((maxColumn * ((oldIndex + 1) / maxColumn).ceil()) - 1) &&
            (_currentItemPosition[oldIndex].dx == (_itemWidth * -1)))) {
          loopEndIndex = oldIndex + 1;
        }
        // 行末尾から下行末尾へ移動2（元行が移動済の場合）
        if ((oldIndex == ((maxColumn * ((oldIndex + 1) / maxColumn).ceil()) - 1) &&
            (_currentItemPosition[oldIndex].dy != 0.0))) {              
          loopEndIndex = oldIndex;
        }
        // 右移動→下行移動(行末尾値点)
        if ((_dragPattern == patternNext) &&
            (currentRow == (((oldIndex + 1) / maxColumn).ceil() + 1)) &&
            (newIndex == currentMaxIndex) &&
            (_currentItemPosition[newIndex].dy != 0.0)) {
              debugPrint('うらうら');
          loopIndex = newIndex - 1;
          loopEndIndex = oldIndex;
        }
        
        // 移動が発生するWidget分だけループ処理
        for (int i = loopIndex; i >= loopEndIndex; i--) {
          itemIndex = i;
          if (i == currentMinIndex) {
            // 行先頭は上の行へ
            nextX = reorderWidgetSize.width - _itemWidth;
            nextY = 0.0 - _itemHeight;
            // 行の移動を記録
            _rowChangeIndexs[((oldIndex) / maxColumn).floor()] = 1;
          } else {
            // 移動
            nextX = 0.0 - _itemWidth;
            nextY = 0.0;
          }
          if (_currentItemPosition[i].dx != 0.0) {
            // 移動しているアイテムは元の位置に戻す
            nextX = 0.0;
            nextY = 0.0;
          }
          if ((i == oldIndex) && 
              (_dragPattern == patternNext) && 
              (_currentItemPosition[i].dx != _itemWidth) &&
              (_currentItemPosition[i].dy == 0.0) &&
              (loopIndex != currentMaxIndex)) {
            // 右移動→下行移動時の前位置
            nextX = _currentItemPosition[i].dx;
            nextY = _currentItemPosition[i].dy;
          }
          if ((i == oldIndex) && 
              (_dragPattern == patternPreview) && 
              (_currentItemPosition[i].dx != _itemWidth) &&
              (_currentItemPosition[i].dy == 0.0)) {
            // 左移動→下行移動時の前位置
            nextX = _currentItemPosition[i].dx;
            nextY = _currentItemPosition[i].dy;
          }
          _currentItemPositionChange(itemIndex, nextX, nextY);
        }
      }

      // 左１＋（下段から上段移動含む）************************************************************
      if ((newIndex < oldIndex) && ((oldIndex - newIndex) > 1)) {
        // newIndexがある行の情報を取得
        currentRow = ((newIndex + 1) / maxColumn).ceil();
        // newIndexがある行の最大Index値
        currentMaxIndex = ((maxColumn * currentRow) - 1);
        // newIndexがある行の最小Index値
        currentMinIndex = currentMaxIndex - (maxColumn - 1);
        // ループ開始Index値設定
        loopIndex = newIndex;
        // ループ終了Index値設定
        loopEndIndex = oldIndex;
        // 右移動→上行移動
        if ((_dragPattern == patternNext) && 
            (currentRow == (((oldIndex + 1) / maxColumn).ceil() - 1))) {
          loopIndex = newIndex;
          // 移動する先が動いているか
          if ((_rowChangeIndexs[currentRow - 1] == 1) &&
              (_currentItemPosition[newIndex].dx != 0.0)) {
            loopIndex = newIndex + 1;
            _rowChangeIndexs[currentRow - 1] = 0;
          }
        }
        // 左移動→上行移動
        if ((_dragPattern == patternPreview) && 
            (currentRow == (((oldIndex + 1) / maxColumn).ceil() - 1)) &&
            (newIndex > currentMinIndex)) {
          loopIndex = newIndex;
          // 移動する先が動いているか
          if ((_rowChangeIndexs[currentRow - 1] == 1) &&
              (_currentItemPosition[newIndex].dx != 0.0)) {
            loopIndex = newIndex + 1;
            _rowChangeIndexs[currentRow - 1] = 0;
          }
        }
        // 行末尾から上行末尾へ移動（元行が移動済の場合）
        if ((oldIndex == ((maxColumn * ((oldIndex + 1) / maxColumn).ceil()) - 1) &&
            (_currentItemPosition[oldIndex].dy != 0.0))) {
          loopEndIndex = oldIndex - 1;
        }
        // 左移動→上行移動(行開始値点)
        if ((_dragPattern == patternPreview) &&
            (currentRow == (((oldIndex + 1) / maxColumn).ceil() - 1)) &&
            (newIndex == currentMinIndex) &&
            (_currentItemPosition[newIndex].dy != 0.0)) {
          loopIndex = newIndex + 1;
          loopEndIndex = oldIndex;
        }

        // 移動が発生するWidget分だけループ処理
        for (int i = loopIndex; i <= loopEndIndex; i ++) {
          itemIndex = i;
          // 行末尾は下の行へ
          if (i == currentMaxIndex) {
            nextX = (reorderWidgetSize.width - _itemWidth) * -1;
            nextY = 0.0 + _itemHeight;
            // 行の移動を記録
            _rowChangeIndexs[currentRow] = 1;
          } else {
            nextX = 0.0 + _itemWidth;
            nextY = 0.0;
          }
          if (_currentItemPosition[i].dx != 0.0) {
            // 移動しているアイテムは元の位置に戻す
            nextX = 0.0;
            nextY = 0.0;
          }
          if ((i == oldIndex) && 
              (_dragPattern == patternPreview) && 
              (_currentItemPosition[i].dx == _itemWidth)) {
            // 左移動→上行移動時の前位置
            nextX = _currentItemPosition[i].dx;
            nextY = _currentItemPosition[i].dy;
          }
          if ((i == oldIndex) && 
              (_dragPattern == patternNext) && 
              (_currentItemPosition[i].dx == _itemWidth)) {
            // 右移動→上行移動時の前位置
            nextX = _currentItemPosition[i].dx;
            nextY = _currentItemPosition[i].dy;
          }
          _currentItemPositionChange(itemIndex, nextX, nextY);
        }
      }
    });

    // 移動パターン設定
    if (oldIndex < newIndex) {
      _dragPattern = patternNext;
    }
    if (oldIndex > newIndex) {
      _dragPattern = patternPreview;
    }
  }

  /// Widgetポジションチェンジ処理
  /// 引数：対象WidgetのNo, X値, Y値
  void _currentItemPositionChange(int index, double x, double y) {
    _currentItemPosition[index] = Offset(x, y);
  }

  Widget _draggableWrap(int index) {
    return Draggable(
      data: index,
      // 元のwidget
      child: _items[index],
      // ドラッグ中のWidget
      feedback: _items[index],
      // ドラッグ中に表示させる元のWidget
      childWhenDragging: Container(
        height: _itemHeight,
        width: _itemWidth,
      ),
      // ドロップできなかった場合の処理
      onDraggableCanceled: (Velocity velocity, Offset offset) {
        setState((){
          _isSuccessful = false;
        });
      },
      // ドロップできた場合の処理
      onDragEnd: (DraggableDetails details) {
        debugPrint('成功');
        if(_isSuccessful) {
          debugPrint('変化あり');
          _isSuccessful = false;
          widget.reorderContentCallback(_items, _itemIndex);
        } else {
          debugPrint('変化なし');
        }
        _initAnimationContent();
      }
    );
  }

  Widget _dragTargetWrap(int index) {
    return DragTarget(
      builder: (
        BuildContext context,
        List<int> indexList,
        rejectedIndex,
      ){
        return _animatedContainerWrap(index);
      },
      onWillAccept: (int oldIndex) {
        //debugPrint('新しい場所');
        if (_dragPattern == '') {
          _draggingIndex = index;
        }
        _moveItems(_draggingIndex, index, oldIndex);
        _draggingIndex = index;
        return oldIndex != index;
      },
      onAccept: (int oldIndex) {
        //debugPrint('確定');
        _changeList(oldIndex, index);
        setState(() {
          _isSuccessful = true;
        });
      },
      onLeave: (e) {
        //debugPrint('元の場所');
      },
    );
  }

  /// 各リスト並べ替え処理
  /// 引数：元のインデックス, 新しいインデックス
  void _changeList(int oldIndex, int newIndex) {
    Widget escWidget = _items[oldIndex];
    int escIndex = _itemIndex[oldIndex];
    if (oldIndex < newIndex) {
      for (int i = oldIndex; i < newIndex; i ++) {
        _items[i] = _items[i + 1];
        _itemIndex[i] = _itemIndex[i + 1];
      }
    } else {
      for (int i = oldIndex; i > newIndex; i --) {
        _items[i] = _items[i - 1];
        _itemIndex[i] = _itemIndex[i - 1];
      }
    }
    _items[newIndex] = escWidget;
    _itemIndex[newIndex] = escIndex;
  }
}