import 'package:flutter/material.dart';
import 'package:foodrecipe/models/recipe.dart';
import 'package:foodrecipe/models/recipe_api.dart';
import 'package:foodrecipe/views/widgets/recipe_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  List<Recipe> list=[];
  bool isLoading= false;

  @override
  void initState()
  {
    super.initState();
    getRecipees();
  }

  Future<void> getRecipees() async
  {
    list = (await RecipeApi.getRecipe())!;
    setState(() {
      isLoading = false;
    });

    print('recipe');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.restaurant_menu),
            SizedBox(
              height: 12,
              width: 12,
            ),
            Text(
              'Food Recipe',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            )
          ],
        ),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16))),
        backgroundColor: Colors.green,
      ),
      body:
          isLoading ? Center(
            child: CircularProgressIndicator()):
              ListView.builder(
                itemCount: list.length,
                itemBuilder: (context , index)
                {
                  return RecipeCard(title: list[index].name, cookTime: list[index].totalTime, rating: list[index].rating.toString(), thumbnailUrl: list[index].image);
                },
              )
          );
      // SingleChildScrollView(
      //   child: Column(
      //     children: [
      //       RecipeCard(title: 'Food',rating: '34534', cookTime: '234', thumbnailUrl: 'https://lh3.googleusercontent.com/ei5eF1LRFkkcekhjdR_8XgOqgdjpomf-rda_vvh7jIauCgLlEWORINSKMRR6I6iTcxxZL9riJwFqKMvK0ixS0xwnRHGMY4I5Zw=s360',),
      //       RecipeCard(title: 'Food',rating: '34534', cookTime: '234', thumbnailUrl: 'https://lh3.googleusercontent.com/ei5eF1LRFkkcekhjdR_8XgOqgdjpomf-rda_vvh7jIauCgLlEWORINSKMRR6I6iTcxxZL9riJwFqKMvK0ixS0xwnRHGMY4I5Zw=s360',),
      //       RecipeCard(title: 'Food',rating: '34534', cookTime: '234', thumbnailUrl: 'https://lh3.googleusercontent.com/ei5eF1LRFkkcekhjdR_8XgOqgdjpomf-rda_vvh7jIauCgLlEWORINSKMRR6I6iTcxxZL9riJwFqKMvK0ixS0xwnRHGMY4I5Zw=s360',),
      //       RecipeCard(title: 'Food',rating: '34534', cookTime: '234', thumbnailUrl: 'https://lh3.googleusercontent.com/ei5eF1LRFkkcekhjdR_8XgOqgdjpomf-rda_vvh7jIauCgLlEWORINSKMRR6I6iTcxxZL9riJwFqKMvK0ixS0xwnRHGMY4I5Zw=s360',),
      //       RecipeCard(title: 'Food',rating: '34534', cookTime: '234', thumbnailUrl: 'https://lh3.googleusercontent.com/ei5eF1LRFkkcekhjdR_8XgOqgdjpomf-rda_vvh7jIauCgLlEWORINSKMRR6I6iTcxxZL9riJwFqKMvK0ixS0xwnRHGMY4I5Zw=s360',),
      //       RecipeCard(title: 'Food',rating: '34534', cookTime: '234', thumbnailUrl: 'https://lh3.googleusercontent.com/ei5eF1LRFkkcekhjdR_8XgOqgdjpomf-rda_vvh7jIauCgLlEWORINSKMRR6I6iTcxxZL9riJwFqKMvK0ixS0xwnRHGMY4I5Zw=s360',),
      //
      //     ],
      //   ),
      // ),
     // backgroundColor: Colors.red,
   // );
  }
}
