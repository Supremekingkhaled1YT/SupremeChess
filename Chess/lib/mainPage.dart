import 'package:chess_game/aiboard.dart';
import 'package:chess_game/mainboard.dart';
import 'package:flutter/material.dart';

class Mainpage extends StatelessWidget {
  const Mainpage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chess'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 187, 33, 243),
      ),
      body: Center(
        child: SizedBox(
          width: 500,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("pieces/BG1.jpg"),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Modes',
                  style: TextStyle(fontSize: 24, color: Colors.deepPurple),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                   Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Mainboard(),
                      ),
                    );
                  },
                  child: const Text('Player Vs Player'),
                ),
                Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context)=>aiboard())
                        );
                      },
                      child: const Text('Player Vs AI'),
                    );
  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
