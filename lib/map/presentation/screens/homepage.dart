import 'package:bari_koi/map/presentation/provider/map_provider.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);



    return Scaffold(backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.amber, title: const Text('BariKoi Map'),centerTitle: true,),
      body: Column(
        children: [
          Expanded(
            child: MaplibreMap(
              initialCameraPosition: mapProvider.initialPosition,
              minMaxZoomPreference: const MinMaxZoomPreference(3.0, 18.0),
              styleString: MapProvider.mapUrl,
              onMapCreated: (controller) {
                mapProvider.mController = controller;


              },
              onMapClick: (point, latLng) {
                mapProvider.getAddressFromCoordinates(latLng,context);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [ if (mapProvider.originAddress.isNotEmpty || mapProvider.destinationAddress.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Origin Address: ${mapProvider.originAddress}'),
                    Text('Destination Address: ${mapProvider.destinationAddress}'),
                  ],
                )
              else
                const Text('Click on the map to get the addresses'),
                const SizedBox(height: 10),
                ElevatedButton(

                  onPressed: mapProvider.getCurrentLocation,
                  style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.amber
                  ),
                  child: const Text('Get Current Location', style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold),),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
