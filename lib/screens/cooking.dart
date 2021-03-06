import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nepali_food_recipes/components/flat_button.dart';
import 'package:nepali_food_recipes/components/snack_bar.dart';
import 'package:nepali_food_recipes/constants.dart';
import 'package:nepali_food_recipes/helpers/navigation.dart';
import 'package:nepali_food_recipes/helpers/screen_size.dart';
import 'package:nepali_food_recipes/providers/auth.dart';
import 'package:nepali_food_recipes/screens/nav_controller.dart';
import 'package:nepali_food_recipes/screens/profile.dart';
import 'package:nepali_food_recipes/screens/recipe_form.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timelines/timelines.dart';
import 'package:nepali_food_recipes/helpers/delete_recipe.dart';

class CookingScreen extends StatefulWidget {
  final QueryDocumentSnapshot? snapshot;
  CookingScreen({this.snapshot});

  @override
  _CookingScreenState createState() => _CookingScreenState();
}

class _CookingScreenState extends State<CookingScreen> {
  FirebaseFirestore _fireStore = FirebaseFirestore.instance;
  bool isAdmin = false;
  bool isOwnRecipe = false;
  List<IndicatorStyle> indicatorValues = [
    IndicatorStyle.outlined,
    IndicatorStyle.dot
  ];
  var recipeDetail;
  String foodName = 'Food Name';
  String cookingDuration = '30';
  String description = 'Taste of Asia';
  List ingredients = ['butter', 'chilli'];
  List steps = ['fry', ' cook it 15 minutes'];
  bool isVeg = false;
  String chefName = '';
  String? chefImage;
  String? imgUrl;
  String? chefID;
  int? views;
  String? docRefId;
  bool isSaved = false;
  @override
  void initState() {
    super.initState();
    recipeDetail = widget.snapshot;
    docRefId = widget.snapshot!.reference.id;
    // isAdmin = Provider.of<AuthProvider>(context, listen: false).isAdmin;
    chefID = recipeDetail['chefId'];
    foodName = recipeDetail['name'];
    cookingDuration = recipeDetail['duration'].toString();
    description = recipeDetail['description'];
    ingredients = recipeDetail['ingredients'];
    steps = recipeDetail['steps'];
    isVeg = recipeDetail['veg'];
    imgUrl = recipeDetail['photo'];
    chefName = recipeDetail['chef'];
    chefImage = recipeDetail['chefImage'];
    views = recipeDetail['views'];
    initializeIsAdminPrefs();

    checkIfAlreadySavedOrNot();
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();

    isThisRecipeBelongsToCurrentUser();
    increaseViewCount(docRefId!);
  }

  void initializeIsAdminPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('isAdmin') ?? false == true) {
      setState(() {
        isAdmin = true;
      });
    }
  }

  void isThisRecipeBelongsToCurrentUser() {
    if (recipeDetail['chefId'] ==
        Provider.of<AuthProvider>(context).auth.currentUser!.uid) {
      setState(() {
        isOwnRecipe = true;
      });
    }
  }

  void removeFromBookmark() {
    print('remove called');
    _fireStore
        .collection('users')
        .doc(Provider.of<AuthProvider>(context, listen: false)
            .auth
            .currentUser!
            .uid)
        .update({
      'saved': FieldValue.arrayRemove([docRefId])
    }).onError((error, stackTrace) {
      showSnackBar('Cannot remove from bookmark', context, Icons.error_outline);
    });

    setState(() {
      isSaved = false;
    });
  }

  void checkIfAlreadySavedOrNot() {
    _fireStore
        .collection('users')
        .doc(Provider.of<AuthProvider>(context, listen: false)
            .auth
            .currentUser!
            .uid)
        .get()
        .then(
          (value) => {
            if (value['saved'].contains(docRefId))
              setState(() {
                isSaved = true;
              })
            else
              setState(() {
                isSaved = false;
              })
          },
        );
  }

  void increaseViewCount(String docId) {
    _fireStore.collection('recipes').doc(docId).update(
      {'views': views! + 1},
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: CustomScrollView(
          physics: BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              iconTheme: IconThemeData(color: kPrimaryColor),
              stretch: true,
              backgroundColor: Colors.white,
              elevation: 0,
              expandedHeight: 300.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: EdgeInsets.only(top: 10),
                  title: Wrap(
                    /// TODO: Wrap is cropping title of long food names
                    // mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        alignment: Alignment.bottomCenter,
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20)),
                        child: Center(
                          child: Text(
                            foodName,
                            textAlign: TextAlign.center,
                            maxLines: foodName.length > 40 ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                kFormHeadingStyle.copyWith(color: Colors.white),
                            // overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  collapseMode: CollapseMode.parallax,

                  /// food image
                  background: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(30),
                          bottomLeft: Radius.circular(30)),
                      image: DecorationImage(
                          image: CachedNetworkImageProvider(
                            imgUrl!,
                          ),
                          fit: BoxFit.cover),
                    ),
                  )),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              sliver: SliverList(
                  delegate: SliverChildListDelegate([
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    kFixedSizedBox,
                    foodName.length > 40
                        ? Text(
                            " ' $foodName ' ",
                            // textAlign: TextAlign.center,

                            style: kFormHeadingStyle.copyWith(fontSize: 18),
                            // overflow: TextOverflow.ellipsis,
                          )
                        : Container(),
                    kFixedSizedBox,
                    Text(
                      '${isVeg ? 'Veg' : 'Non-veg'}. ${cookingDuration.toString()} mins',
                      style: kSecondaryTextStyle,
                    ),
                    kFixedSizedBox,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// Row of chef image and name
                            InkWell(
                              onTap: () {
                                Navigation.changeScreen(
                                  context,
                                  Profile(chefID),
                                );
                                //TODO goto profile
                              },
                              child: Row(
                                children: [
                                  Container(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: CachedNetworkImage(
                                        imageUrl: chefImage!,
                                        placeholder: (context, url) =>
                                            Image.asset(
                                                'images/profile_loading.gif'),
                                        errorWidget: (context, url, error) =>
                                            Icon(Icons.network_check),
                                        fit: BoxFit.cover,
                                        height: 35,
                                        width: 35,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    chefName,
                                    overflow: TextOverflow.ellipsis,
                                    style: kFormHeadingStyle.copyWith(
                                        fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            InkWell(
                              onTap: isSaved
                                  ? () {
                                      removeFromBookmark();
                                    }
                                  : () async {
                                      print('save clicked');
                                      _fireStore
                                          .collection('users')
                                          .doc(Provider.of<AuthProvider>(
                                                  context,
                                                  listen: false)
                                              .auth
                                              .currentUser!
                                              .uid)
                                          .update(
                                        {
                                          'saved':
                                              FieldValue.arrayUnion([docRefId])
                                        },
                                      ).onError((error, stackTrace) {
                                        print(error);
                                        showSnackBar(
                                            'Could not Save at the moment',
                                            context,
                                            Icons.error_outline);
                                      });
                                      setState(() {
                                        isSaved = true;
                                      });
                                    },
                              child: Row(
                                children: [
                                  Icon(
                                    isSaved
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    color: Colors.redAccent,
                                  ),
                                  SizedBox(width: 10),
                                  Text(isSaved ? 'Bookmarked' : 'Bookmark',
                                      style: kFormHeadingStyle.copyWith(
                                          fontSize: 15))
                                ],
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// Row of view icon and view count
                            Row(
                              children: [
                                Icon(
                                  Icons.remove_red_eye_outlined,
                                  color: Colors.red,
                                ),
                                Text(
                                  '  $views views',
                                  style:
                                      kFormHeadingStyle.copyWith(fontSize: 15),
                                )
                              ],
                            ),

                            /// row for delete icon and text

                            isAdmin || isOwnRecipe
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 10.0),
                                    child: InkWell(
                                      onTap: () {
                                        showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                content: Text(
                                                    'Are you sure want to delete?',
                                                    style: kFormHeadingStyle
                                                        .copyWith(
                                                            fontSize: 18,
                                                            color: Colors.red)),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () {
                                                        DeleteRecipe(
                                                                imageUrl:
                                                                    imgUrl,
                                                                snapshot: widget
                                                                    .snapshot)
                                                            .deleteDocumentFromFirebase();
                                                        showSnackBar(
                                                            "Deleted SuccessFully",
                                                            context,
                                                            Icons
                                                                .delete_forever_outlined);
                                                        Navigation
                                                            .changeScreenWithReplacement(
                                                                context,
                                                                NavBarController());
                                                      },
                                                      child: Text('Yes')),
                                                  TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child: Text('No',
                                                          style: kFormHeadingStyle
                                                              .copyWith(
                                                                  fontSize: 15,
                                                                  color: Colors
                                                                      .red)))
                                                ],
                                              );
                                            });
                                      },
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_forever_outlined,
                                            color: Colors.redAccent,
                                          ),
                                          Text(
                                            ' Delete',
                                            style: kFormHeadingStyle.copyWith(
                                                fontSize: 15,
                                                color: Colors.red),
                                          )
                                        ],
                                      ),
                                    ),
                                  )
                                : Container(),
                          ],
                        ),
                      ],
                    ),
                    kFixedSizedBox,
                    isAdmin || isOwnRecipe
                        ? InkWell(
                            onTap: () {
                              Navigation.changeScreen(
                                  context,
                                  RecipeForm(
                                    isEditing: true,
                                    editingSnapshot: widget.snapshot,
                                  ));
                            },
                            child: FlatButtonWithText(
                              text: 'Edit Recipe',
                            ),
                          )
                        : Container(),
                    kDivider,
                    Text(
                      'Description',
                      style: kFormHeadingStyle,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      description,
                      style: kSecondaryTextStyle,
                    ),
                    kDivider,
                    Text(
                      'Ingredients',
                      style: kFormHeadingStyle,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                  ],
                )
              ])),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  List.generate(
                    ingredients.length,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.withOpacity(0.1)),
                            child: Center(
                              child: Icon(
                                Icons.check,
                                size: 20,
                                color: kPrimaryColor,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Container(
                            width: ScreenSize.getWidth(context) * 0.8,
                            child: Text(
                              ingredients[index],
                              style: TextStyle(
                                  fontFamily: 'Dosis-SemiBold',
                                  letterSpacing: 1.1),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Steps',
                  style: kFormHeadingStyle,
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  ListView.builder(
                    itemCount: steps.length,
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemBuilder: (BuildContext context, index) {
                      return TimelineTile(
                        // oppositeContents: Padding(
                        //   padding: const EdgeInsets.all(8.0),
                        //   child: Text('opposite\ncontents'),
                        // ),

                        nodePosition: 0.05,
                        contents: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            width: ScreenSize.getWidth(context),
                            padding: EdgeInsets.all(25),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: Offset(5, 5))
                                ]),
                            child: Text(
                              steps[index],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                  fontSize: 18,
                                  letterSpacing: 1.5),
                            ),
                          ),
                        ),
                        node: TimelineNode(
                          indicator: ContainerIndicator(
                            child: CircleAvatar(
                              backgroundColor: kPrimaryColor,
                              radius: 18,
                              child: Text(
                                (index + 1).toString(),
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          startConnector: SolidLineConnector(
                            color: index == 0
                                ? Colors.transparent
                                : kLightGreenColor,
                            thickness: 3.5,
                          ),
                          endConnector: SolidLineConnector(
                            color: (index + 1) == steps.length
                                ? Colors.transparent
                                : kLightGreenColor,
                            thickness: 3.5,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(
                    height: 50,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
