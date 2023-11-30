import 'package:flutter/material.dart';

// Importaciones de http para consumir la api
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    //fetchData();
    return MaterialApp(
      title: 'Restaurante la Criollita',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.teal,
          accentColor: Colors.deepOrangeAccent,
        ),
        fontFamily: 'Montserrat',
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      home: const MyHomePage(title: 'La Criollita'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<MenuItem> menuItems = [];
  List<String> categories = [];

  TextEditingController categoryController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController costController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Llama a la función fetchData al iniciar la página
    fetchData();
  }

  void fetchData() async {
    try {
      final response = await http
          .get(Uri.parse('http://10.0.2.2:3000/categoriasconplatillos'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);

        // Itera sobre la respuesta y construye las listas
        for (var categoryData in data) {
          String categoryName = categoryData['nombre'];
          categories.add(categoryName);

          List<dynamic> platillos = categoryData['platillos'];
          for (var platilloData in platillos) {
            bool isActive = platilloData['activo'];

            // Solo agrega el platillo si está activo
            if (isActive) {
              menuItems.add(MenuItem(
                categoryName,
                platilloData['nombre'],
                double.parse(platilloData['costo']),
                isActive,
              ));
            }
          }
        }

        // Actualiza el estado para que Flutter repinte la interfaz
        setState(() {});
      } else {
        throw Exception('Error al cargar datos desde la API');
      }
    } catch (e) {
      print('Error: $e');
      // Maneja el error según sea necesario
    }
  }

  void _addOrUpdateItem(MenuItem item) {
    setState(() {
      if (menuItems.contains(item)) {
        int index = menuItems.indexOf(item);
        menuItems[index] = item;
      } else {
        // Establecer por defecto que el estado esté activo
        menuItems.add(MenuItem(
          item.category,
          item.name,
          item.cost,
          true,
        ));
      }

      categoryController.clear();
      nameController.clear();
      costController.clear();
    });
  }

  void _deleteItem(MenuItem item) {
    setState(() {
      menuItems.remove(item);
    });
  }

  void _toggleItemStatus(MenuItem item) {
    setState(() {
      item.isActive = !item.isActive;
    });
  }

  void _addOrUpdateCategory(String category) {
    setState(() {
      if (categories.contains(category)) {
        return;
      }

      categories.add(category);
      categoryController.clear();
    });
  }

  void _deleteCategory(String category) {
    setState(() {
      categories.remove(category);
      menuItems.removeWhere((item) => item.category == category);

      categoryController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<MenuItem>> groupedMenuItems = {};

    menuItems.forEach((item) {
      if (!groupedMenuItems.containsKey(item.category)) {
        groupedMenuItems[item.category] = [];
      }
      groupedMenuItems[item.category]!.add(item);
    });

    return Scaffold(
      appBar: AppBar(
        title:
            Text('Restaurante La Criollita', style: TextStyle(fontSize: 24.0)),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: groupedMenuItems.length,
        itemBuilder: (context, categoryIndex) {
          String category = groupedMenuItems.keys.elementAt(categoryIndex);
          List<MenuItem> categoryItems = groupedMenuItems[category]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: categoryItems.length,
                itemBuilder: (context, itemIndex) {
                  return Card(
                    margin: EdgeInsets.all(8.0),
                    elevation: 4.0,
                    child: ListTile(
                      title: Text(
                        categoryItems[itemIndex].name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              "Categoría: ${categoryItems[itemIndex].category}"),
                          Text(
                              "Costo: \₡${categoryItems[itemIndex].cost.toStringAsFixed(2)}"),
                          Text(
                            "Estado: ${categoryItems[itemIndex].isActive ? 'Activo' : 'Inactivo'}",
                            style: TextStyle(
                              color: categoryItems[itemIndex].isActive
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _showEditItemDialog(categoryItems[itemIndex]);
                            },
                          ),
                          IconButton(
                            icon: Icon(categoryItems[itemIndex].isActive
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () {
                              _toggleItemStatus(categoryItems[itemIndex]);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              _deleteItem(categoryItems[itemIndex]);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddItemDialog();
        },
        tooltip: 'Agregar Platillo',
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddItemDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Agregar Nuevo Platillo',
              style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButton<String>(
                  value: categories.isNotEmpty ? categories[0] : null,
                  items:
                      categories.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      categoryController.text = value ?? '';
                    });
                  },
                  hint: Text('Seleccionar Categoría',
                      style: TextStyle(color: Colors.white)),
                ),
                TextField(
                  controller: nameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nombre del Platillo',
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                ),
                TextField(
                  controller: costController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Costo',
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Agregar', style: TextStyle(color: Colors.white)),
              onPressed: () {
                if (categoryController.text.isNotEmpty &&
                    nameController.text.isNotEmpty &&
                    costController.text.isNotEmpty) {
                  _addOrUpdateItem(MenuItem(
                    categoryController.text,
                    nameController.text,
                    double.parse(costController.text),
                    true,
                  ));
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Todos los campos son obligatorios'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditItemDialog(MenuItem item) async {
    categoryController.text = item.category;
    nameController.text = item.name;
    costController.text = item.cost.toString();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar Platillo', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButton<String>(
                  value: item.isActive
                      ? categories.contains(categoryController.text)
                          ? categoryController.text
                          : null
                      : null,
                  items:
                      categories.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      categoryController.text = value ?? '';
                    });
                  },
                  hint: Text('Seleccionar Categoría',
                      style: TextStyle(color: Colors.white)),
                ),
                TextField(
                  controller: nameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nombre del Platillo',
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                ),
                TextField(
                  controller: costController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Costo',
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Guardar Cambios',
                  style: TextStyle(color: Colors.white)),
              onPressed: () {
                if (categoryController.text.isNotEmpty &&
                    nameController.text.isNotEmpty &&
                    costController.text.isNotEmpty) {
                  _addOrUpdateItem(MenuItem(
                    categoryController.text,
                    nameController.text,
                    double.parse(costController.text),
                    item.isActive,
                  ));
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Todos los campos son obligatorios'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}

Future<List<dynamic>> fetchData() async {
  final response =
      await http.get(Uri.parse('http://10.0.2.2:3000/categoriasconplatillos'));

  if (response.statusCode == 200) {
    List<dynamic> data = json.decode(response.body);
    print('Datos desde la API: $data'); // Imprimir datos en la consola
    return data;
  } else {
    throw Exception('Error al cargar datos desde la API');
  }
}

class MenuItem {
  final String category;
  final String name;
  final double cost;
  bool isActive;

  MenuItem(this.category, this.name, this.cost, this.isActive);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuItem &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          name == other.name &&
          cost == other.cost &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      category.hashCode ^ name.hashCode ^ cost.hashCode ^ isActive.hashCode;
}
