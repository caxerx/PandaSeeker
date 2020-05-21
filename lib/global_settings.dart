import 'package:flutter/material.dart';

class GlobalSetting {
  static const APP_NAME = "Panda Seeker";
  static const searchType = [
    SearchType(title: "Doujinshi", color: Colors.red, value: 2),
    SearchType(title: "Manga", color: Colors.orange, value: 4),
    SearchType(title: "Artist CG", color: Colors.yellow, value: 8),
    SearchType(title: "Game CG", color: Colors.green, value: 16),
    SearchType(title: "Western", color: Colors.lightGreen, value: 512),
    SearchType(title: "Non-H", color: Colors.lightBlueAccent, value: 256),
    SearchType(title: "Image Set", color: Colors.blueAccent, value: 32),
    SearchType(title: "Cosplay", color: Colors.purple, value: 64),
    SearchType(title: "Asian Porn", color: Colors.purpleAccent, value: 128),
    SearchType(title: "Misc", color: Colors.grey, value: 1),
  ];

  static const safeMode = 767;
}

class SearchType {
  final String title;
  final Color color;
  final int value;

  const SearchType({this.title, this.color, this.value});

  static int calculateSearchParameter(List<SearchType> disabledOption) {
    return disabledOption.map((i) => i.value).reduce((v, e) => v + e);
  }
}
