import 'package:flutter/material.dart';

class SettingView extends StatefulWidget {
  const SettingView({super.key});

  @override
  _SettingViewState createState() => _SettingViewState();
}

class _SettingViewState extends State<SettingView> {
  late ScrollController _scrollController;
  bool _isAppBarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification is ScrollUpdateNotification) {
            // This listens for scroll updates and updates the collapsed state
            setState(() {
              _isAppBarCollapsed = _scrollController.offset > 0;
            });
          }
          return true;
        },
        child: CustomScrollView(
          controller: _scrollController, // Attach ScrollController
          slivers: <Widget>[
            SliverAppBar(
              expandedHeight: 70.0, // Height when expanded
              floating: false,
              pinned: true, // AppBar stays pinned when collapsed
              centerTitle: true,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.white,
              title: AnimatedOpacity(
                opacity: _isAppBarCollapsed
                    ? 1.0
                    : 0.0, // Title opacity based on collapsed state
                duration: Duration(milliseconds: 300),
                child: Text(
                  "Settings", // Title text when collapsed
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: AnimatedOpacity(
                  opacity: _isAppBarCollapsed
                      ? 0.0
                      : 1.0, // Title opacity when expanded
                  duration: Duration(milliseconds: 300),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          "Settings", // Title text when expanded
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Content after the SliverAppBar
            SliverToBoxAdapter(
              child: Container(
                color: Colors.amber,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text("Body content goes here",
                          style: TextStyle(fontSize: 18)),
                    )
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: Colors.amber,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text("Body content goes here",
                          style: TextStyle(fontSize: 18)),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
