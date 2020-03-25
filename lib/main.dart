import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui/flutter_firebase_ui.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hari Store',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Hari Project'),
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
  int _cindex = 0;
  final gkey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final _pages = <Widget>[
      HomePage(),
      CategoryPage(),
      OtherPage(),
    ];

    final _pageItem = <BottomNavigationBarItem>[
      BottomNavigationBarItem(icon: Icon(Icons.home), title: Text("Home")),
      BottomNavigationBarItem(
          icon: Icon(Icons.category), title: Text("Categories")),
      BottomNavigationBarItem(icon: Icon(Icons.list), title: Text("Others")),
    ];

    final bottomNavBar = BottomNavigationBar(
      items: _pageItem,
      currentIndex: _cindex,
      type: BottomNavigationBarType.fixed,
      onTap: (int index) {
        setState(() {
          _cindex = index;
        });
      },
    );

    return Scaffold(
      key: gkey,
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.shopping_basket),
            onPressed: () {},
          ),
          PopupMenuButton(
            itemBuilder: (BuildContext ctx) {
              return [
                PopupMenuItem(
                  child: Text("Profile"),
                ),
                PopupMenuItem(
                  child: Text("Settings"),
                )
              ];
            },
          )
        ],
      ),
      body: _pages[_cindex],
      bottomNavigationBar: bottomNavBar,
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance.collection('item').snapshots(),
        builder: (BuildContext ctx, AsyncSnapshot<QuerySnapshot> sst) {
          if (sst.hasError) return Text('Error: ${sst.hasError}');
          switch (sst.connectionState) {
            case ConnectionState.waiting:
              return Center(child: Text('Loading...'));
            default:
              return GridView.count(
                crossAxisCount: 2,
                children: sst.data.documents.map((DocumentSnapshot ds) {
                  String imgsrc = ds['img'];
                  return GridTile(
                    child:  Column(
                        children: <Widget>[
                          Expanded(
                            flex: 2,
                            child: Image.network(
                              imgsrc,
                              fit: BoxFit.cover,
                            ),
                          )
                        ],
                      ),
                    footer: Container(
                      color: Colors.grey,
                        child: ListTile(
                    leading: Text(
                      ds['title'],
                      style: TextStyle(color: Colors.white),
                    ),
                  )),
                  );
                }).toList(),
              );
          }
        },
      ),
    );
  }
}

class CategoryPage extends StatefulWidget {
  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Text("Categories"),
      ),
    );
  }
}

class OtherPage extends StatefulWidget {
  @override
  _OtherPageState createState() => _OtherPageState();
}

class _OtherPageState extends State<OtherPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Text("Others"),
      ),
    );
  }
}
