import 'package:flutter/material.dart';

///classes that implement Tile have a method to be displayed with a ListTile
abstract class Tile {
  ListTile getTile(BuildContext context);
}
