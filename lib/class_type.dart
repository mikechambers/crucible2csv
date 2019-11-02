class ClassType {
  static const int titan = 0;
  static const int hunter = 1;
  static const int warlock = 2;


  static String labelFromType(int classType) {
    String out;

    switch(classType){
      case titan:
        out = "Titan";
        break;
      case hunter:
        out = "Hunter";
        break;
      case warlock:
        out = "Warlock";
        break;
    }

    return out;
  }
}