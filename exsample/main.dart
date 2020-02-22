import 'package:flutter/material.dart';
import 'package:reorderwrap/reorder_wrap.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reorder Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Reorder Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Widget> _icons = <Widget>[
    Container(
      child: GestureDetector(
        child: Container(height: 90, width: 90, color: Colors.red),
        onTap: () {
          debugPrint("Tap!");
        },
      ),
    ),
    Container(height: 90, width: 90, color: Colors.blue),
    Container(height: 90, width: 90, color: Colors.purple),
    Container(height: 90, width: 90, color: Colors.blueGrey),
    Container(height: 90, width: 90, color: Colors.brown),
    Container(height: 90, width: 90, color: Colors.orange),
    Container(height: 90, width: 90, color: Colors.lime),
    Container(height: 90, width: 90, color: Colors.lightGreen),
    Container(height: 90, width: 90, color: Colors.pink),
    Container(height: 90, width: 90, color: Colors.lightGreenAccent),
    Container(height: 90, width: 90, color: Colors.yellow),
    // Container(height: 90, width: 90, color: Colors.deepPurple),
    // Container(height: 90, width: 90, color: Colors.black),
    // Container(height: 90, width: 90, color: Colors.cyan),
    // Container(height: 90, width: 90, color: Colors.deepOrange),
  ];
  List<int> _indexList;

  @override
  void initState() {
    super.initState();
    _indexList = List.generate(_icons.length, (i)=>i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          ReorderWrap(
            itemHeight: 90,
            itemWidth: 90,
            children: _icons,
            reorderCallback: (newIndexList, oldIndex, newIndex){
              setState(() {
                _indexList = newIndexList;
              });
            },
          ),
          Text(_indexList.toString(), 
            style: TextStyle(fontSize: 20)
          )
        ],
      ),
    );
  }
}
