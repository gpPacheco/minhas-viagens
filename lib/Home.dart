import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'geocoding_service.dart';
import 'viagem_model.dart';
import 'Mapas.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final List<Viagem> _listaViagens = [];

  Future<void> _adicionarLocal() async {
    final selectedLocation = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (context) => const Mapas()),
    );
    if (selectedLocation != null) {
      await _adicionarViagemDaLocalizacao(selectedLocation);
    }
  }

  Future<void> _adicionarViagemDaLocalizacao(LatLng location) async {
    try {
      // 1. Obter dados da API
      final dadosLocal =
          await GeocodingService.getAddressFromCoordinates(location);

      // 2. Diálogo para nome personalizado
      final nomeController = TextEditingController(
        text: dadosLocal['name'] ??
            dadosLocal['address']['amenity'] ??
            'Novo Local',
      );

      final confirmado = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar Local'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                    'Endereço: ${dadosLocal['display_name'] ?? 'Não identificado'}'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome para este local',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      );

      if (confirmado == true) {
        final novaViagem = Viagem.fromJson(
          dadosLocal,
          nomePersonalizado: nomeController.text,
        );
        setState(() => _listaViagens.add(novaViagem));
      }
    } catch (e) {
      // Fallback manual se a API falhar
      final nome = await _mostrarDialogoManual(location);
      if (nome != null) {
        setState(() => _listaViagens.add(
              Viagem(
                coordenadas: location,
                nome: nome,
                endereco:
                    'Coordenadas: ${location.latitude.toStringAsFixed(6)}, '
                    '${location.longitude.toStringAsFixed(6)}',
                cidade: 'Não identificada',
                estado: '',
                pais: '',
                cep: '',
              ),
            ));
      }
    }
  }

  Future<String?> _mostrarDialogoManual(LatLng location) async {
    final controller = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Local Manualmente'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nome do local',
            hintText: 'Ex: Meu ponto favorito',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _excluirViagem(int index) {
    setState(() {
      _listaViagens.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Minhas Viagens"),
        centerTitle: true,
        actions: [
          if (_listaViagens.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.sort_by_alpha),
              tooltip: 'Ordenar por proximidade',
              onPressed: () async {
                try {
                  final position = await Geolocator.getCurrentPosition();
                  setState(() {
                    _listaViagens.sort((a, b) {
                      final distanciaA = const Distance().as(
                          LengthUnit.Kilometer,
                          LatLng(position.latitude, position.longitude),
                          a.coordenadas);
                      final distanciaB = const Distance().as(
                          LengthUnit.Kilometer,
                          LatLng(position.latitude, position.longitude),
                          b.coordenadas);
                      return distanciaA.compareTo(distanciaB);
                    });
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Viagens ordenadas por proximidade'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao ordenar: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add_location_alt),
        onPressed: _adicionarLocal,
        tooltip: 'Adicionar nova viagem',
      ),
      body: _listaViagens.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.travel_explore,
                    size: 80,
                    color: Colors.blue.withOpacity(0.5),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Nenhuma viagem adicionada',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Toque no botão + para adicionar\nsua primeira viagem',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _listaViagens.length,
              itemBuilder: (context, index) {
                final viagem = _listaViagens[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Mapas(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  viagem.nome,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.red[400],
                                onPressed: () => _excluirViagem(index),
                              ),
                            ],
                          ),
                          if (viagem.endereco.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                viagem.endereco,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          if (viagem.cidade.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '${viagem.cidade}, ${viagem.estado}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.blue[400],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${viagem.coordenadas.latitude.toStringAsFixed(4)}, '
                                  '${viagem.coordenadas.longitude.toStringAsFixed(4)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
