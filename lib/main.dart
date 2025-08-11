import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatbytes/login_screen.dart';
import 'package:whatbytes/on_boarding_screen.dart';
import 'package:whatbytes/task_managementUi.dart';

//void = does not return any value
//main = entry point of program execution
//async uses the await keyword to allow the function to operate in the background
void main() async {
  //widgetsflutter= bridge between flutter and host OS
  //ensures the framework is intialised before starting the program
  WidgetsFlutterBinding.ensureInitialized();

  //await used with async function; pauses the execution of code until initialise app is complete
  //initialiseApp initialises the firebase services for the application
  await Firebase.initializeApp(); // <-- Add this

  //runApp takes and inflates the widget to become the root of the widget
  runApp(const ProviderScope(child: MyApp()));

  //const= optimisation keyword = immutable = compile time constant
}

//class named myAPP that is a stateless widget
//extends=MyApp is a subclass of another class=inherits the properties and methods of stateless widget
class MyApp extends StatelessWidget {
  //MyApp = constructor of MyApp class
  //super.key passess Key to super class=dad of the class=keys as ID
  const MyApp({super.key});

  // overrides the existing method of superclass
  @override
  //returns a widget=return type of a build method
  //build= main method for widget= describes how widgets should be displayed
  //buildContext = handle the location of widget in widget tree = allows access to themedata and other services
  //context= parameter name for build context
  Widget build(BuildContext context) {
    //build returns materialApp
    //widget that wraps serveral widgets=used in material design apps=offers services like navigations; themes etc
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        //themedata holds data like colorscheme,text styles and visual properties etc
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const OnboardingScreen(),
    );
  }
}
