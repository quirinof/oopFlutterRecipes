// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

enum TableStatus { idle, loading, ready, error }

class DataService {
  final ValueNotifier<Map<String, dynamic>> tableStateNotifier = ValueNotifier({
    'status': TableStatus.idle,
    'dataObjects': [],
  });

  void carregar(index) {
    final funcoes = [
      carregarCafes,
      carregarCervejas,
      carregarComidas,
      carregarNacoes
    ];
    tableStateNotifier.value = {
      'status': TableStatus.loading,
      'dataObjects': []
    };
    funcoes[index]();
  }

// foram adicionados, em todas as chamadas as api's, os tratamentos de erros

  void carregarCafes() {
    var coffeesUri = Uri(
      scheme: 'https',
      host: 'random-data-api.com',
      path: 'api/coffee/random_coffee',
      queryParameters: {'size': '15'},
    );

    http.read(coffeesUri).then((jsonString) {
      var coffeesJson = jsonDecode(jsonString);
      tableStateNotifier.value = {
        'status': TableStatus.ready,
        'dataObjects': coffeesJson,
        'columnNames': ["Nome", "Intensificador", "Notas"],
        'propertyNames': ["blend_name", "intensifier", "notes"],
      };
    }).catchError((e) {
      tableStateNotifier.value = {'status': TableStatus.error};
    });
  }

  void carregarCervejas() {
    var beersUri = Uri(
      scheme: 'https',
      host: 'random-data-api.com',
      path: 'api/beer/random_beer',
      queryParameters: {'size': '15'},
    );

    http.read(beersUri).then((jsonString) {
      var beersJson = jsonDecode(jsonString);
      tableStateNotifier.value = {
        'status': TableStatus.ready,
        'dataObjects': beersJson,
        'columnNames': ["Nome", "Estilo", "IBU"],
        'propertyNames': ["name", "style", "ibu"],
      };
    }).catchError((e) {
      tableStateNotifier.value = {'status': TableStatus.error};
    });
  }

  void carregarComidas() async {
    var foodsUri = Uri(
      scheme: 'https',
      host: 'random-data-api.com',
      path: 'api/food/random_food',
      queryParameters: {'size': '15'},
    );
    try {
      var jsonString = await http.read(foodsUri);
      var foodsJson = jsonDecode(jsonString);
      tableStateNotifier.value = {
        'status': TableStatus.ready,
        'dataObjects': foodsJson,
        'columnNames': ["Prato", "Ingredientes", "Medida"],
        'propertyNames': ["dish", "ingredient", "measurement"],
      };
    } catch (e) {
      tableStateNotifier.value = {'status': TableStatus.error};
    }
  }

  void carregarNacoes() async {
    var nationsUri = Uri(
      scheme: 'https',
      host: 'random-data-api.com',
      path: 'api/nation/random_nation',
      queryParameters: {'size': '15'},
    );
    try {
      var jsonString = await http.read(nationsUri);
      var nationsJson = jsonDecode(jsonString);
      tableStateNotifier.value = {
        'status': TableStatus.ready,
        'dataObjects': nationsJson,
        'columnNames': ["Nação", "Idioma", "Capital"],
        'propertyNames': ["nationality", "language", "capital"],
      };
    } catch (e) {
      tableStateNotifier.value = {'status': TableStatus.error};
    }
  }
}

final dataService = DataService();

void main() {
  MyApp app = MyApp();
  runApp(app);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.amber),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Dicas"),
        ),
        body: ValueListenableBuilder(
          valueListenable: dataService.tableStateNotifier,
          builder: (_, value, __) {
            switch (value['status']) {
              case TableStatus.idle:
                return Column(children: [
                  Center(
                    child: Image.asset(
                      'assets/images/cafe-e-cerveja.jpg',
                      width: 300.0,
                      height: 300.0,
                    ),
                  ),
                  Text(
                    "Bem vindo ao App",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Você deve tocar em um dos botões abaixo",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ]);

              case TableStatus.loading:
                return Center(child: CircularProgressIndicator());

              case TableStatus.ready:
                return SingleChildScrollView(
                  child: Center(
                    child: DataTableWidget(
                      jsonObjects: value['dataObjects'],
                      columnNames: value['columnNames'],
                      propertyNames: value['propertyNames'],
                    ),
                  ),
                );

              case TableStatus.error:
                return Center(
                  child: Text(
                    "Falha na conexão.",
                    style: TextStyle(fontSize: 30, color: Colors.red),
                  ),
                );
            }

            return const Text("...");
          },
        ),
        bottomNavigationBar: NewNavBar(
          itemSelectedCallback: dataService.carregar,
        ),
      ),
    );
  }
}

class NewNavBar extends HookWidget {
  final _itemSelectedCallback;

  NewNavBar({itemSelectedCallback})
      : _itemSelectedCallback = itemSelectedCallback ?? (int) {}

  @override
  Widget build(BuildContext context) {
    var state = useState(1);

    return BottomNavigationBar(
      onTap: (index) {
        state.value = index;

        _itemSelectedCallback(index);
      },
      currentIndex: state.value,
      selectedItemColor: Colors.amber,
      items: const [
        BottomNavigationBarItem(
          label: "Cafés",
          icon: Icon(Icons.coffee_outlined),
          backgroundColor: Colors.black,
        ),
        BottomNavigationBarItem(
          label: "Cervejas",
          icon: Icon(Icons.local_drink_outlined),
          backgroundColor: Colors.black,
        ),
        BottomNavigationBarItem(
          label: "Comidas",
          icon: Icon(Icons.food_bank_outlined),
          backgroundColor: Colors.black,
        ),
        BottomNavigationBarItem(
          label: "Nações",
          icon: Icon(Icons.flag_outlined),
          backgroundColor: Colors.black,
        ),
      ],
    );
  }
}

class DataTableWidget extends HookWidget {
  // transformada a classe em um hookWidget
  final List jsonObjects;
  final List<String> columnNames;
  final List<String> propertyNames;

  DataTableWidget({
    this.jsonObjects = const [],
    this.columnNames = const ["Nome", "Estilo", "IBU"],
    this.propertyNames = const ["name", "style", "ibu"],
  }) {
    jsonObjects.sort((obj1, obj2) =>
        obj1[propertyNames[0]].compareTo(obj2[propertyNames[0]]));
  }

  @override
  Widget build(BuildContext context) {
    // adicionando os estados para as colunas
    var stateIndex = useState(0);
    var stateAscending = useState(true);
    return DataTable(
      sortColumnIndex: stateIndex.value,
      sortAscending: stateAscending.value,
      columns: columnNames
          .map((name) => DataColumn(
              onSort: (index, Ascending) {
                stateIndex.value = index;
                stateAscending.value = Ascending;
                // comparando os objetos para a ordenação
                if (Ascending) {
                  jsonObjects.sort((obj1, obj2) => obj1[propertyNames[index]]
                      .compareTo(obj2[propertyNames[index]]));
                } else {
                  jsonObjects.sort((obj1, obj2) => obj2[propertyNames[index]]
                      .compareTo(obj1[propertyNames[index]]));
                }
              },
              label: Expanded(
                child: Text(
                  name,
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              )))
          .toList(),
      rows: jsonObjects
          .map((obj) => DataRow(
              cells: propertyNames
                  .map((propName) => DataCell(Text(obj[propName])))
                  .toList()))
          .toList(),
    );
  }
}
