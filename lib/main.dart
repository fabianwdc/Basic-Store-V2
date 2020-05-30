import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui/flutter_firebase_ui.dart';
import 'package:firebase_ui/l10n/localization.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() => runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hari Store',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home:MyHomePage(title: 'Hari Project'),
      localizationsDelegates:[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FFULocalizations.delegate,
      ] ,
      supportedLocales:[
        const Locale('fr', 'FR'),
        const Locale('en', 'US'),
        const Locale('de', 'DE'),
        const Locale('pt', 'BR'),
        const Locale('es', 'MX'),
      ] ,
    )
);

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _cindex = 0;
  int _cind = 0;
  final gkey = GlobalKey<ScaffoldState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<FirebaseUser> _listener;
  FirebaseUser _currentUser;
  Firestore store = Firestore.instance;
  String addr="";
  String pho="";
  String vno="";

  String addr2="";
  String pho2="";
  String vno2="";

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  @override
  void dispose() {
    _listener.cancel();
    super.dispose();
  }

  void _checkCurrentUser() async {
    _currentUser = await _auth.currentUser();
    _currentUser?.getIdToken(refresh: true);

    _listener = _auth.onAuthStateChanged.listen((FirebaseUser user) {
      setState(() {
        _currentUser = user;
      });
    });
  }

  void _logout() {
    signOutProviders();
  }

  @override
  Widget build(BuildContext context) {
    final _pages = <Widget>[
      HomePage(_currentUser),
      CategoryPage(_currentUser),
      OtherPage(_currentUser),
    ];

    final _pageadd = <Widget>[
      AdOrderPage(),
      AdItemsPage(),
      AddItemPage()
    ];

    final _pageItem = <BottomNavigationBarItem>[
      BottomNavigationBarItem(
          icon: Icon(Icons.home),
          title: Text("Home")
      ),
      BottomNavigationBarItem(
          icon: Icon(Icons.category),
          title: Text("Categories")
      ),
      BottomNavigationBarItem(
          icon: Icon(Icons.list),
          title: Text("Others")
      ),
    ];

    final _adpageItem = <BottomNavigationBarItem>[
      BottomNavigationBarItem(
          icon: Icon(Icons.store),
          title: Text("Orders")
      ),
      BottomNavigationBarItem(
          icon: Icon(Icons.lightbulb_outline),
          title: Text("Products")
      ),
      BottomNavigationBarItem(
          icon: Icon(Icons.add),
          title: Text("Add Item")
      ),
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

    final addbottomNavBar = BottomNavigationBar(
      items: _adpageItem,
      currentIndex: _cind,
      type: BottomNavigationBarType.fixed,
      onTap: (int index) {
        setState(() {
          _cind = index;
        });
      },
    );

    if (_currentUser == null) {
      return SignInScreen(
        title: "Welcome",
        header: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Sign In"),
          ),
        ),
        showBar: true,
        bottomPadding: 5,
        avoidBottomInset: true,
        color: Color(0xFF363636),
        providers: [
          ProvidersTypes.email,
        ],
        twitterConsumerKey: "",
        twitterConsumerSecret: "",
        horizontalPadding: 12,
      );
    } else {

      if(_currentUser.email ==''){
        return Scaffold(
          appBar: AppBar(
            title: Text("Admin Panel"),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.power_settings_new),
                onPressed: (){
                  _logout();
                },
              ),
            ],
          ),
          body: _pageadd[_cind],
          bottomNavigationBar: addbottomNavBar,
        );
      }else{
        return Scaffold(
          key: gkey,
          appBar: AppBar(
            title: Text(widget.title),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.shopping_basket),
                onPressed: () {
                  showModalBottomSheet(context: context,
                      builder: (context){
                        Firestore.instance.collection("UserData").document(_currentUser.uid).snapshots()
                            .listen((event) {
                          if(event.data != null){
                            event.data.forEach((key, value) {
                              if(key.toString() =="add"){
                                if(value.toString() != ''){
                                  setState(() {
                                    addr2 = value.toString();
                                  });
                                }
                              }
                              if(key.toString() =="phone"){
                                if(value.toString() != ''){
                                  setState(() {
                                    pho2 = value.toString();
                                  });
                                }
                              }
                              if(key.toString() =="vno"){
                                if(value.toString() != ''){
                                  setState(() {
                                    vno2 = value.toString();
                                  });
                                }
                              }
                            });
                          }
                        });
                        return Column(
                          children: <Widget>[
                            Container(
                                height: 70,
                                child: Center(
                                  child: Text("Cart",textAlign: TextAlign.center,) ,
                                )
                            ),
                            Divider(thickness: 2,),
                            Expanded(
                                child:StreamBuilder<QuerySnapshot>(
                                  stream: Firestore.instance.collection('UserData').document(_currentUser.uid).collection("cart").snapshots(),
                                  builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                                    if (snapshot.hasError)
                                      return new Text('Error: ${snapshot.error}');
                                    switch (snapshot.connectionState) {
                                      case ConnectionState.waiting: return new Text('Loading...');
                                      default:
                                        return new ListView(
                                          children: snapshot.data.documents.map((DocumentSnapshot document) {
                                            return new ListTile(
                                              title: new Text(document['pitt']),
                                            );
                                          }).toList(),
                                        );
                                    }
                                  },
                                )
                            ),
                            Container(
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: FlatButton(
                                      child: Text("Clear"),
                                      onPressed: (){
                                        Firestore.instance.collection('UserData').document(_currentUser.uid).collection("cart")
                                            .getDocuments()
                                            .then((value){
                                          for (DocumentSnapshot ds in value.documents){
                                            ds.reference.delete();
                                          }
                                        }).whenComplete(() => Navigator.pop(context));
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: FlatButton(
                                        child: Text("Buy"),
                                        onPressed: (){
                                          String orederid=Uuid().v4();
                                          DateTime now = DateTime.now();
                                          String formattedDate = DateFormat('kkmmss').format(now);
                                          String finalord = formattedDate+'-'+orederid.substring(0,8);

                                          Firestore.instance.collection('AllOrders').document(finalord).setData(
                                              {
                                                'uid':_currentUser.uid,
                                                'oid':finalord,
                                                'placed': now,
                                                'add': addr2,
                                                'pno':pho2,
                                                'vno':vno2
                                              }
                                          );

                                          int b;
                                          Firestore.instance.collection('UserData').document(_currentUser.uid)
                                              .collection('cart')
                                              .getDocuments()
                                              .then((value) {
                                            b=0;
                                            for(DocumentSnapshot ds in value.documents){
                                              Firestore.instance.collection('AllOrders').document(finalord).collection('prods').document()
                                                  .setData({
                                                'title':ds['pitt'].toString(),
                                                'pid':ds['pid'].toString(),
                                                'prc':ds['prc'].toString()
                                              });
                                              String vari =ds['prc'].toString();
                                              b = b + int.parse(vari);
                                            }
                                            Firestore.instance.collection('AllOrders').document(finalord)
                                                .updateData({
                                              'prc':b.toString()
                                            });
                                          });

                                          Firestore.instance.collection('UserData').document(_currentUser.uid)
                                              .collection('orders').document(finalord).setData(
                                              {
                                                'oid':finalord,
                                                'placed': now,
                                                'add': addr2,
                                                'pno':pho2,
                                                'vno':vno2
                                              }
                                          );

                                          int a;
                                          Firestore.instance.collection('UserData').document(_currentUser.uid)
                                              .collection('cart')
                                              .getDocuments()
                                              .then((value) {
                                            a=0;
                                            for(DocumentSnapshot ds in value.documents){
                                              Firestore.instance.collection('UserData').document(_currentUser.uid)
                                                  .collection('orders').document(finalord).collection('prods').document()
                                                  .setData({
                                                'title':ds['pitt'].toString(),
                                                'pid':ds['pid'].toString(),
                                                'prc':ds['prc'].toString()
                                              });
                                              String vari =ds['prc'].toString();
                                              a = a + int.parse(vari);
                                            }
                                            Firestore.instance.collection('UserData').document(_currentUser.uid)
                                                .collection('orders').document(finalord)
                                                .updateData({
                                              'prc':a.toString()
                                            });
                                          }).whenComplete(() {
                                            Firestore.instance.collection('UserData').document(_currentUser.uid).collection("cart")
                                                .getDocuments()
                                                .then((value){
                                              for (DocumentSnapshot ds in value.documents){
                                                ds.reference.delete();
                                              }
                                            }).whenComplete(() => Navigator.pop(context));
                                          });
                                        }
                                    ),
                                  )
                                ],
                              ),
                            )
                          ],
                        );
                      }
                  );
                },
              ),
              PopupMenuButton(
                onSelected: (x){
                  if (x=="logout"){
                    _logout();
                  }
                },
                itemBuilder: (BuildContext ctx) {
                  return [
                    PopupMenuItem(
                      child: Text("Log Out"),
                      value: "logout" ,
                    )
                  ];
                },
              )
            ],
          ),
          body: _pages[_cindex],
          bottomNavigationBar: bottomNavBar,
        );
      }
    }
  }
}

class HomePage extends StatefulWidget {

  FirebaseUser us;

  HomePage(this.us);
  @override
  _HomePageState createState() => _HomePageState(this.us);
}

class _HomePageState extends State<HomePage> {

  FirebaseUser us;
  _HomePageState(this.us);

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
                  String pid = ds['iid'];
                  String cat = ds['cat'];
                  String prc = ds['prc'];
                  String desc = ds['desc'];
                  String title= ds['title'];
                  String imgsrc = ds['img'];
                  return InkResponse(
                    onTap: (){
                      Navigator.push(context, _DetailsPG(title, imgsrc,prc,desc,pid,cat,us));
                    },
                      enableFeedback: true,
                      child:GridTile(
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
                      title,
                      style: TextStyle(color: Colors.white),
                    ),
                  )),
                  ));
                }).toList(),
              );
          }
        },
      ),
    );
  }
}

class CategoryPage extends StatefulWidget {

  FirebaseUser us;

  CategoryPage(this.us);

  @override
  _CategoryPageState createState() => _CategoryPageState(this.us);
}

class _CategoryPageState extends State<CategoryPage> {

  FirebaseUser us;

  _CategoryPageState(this.us);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: ListView(
          children: <Widget>[
            ExpansionTile(
              title:Text("Two Wheeler") ,
              children: <Widget>[
                ListTile(
                  title: Text("Lights"),
                  onTap: (){
                    String cat = "twl";
                    Navigator.push(context, _CatLisPage(us, cat));
                  },
                ),
                ListTile(
                  title: Text("Battery"),
                  onTap: (){
                    String cat = "twb";
                    Navigator.push(context, _CatLisPage(us, cat));
                  },
                )
              ],
            ),
            ExpansionTile(
              title:Text("Four Wheeler") ,
              children: <Widget>[
                ListTile(
                  title: Text("Lights"),
                  onTap: (){
                    String cat = "fwl";
                    Navigator.push(context, _CatLisPage(us, cat));
                  },
                ),
                ListTile(
                  title: Text("Battery"),
                  onTap: (){
                    String cat = "fwb";
                    Navigator.push(context, _CatLisPage(us, cat));
                  },
                ),
                ListTile(
                  title: Text("Wheel Hub"),
                  onTap: (){
                    String cat = "fwwh";
                    Navigator.push(context, _CatLisPage(us, cat));
                  },
                ),
                ListTile(
                  title: Text("Steering Cover"),
                  onTap: (){
                    String cat = "fwsc";
                    Navigator.push(context, _CatLisPage(us, cat));
                  },
                ),
                ListTile(
                  title: Text("Gear Knob"),
                  onTap: (){
                    String cat = "fwgk";
                    Navigator.push(context, _CatLisPage(us, cat));
                  },
                ),
                ListTile(
                  title: Text("Audio System"),
                  onTap: (){
                    String cat = "fwas";
                    Navigator.push(context, _CatLisPage(us, cat));
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class OtherPage extends StatefulWidget {
  FirebaseUser us;

  OtherPage(this.us);

  @override
  _OtherPageState createState() => _OtherPageState(this.us);
}

class _OtherPageState extends State<OtherPage> {

  FirebaseUser us;

  _OtherPageState(this.us);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Column(
          children: <Widget>[
            ListTile(
              title: Text("Orders"),
              onTap: (){
                Navigator.push(context, _OrderLis(us));
              },
            ),
            ListTile(
              title: Text("Profile"),
              onTap: (){
                Navigator.push(context, _ProfPG(us));
              },
            )
          ],
        ),
      ),
    );
  }
}

class _DetailsPG extends MaterialPageRoute<Null>{

  String title;
  String img;
  String prc;
  String desc;
  String pid;
  String cat;
  String addr="";
  FirebaseUser us;

  _DetailsPG(this.title,this.img,this.prc,this.desc,this.pid,this.cat,this.us):super(builder:(BuildContext context){
    return DetailsPage(title,img,prc,desc,pid,cat,us);
  });
}

class DetailsPage extends StatefulWidget {

  String title;
  String img;
  String prc;
  String desc;
  String pid;
  String cat;
  String addr="";
  FirebaseUser us;

  DetailsPage(this.title,this.img,this.prc,this.desc,this.pid,this.cat,this.us);

  @override
  _DetailsPageState createState() => _DetailsPageState(this.title,this.img,this.prc,this.desc,this.pid,this.cat,this.us);
}

class _DetailsPageState extends State<DetailsPage> {

  String title;
  String img;
  String prc;
  String desc;
  String pid;
  String cat;
  String addr="";
  String pho="";
  String vno="";
  FirebaseUser us;

  _DetailsPageState(this.title,this.img,this.prc,this.desc,this.pid,this.cat,this.us);

  @override
  Widget build(BuildContext context) {

    Firestore.instance
        .collection('UserData')
        .document(us.uid)
        .get()
        .then((DocumentSnapshot ds) {
          setState(() {
            addr = ds['add'].toString();
          });
    });

    Firestore.instance
        .collection('UserData')
        .document(us.uid)
        .get()
        .then((DocumentSnapshot ds) {
          setState(() {
            pho = ds['phone'].toString();
          });
    });

    Firestore.instance
        .collection('UserData')
        .document(us.uid)
        .get()
        .then((DocumentSnapshot ds) {
      setState(() {
        vno = ds['vno'].toString();
      });
    });

    return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              flex: 2,
              child: ListView(
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child:  Image.network(
                      img,
                      fit: BoxFit.cover,
                    ) ,
                  ),
                  Divider(thickness: 3,),
                  ListTile(
                    title: Text("₹$prc"),
                  ),
                  ListTile(
                    title: Text(title),
                  ),
                  ListTile(
                    title: Text(desc),
                  )
                ],
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: FlatButton(
                    child: Text("Add To Cart"),
                    onPressed: (){
                      Firestore.instance.collection("UserData").document(us.uid).collection("cart").document().setData(
                          {
                            'pid':pid,
                            'prc':prc,
                            'pitt':title
                          }
                      ).whenComplete(() => Navigator.pop(context));
                    },
                  ),
                ),
                Expanded(
                  child: FlatButton(
                    child: Text("Buy"),
                    onPressed: (){
                      String orederid=Uuid().v4();
                      DateTime now = DateTime.now();
                      String formattedDate = DateFormat('kkmmss').format(now);
                      String finalord = formattedDate+'-'+orederid.substring(0,8);

                      Firestore.instance
                          .collection('UserData')
                          .document(us.uid)
                          .get()
                          .then((DocumentSnapshot ds) {
                        setState(() {
                          addr = ds['add'].toString();
                        });
                      });

                      Firestore.instance
                          .collection('UserData')
                          .document(us.uid)
                          .get()
                          .then((DocumentSnapshot ds) {
                        setState(() {
                          pho = ds['phone'].toString();
                        });
                      });

                      Firestore.instance
                          .collection('UserData')
                          .document(us.uid)
                          .get()
                          .then((DocumentSnapshot ds) {
                        setState(() {
                          vno = ds['vno'].toString();
                        });
                      });

                      Firestore.instance.collection('AllOrders').document(finalord).setData(
                          {
                            'uid':us.uid,
                            'oid':finalord,
                            'placed': now,
                            'prc': prc,
                            'add': addr,
                            'pno':pho,
                            'vno':vno
                          }
                      );

                      Firestore.instance.collection('AllOrders').document(finalord).collection('prods').document()
                          .setData(
                          {
                            'title':title,
                            'pid':pid,
                            'prc': prc
                          }
                      );

                      Firestore.instance.collection('UserData').document(us.uid)
                          .collection('orders').document(finalord).setData(
                          {
                            'oid':finalord,
                            'placed': now,
                            'prc': prc,
                            'add': addr,
                            'pno':pho,
                            'vno':vno
                          }
                      );

                      Firestore.instance.collection('UserData').document(us.uid)
                          .collection('orders').document(finalord).collection('prods').document()
                          .setData(
                          {
                            'title':title,
                            'pid':pid,
                            'prc': prc
                          }
                      ).whenComplete(() => Navigator.pop(context));
                    },
                  ),
                ),
              ],
            ),
          ],
        )
    );
  }
}

class _ProfPG extends MaterialPageRoute<Null>{

  FirebaseUser us;
  
  _ProfPG(this.us):super(builder: (BuildContext context){

    return ProfilePage(us) ;
  });
}

class ProfilePage extends StatefulWidget {
  FirebaseUser us;

  ProfilePage(this.us);

  @override
  _ProfilePageState createState() => _ProfilePageState(us);
}

class _ProfilePageState extends State<ProfilePage> {

  FirebaseUser us;
  _ProfilePageState(this.us);

  String addres = "";
  String pho = "";
  String vhno = "";
  Firestore fs = Firestore.instance;

  @override
  Widget build(BuildContext context) {
    fs.collection("UserData").document(us.uid).snapshots()
        .listen((event) {
          if (event.data != null){
            event.data.forEach((key, value) {
              if(key.toString()=="add"){
                if(value.toString() != ''){
                  setState(() {
                    addres = value.toString();
                  });
                }
              }
              if(key.toString()=="phone"){
                if(value.toString() != ''){
                  setState(() {
                    pho = value.toString();
                  });
                }
              }
              if(key.toString()=="vno"){
                if( value.toString() != ''){
                  setState(() {
                    vhno = value.toString();});
                }
              }
            });
          }
    });

    return Scaffold(
        appBar: AppBar(
          title: Text("Profile"),
        ),
        body: Column(
          children: <Widget>[
            ListTile(
              title: us.displayName != null ? Text(us.displayName):Text("User"),
            ),
            ListTile(
              title: addres != "" ? Text(addres):Text("Address"),
              subtitle: Text("Address"),
            ),
            ListTile(
              title: pho !="" ? Text(pho):Text("Phone Number"),
              subtitle: Text("Phone Number"),
            ),
            ListTile(
              title: vhno !=""? Text(vhno):Text("Vehichle Number"),
              subtitle: Text("Vehichle Number"),
            ),
            Expanded(
              child:FlatButton(
                child: Text("Update Address"),
                onPressed: (){
                  Navigator.push(context, UpAdPage(us));
                },
              )
            )
          ],
        )
    );
  }
}

class _OrderLis extends MaterialPageRoute<Null>{

  FirebaseUser us;

  _OrderLis(this.us):super(builder: (BuildContext context){

    return OrdLisPage(us) ;
  });
}

class OrdLisPage extends StatefulWidget {

  FirebaseUser us;

  OrdLisPage(this.us);

  @override
  _OrdLisPageState createState() => _OrdLisPageState(this.us);
}

class _OrdLisPageState extends State<OrdLisPage> {

  FirebaseUser us;

  _OrdLisPageState(this.us);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Orders"),
      ),
      body:Container(
        child: StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance.collection('UserData').document(us.uid).collection('orders').snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError)
              return Text('Error: ${snapshot.error}');
            switch (snapshot.connectionState) {
              case ConnectionState.waiting: return Text('Loading...');
              default:
                return ListView(
                  children: snapshot.data.documents.map((DocumentSnapshot ds) {
                    Timestamp ts = ds['placed'];
                    DateTime dtvar = ts.toDate();
                    return ListTile(
                      title: Text(ds['oid']),
                      subtitle: Text("Ordered On:  "+dtvar.toString()),
                      onTap: (){
                        showModalBottomSheet(context: context,
                            builder:(context){
                              return Container(
                                child: Column(
                                  children: <Widget>[
                                    Expanded(
                                      child: ListView(
                                        children: <Widget>[
                                          ListTile(
                                            title: Text(ds['oid']),
                                            subtitle: Text("OrderID"),
                                          ),
                                          ListTile(
                                            title: Text("₹ "+ds['prc']),
                                            subtitle: Text("Price"),
                                          ),
                                          ListTile(
                                            title: Text(ds['add']),
                                            subtitle: Text("Address"),
                                          ),
                                          ListTile(
                                            title:  Text(ds['pno']),
                                            subtitle: Text("Phone"),
                                          ),
                                          ListTile(
                                            title: Text(ds['vno']),
                                            subtitle: Text("Vehicle Number"),
                                          ),
                                          ListTile(
                                            title: Text(dtvar.toString()),
                                            subtitle: Text("Order Placed On"),
                                          ),
                                        ],
                                      ),
                                    ),

                                    Expanded(
                                      child: StreamBuilder<QuerySnapshot>(
                                        stream: Firestore.instance.collection('UserData').document(us.uid).collection('orders').document(ds['oid'].toString()).collection('prods').snapshots(),
                                        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                                          if (snapshot.hasError)
                                            return Text('Error: ${snapshot.error}');
                                          switch (snapshot.connectionState) {
                                            case ConnectionState.waiting: return Text('Loading...');
                                            default:
                                              return ListView(
                                                children: snapshot.data.documents.map((DocumentSnapshot document) {
                                                  return ListTile(
                                                    title: Text(document['title']),
                                                    subtitle: Text("₹ "+document['prc']),
                                                  );
                                                }).toList(),
                                              );
                                          }
                                        },
                                      ),
                                    )
                                  ],
                                ),
                              );
                            }
                        );
                      },
                    );
                  }).toList(),
                );
            }
          },
        ),
      ) ,
    );
  }
}

class _CatLisPage extends MaterialPageRoute<Null>{

  FirebaseUser us;
  String cat;

  _CatLisPage(this.us,this.cat):super(builder: (BuildContext context){

    return CatPage(us,cat) ;
  });
}

class CatPage extends StatefulWidget {

  FirebaseUser us;
  String cat;

  CatPage(this.us,this.cat);

  @override
  _CatPageState createState() => _CatPageState(this.us,this.cat);
}

class _CatPageState extends State<CatPage> {

  FirebaseUser us;
  String cat;

  _CatPageState(this.us,this.cat);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Result"),
      ),
      body:Container(
        child: StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance.collection('item').where('cat',isEqualTo: cat).snapshots(),
          builder: (BuildContext ctx, AsyncSnapshot<QuerySnapshot> sst) {
            if (sst.hasError) return Text('Error: ${sst.hasError}');
            switch (sst.connectionState) {
              case ConnectionState.waiting:
                return Center(child: Text('Loading...'));
              default:
                return GridView.count(
                  crossAxisCount: 2,
                  children: sst.data.documents.map((DocumentSnapshot ds) {
                    String pid = ds['iid'];
                    String cat = ds['cat'];
                    String prc = ds['prc'];
                    String desc = ds['desc'];
                    String title= ds['title'];
                    String imgsrc = ds['img'];
                    return InkResponse(
                        onTap: (){
                          Navigator.push(context, _DetailsPG(title, imgsrc,prc,desc,pid,cat,us));
                        },
                        enableFeedback: true,
                        child:GridTile(
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
                                  title,
                                  style: TextStyle(color: Colors.white),
                                ),
                              )),
                        ));
                  }).toList(),
                );
            }
          },
        ),
      ),
    );
  }
}

class AdOrderPage extends StatefulWidget {
  @override
  _AdOrderPageState createState() => _AdOrderPageState();
}

class _AdOrderPageState extends State<AdOrderPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Container(
        child: StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance.collection('AllOrders').snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError)
              return Text('Error: ${snapshot.error}');
            switch (snapshot.connectionState) {
              case ConnectionState.waiting: return Text('Loading...');
              default:
                return ListView(
                  children: snapshot.data.documents.map((DocumentSnapshot ds) {
                    Timestamp ts = ds['placed'];
                    DateTime dtvar = ts.toDate();
                    return ListTile(
                      title: Text(ds['oid']),
                      subtitle: Text("Ordered On:  "+dtvar.toString()),
                      onTap: (){
                        showModalBottomSheet(context: context,
                            builder:(context){
                              return Container(
                                child: Column(
                                  children: <Widget>[
                                    Expanded(
                                      child: ListView(
                                        children: <Widget>[
                                          ListTile(
                                            title: Text(ds['uid']),
                                            subtitle: Text("OrderID"),
                                          ),
                                          ListTile(
                                            title: Text(ds['oid']),
                                            subtitle: Text("User ID"),
                                          ),
                                          ListTile(
                                            title: Text(ds['uid']),
                                            subtitle: Text("User ID"),
                                          ),
                                          ListTile(
                                            title: Text("₹ "+ds['prc']),
                                            subtitle: Text("Price"),
                                          ),
                                          ListTile(
                                            title: Text(ds['add']),
                                            subtitle: Text("Address"),
                                          ),
                                          ListTile(
                                            title:  Text(ds['pno']),
                                            subtitle: Text("Phone"),
                                          ),
                                          ListTile(
                                            title: Text(ds['vno']),
                                            subtitle: Text("Vehicle Number"),
                                          ),
                                          ListTile(
                                            title: Text(dtvar.toString()),
                                            subtitle: Text("Order Placed On"),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: StreamBuilder<QuerySnapshot>(
                                        stream: Firestore.instance.collection('AllOrders').document(ds['oid'].toString()).collection('prods').snapshots(),
                                        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                                          if (snapshot.hasError)
                                            return Text('Error: ${snapshot.error}');
                                          switch (snapshot.connectionState) {
                                            case ConnectionState.waiting: return Text('Loading...');
                                            default:
                                              return ListView(
                                                children: snapshot.data.documents.map((DocumentSnapshot document) {
                                                  return ListTile(
                                                    title: Text(document['title']),
                                                    subtitle: Text("₹ "+document['prc']),
                                                  );
                                                }).toList(),
                                              );
                                          }
                                        },
                                      ),
                                    )
                                  ],
                                ),
                              );
                            }
                        );
                      },
                    );
                  }).toList(),
                );
            }
          },
        ),
      )
    );
  }
}

class AdItemsPage extends StatefulWidget {
  @override
  _AdItemsPageState createState() => _AdItemsPageState();
}

class _AdItemsPageState extends State<AdItemsPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child:StreamBuilder<QuerySnapshot>(
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
                  String pid = ds['iid'];
                  String cat = ds['cat'];
                  String prc = ds['prc'];
                  String desc = ds['desc'];
                  String title= ds['title'];
                  String imgsrc = ds['img'];
                  return InkResponse(
                      onTap: (){
                        showModalBottomSheet(context: context,
                            builder: (context){
                              return Container(
                                child: Column(
                                  children: <Widget>[
                                    Expanded(
                                      child: ListView(
                                        children: <Widget>[
                                          ListTile(
                                            title: Text(title),
                                            subtitle: Text("Title"),
                                          ),
                                          ListTile(
                                            title: Text(pid),
                                            subtitle: Text("PID"),
                                          ),
                                          ListTile(
                                            title: Text("₹ "+prc),
                                            subtitle: Text("Price"),
                                          ),
                                          ListTile(
                                            title: Text(desc),
                                            subtitle: Text("Description"),
                                          ),
                                          ListTile(
                                            title: Text(cat),
                                            subtitle: Text("Category"),
                                          ),
                                          ListTile(
                                            title: Text(imgsrc),
                                            subtitle: Text("Image URL"),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              );
                            }
                        );
                      },
                      enableFeedback: true,
                      child:GridTile(
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
                                title,
                                style: TextStyle(color: Colors.white),
                              ),
                            )),
                      ));
                }).toList(),
              );
          }
        },
      ),
    );
  }
}

class AddItemPage extends StatefulWidget {

  @override
  _AddItemPageState createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {

  String pid="";
  String tit="";
  String desc="";
  String prc="";
  String cat="";
  String imgurl="";
  Firestore store = Firestore.instance;
  File _img ;

  Future<void> _pickImg() async{
    File selected = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      _img= selected;
    });
  }

  Future<void> _upImg() async{
    FirebaseStorage fs = FirebaseStorage.instance;
    if (pid != null && prc != null && tit != null && cat != null && desc != null && _img != null){
      String filepath = '${DateTime.now()}.png';
      StorageReference sr = fs.ref().child(filepath);
      StorageUploadTask sult = sr.putFile(_img);
      StreamSubscription<StorageTaskEvent> ss = sult.events.listen((event) {
        print('EVENT ${event.type}');
      });
      await sult.onComplete;
      StorageTaskSnapshot  ts = await sult.onComplete;
      String downUrl = await ts.ref.getDownloadURL();
      if(sult.isComplete){
        Firestore.instance.collection('item').document()
            .setData({
          'cat':cat,
          'desc':desc,
          'iid':pid,
          'img':downUrl,
          'prc':prc,
          'title':tit
        }).whenComplete(() =>
            Navigator.pop(context)
        );
      }
      ss.cancel();
    } else{
      Scaffold.of(context)
          .showSnackBar(SnackBar(
        content: Text("Complete The Info"),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListView(
        children: <Widget>[
          ListTile(
            title: Text("Add Item"),
          ),
          Expanded(
            child: _img == null ? Center(child: Text("Select An Image"),):Image.file(_img),
          ),
          TextField(
            decoration: InputDecoration.collapsed(hintText: 'Title'),
            onChanged: (a){
              tit=a;
            },
          ),
          Divider(thickness: 1,),
          TextField(
            decoration: InputDecoration.collapsed(hintText: 'Description'),
            onChanged: (a){
              desc = a;
            },
          ),
          Divider(thickness: 1,),
          TextField(
            decoration: InputDecoration.collapsed(hintText: 'Category'),
            onChanged: (a){
              cat = a;
            },
          ),
          Divider(thickness: 1,),
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration.collapsed(hintText: 'Price'),
            onChanged: (a){
              prc=a;
            },
          ),
          Divider(thickness: 1,),
          TextField(
            decoration: InputDecoration.collapsed(hintText: 'Item ID'),
            onChanged: (a){
              pid = a;
            },
          ),
          Divider(thickness: 1,),
          Expanded(
            child: FlatButton(
              child: Text("Select Image"),
              onPressed: (){
                _pickImg();
              },
            ),
          ),
          Expanded(
              child:FlatButton(
                child: Text("Add Item"),
                onPressed: (){
                 _upImg();
                },
              )
          ),
        ],
      ),
    );
  }
}

class UpAdPage extends MaterialPageRoute<Null>{

  FirebaseUser us;

  UpAdPage(this.us):super(builder: (BuildContext context){

    return UpAddScaff(us) ;
  });
}

class UpAddScaff extends StatefulWidget {

  FirebaseUser us;

  UpAddScaff(this.us);

  @override
  _UpAddScaffState createState() => _UpAddScaffState(us);
}

class _UpAddScaffState extends State<UpAddScaff> {

  FirebaseUser us;
  String add="";
  String pho="";
  String vno="";

  _UpAddScaffState(this.us);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Update Address"),
      ),
      body: ListView(
        children: [
          TextField(
            decoration: InputDecoration.collapsed(hintText: 'Address'),
            onChanged: (a){
              add=a;
            },
          ),
          TextField(
            decoration: InputDecoration.collapsed(hintText: 'Phone'),
            keyboardType: TextInputType.phone,
            onChanged: (a){
              pho = a;
            },
          ),
          TextField(
            decoration: InputDecoration.collapsed(hintText: 'Vehicle Number'),
            onChanged: (a){
              vno = a;
            },
          ),
          Expanded(
            child: FlatButton(
              child: Text("Update Address"),
              onPressed: (){
                if(add != "" && pho != "" && vno !=""){
                  Firestore.instance.collection("UserData").document(us.uid).setData({
                          'add':add,
                          'phone':pho,
                          'vno':vno
                        }).whenComplete(() => Navigator.pop(context));

                }else{
                  showDialog(
                      context: context,
                      builder: (BuildContext bc) {
                        return AlertDialog(
                          title: Text("Alert"),
                          content: Text("Complete Everything"),
                        );
                      });
                }
              },
            ),
          )
        ],
      ),
    );
  }
}
