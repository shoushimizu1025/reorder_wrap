# reorderwrap

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# Demo
This Widget adds Wrap to the Reorder function.
Rearrange the arrangement of multiple widgets and call back the final order, original index, and new index.
However, the conditions of the Widget list that can be used are all limited to those of the same vertical and horizontal width.

# Usage
ReorderWrap uses a list widget as an argument, similar to Wrap.
The Widget element specified as a child starts sorting in LongPress.
Please refer to the sample provided in main.dart.
```Dart
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
```
itemHeight
Height of one child Widget.

itemWidth
Width of one child Widget.

children
Widget list as child element.

reorderCallback
You can get indexlist, oldindex, newindex after sorting.