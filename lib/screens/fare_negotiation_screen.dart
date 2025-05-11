 import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/ride_provider.dart';
import '../models/fare_offer_model.dart';
import '../models/driver_model.dart';
import '../constants/app_routes.dart';
import '../constants/app_theme.dart';

class FareNegotiationScreen extends StatefulWidget {
  const FareNegotiationScreen({super.key});

  @override
  State<FareNegotiationScreen> createState() => _FareNegotiationScreenState();
}

class _FareNegotiationScreenState extends State<FareNegotiationScreen> {
  final TextEditingController _counterOfferController = TextEditingController();
  bool _isLoading = false;
  bool _showDriverResponses = false;
  List<String> _selectedDriverIds = [];
  
  @override
  void dispose() {
    _counterOfferController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final rideProvider = Provider.of<RideProvider>(context);
    final currentRideRequest = rideProvider.currentRideRequest;
    
    // If no current ride request, redirect back to home
    if (currentRideRequest == null) {
      // Redirect after frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    final Map<String, dynamic>? routeData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    final String from = currentRideRequest.fromAddress;
    final String to = currentRideRequest.toAddress;
    final double initialFare = currentRideRequest.initialFare;
    
    final counterOffers = 
        rideProvider.getCounterOffersForRide(currentRideRequest.id);
    final activeOffers = counterOffers
        .where((offer) => offer.status == 'pending')
        .toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fare Negotiation'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Route info card
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'From',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            from,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'To',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            to,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Proposed Fare',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '\$${initialFare.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Status text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              currentRideRequest.status == 'pending'
                  ? 'Waiting for drivers to respond...'
                  : activeOffers.isNotEmpty
                      ? 'Drivers have responded with counter offers'
                      : 'Negotiation completed',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Driver responses section
          Expanded(
            child: activeOffers.isEmpty && currentRideRequest.status == 'pending'
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : activeOffers.isEmpty && currentRideRequest.status == 'accepted'
                    ? _buildAcceptedRideInfo(context, rideProvider)
                    : _buildDriverOffersList(
                        context,
                        activeOffers,
                        rideProvider,
                      ),
          ),
          
          // Counter offer section (shown only when drivers are selected)
          if (_selectedDriverIds.isNotEmpty)
            _buildCounterOfferSection(context, rideProvider),
        ],
      ),
    );
  }
  
  Widget _buildDriverOffersList(
    BuildContext context,
    List<FareOffer> offers,
    RideProvider rideProvider,
  ) {
    return ListView.builder(
      itemCount: offers.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final offer = offers[index];
        final driver = rideProvider.getDriverForOffer(offer.driverId);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: _selectedDriverIds.contains(driver.id)
                  ? AppTheme.primaryColor
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                if (_selectedDriverIds.contains(driver.id)) {
                  _selectedDriverIds.remove(driver.id);
                } else {
                  _selectedDriverIds = [driver.id]; // Only select one at a time
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: driver.profileImageUrl != null
                            ? NetworkImage(driver.profileImageUrl!)
                            : null,
                        child: driver.profileImageUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  driver.rating.toString(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${driver.totalRides} rides',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${driver.carModel} • ${driver.carColor}',
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              driver.carNumber,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '\$${offer.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (offer.message != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        offer.message!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              if (_selectedDriverIds.contains(driver.id)) {
                                _selectedDriverIds.remove(driver.id);
                              } else {
                                _selectedDriverIds = [driver.id]; // Only select one
                              }
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _selectedDriverIds.contains(driver.id)
                                  ? AppTheme.primaryColor
                                  : Colors.grey,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            _selectedDriverIds.contains(driver.id)
                                ? 'Selected'
                                : 'Counter',
                            style: TextStyle(
                              color: _selectedDriverIds.contains(driver.id)
                                  ? AppTheme.primaryColor
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Accept this offer
                            rideProvider.acceptCounterOffer(
                              offer.id,
                              rideProvider.currentRideRequest!.id,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Accept',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildCounterOfferSection(
    BuildContext context,
    RideProvider rideProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Make a counter offer',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _counterOfferController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Your counter offer',
              prefixText: '\$ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      final String amountText = _counterOfferController.text;
                      if (amountText.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter an amount'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      final double amount = double.tryParse(amountText) ?? 0;
                      if (amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid amount'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      setState(() {
                        _isLoading = true;
                      });
                      
                      // Send counter offer to selected driver
                      try {
                        rideProvider.createRiderCounterOffer(
                          rideRequestId: rideProvider.currentRideRequest!.id,
                          driverId: _selectedDriverIds.first,
                          amount: amount,
                          message: 'I can pay \$${amount.toStringAsFixed(2)}',
                        );
                        
                        _counterOfferController.clear();
                        setState(() {
                          _selectedDriverIds = [];
                          _isLoading = false;
                        });
                      } catch (e) {
                        setState(() {
                          _isLoading = false;
                        });
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Send Counter Offer',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAcceptedRideInfo(
    BuildContext context,
    RideProvider rideProvider,
  ) {
    final currentRideRequest = rideProvider.currentRideRequest!;
    final acceptedOfferId = currentRideRequest.acceptedOfferId!;
    final offers = rideProvider.fareOffers;
    final acceptedOffer = offers.firstWhere((o) => o.id == acceptedOfferId);
    final driver = rideProvider.getDriverForOffer(acceptedOffer.driverId);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Ride Confirmed!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your ride with ${driver.name} has been confirmed',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _infoRow('Driver', driver.name),
                const SizedBox(height: 8),
                _infoRow('Vehicle', '${driver.carModel} • ${driver.carColor}'),
                const SizedBox(height: 8),
                _infoRow('License Plate', driver.carNumber),
                const SizedBox(height: 8),
                _infoRow('Fare Amount', '\$${acceptedOffer.amount.toStringAsFixed(2)}'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.tracking,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Track Your Ride',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}