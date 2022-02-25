import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:enawra/screens/view_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:enawra/models/post.dart';
import 'package:enawra/pages/profile.dart';
import 'package:enawra/utils/firebase.dart';
import 'package:enawra/widgets/indicators.dart';
import 'package:enawra/widgets/userpost.dart';

class Timeline extends StatefulWidget {
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  List<DocumentSnapshot> post = [];

  bool isLoading = false;

  bool hasMore = true;

  int documentLimit = 50;

  DocumentSnapshot lastDocument;

  ScrollController _scrollController;

  getPosts() async {
    if (!hasMore) {
      print('No New Posts');
    }
    if (isLoading) {
      return CircularProgressIndicator();
    }
    setState(() {
      isLoading = true;
    });
    QuerySnapshot querySnapshot;

    List<dynamic> f;

    await followingRef.doc(firebaseAuth.currentUser.uid).get()
    .then((value) => {
      if(value.exists) {
        f = value['following'],
        f.add(currentUserId())
      }
    });

    print("heloollolllo");

    if (lastDocument == null && f != null) {
      querySnapshot = await postRef
        .where("ownerId", whereIn: f)
          .orderBy('timestamp', descending: true)
          .limit(documentLimit)
          .get();
    } else if (f != null){
      querySnapshot = await postRef
          .where("ownerId", whereIn: f)
          .orderBy('timestamp', descending: true)
          .startAfterDocument(lastDocument)
          .limit(documentLimit)
          .get();
    }

    if(querySnapshot != null) {
      if (querySnapshot.docs.length < documentLimit) {
        hasMore = false;
      }

      lastDocument = querySnapshot.docs[querySnapshot.docs.length - 1];
      post.addAll(querySnapshot.docs);
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    getPosts();
    _scrollController?.addListener(() {
      double maxScroll = _scrollController.position.maxScrollExtent;
      double currentScroll = _scrollController.position.pixels;
      double delta = MediaQuery.of(context).size.height * 0.25;
      if (maxScroll - currentScroll <= delta) {
        getPosts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'enawra',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              CupertinoIcons.profile_circled,
              size: 30.0,
              color: Theme.of(context).colorScheme.secondary,
            ),
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => Profile(profileId: firebaseAuth.currentUser.uid),
                ),
              );
            },
          ),
          SizedBox(width: 20.0),
        ],
      ),
      body: isLoading
          ? circularProgress(context)
          : ListView.builder(
              controller: _scrollController,
              itemCount: post.length,
              itemBuilder: (context, index) {
                internetChecker(context);
                PostModel posts = PostModel.fromJson(post[index].data());
                return Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: UserPost(post: posts),
                );
              },
            ),
    );
  }

  internetChecker(context) async {
    bool result = await DataConnectionChecker().hasConnection;
    if (result == false) {
      showInSnackBar('No Internet Connection', context);
    }
  }

  void showInSnackBar(String value, context) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}
