import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:foodrecipe/models/recipe.dart';

class RecipeApi {
  // const axios = require('axios');
  //
  // const options = {
  //   method: 'GET',
  //   url: 'https://yummly2.p.rapidapi.com/feeds/list',
  //   params: {
  //     limit: '24',
  //     start: '0'
  //   },
  //   headers: {
  //     'X-RapidAPI-Key': '3567e0c326msha258f1fd78bc725p199692jsn4582034b37d9',
  //     'X-RapidAPI-Host': 'yummly2.p.rapidapi.com'
  //   }
  // };

  static Future<List<Recipe>?> getRecipe() async {
    var uri = Uri.https('yummly2.p.rapidapi.com', 'feeds/list',
        {"limit": "24", "start": "0", "tag": "list.recipe.popular"});

    final response = await http.get(uri, headers: {
"X-RapidAPI-Key": "3567e0c326msha258f1fd78bc725p199692jsn4582034b37d9",
"X-RapidAPI-Host": "yummly2.p.rapidapi.com",
      "userQueryString":"true",

    });

    Map data = jsonDecode(response.body);
    List temp = [];
    for (var i in data['feed']) {
      temp.add(i['content']['details']);
    }

    return Recipe.recipesFromSnapshot(temp);
  }
}
