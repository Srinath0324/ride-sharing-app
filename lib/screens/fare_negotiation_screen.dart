import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/ride_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/ride_history_provider.dart';
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
  bool _showCounterOfferInput = false;
  bool _showPaymentSheet = false;
  bool _paymentCompleted = false;
  String _selectedPaymentMethod = 'cash'; // 'cash' or 'wallet'

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

    final counterOffers = rideProvider.getCounterOffersForRide(
      currentRideRequest.id,
    );
    final activeOffers =
        counterOffers.where((offer) => offer.status == 'pending').toList();

    // Get accepted offer if available
    FareOffer? acceptedOffer;
    DriverModel? acceptedDriver;
    if (currentRideRequest.acceptedOfferId != null) {
      acceptedOffer = rideProvider.fareOffers.firstWhere(
        (o) => o.id == currentRideRequest.acceptedOfferId,
        orElse: () => throw Exception('Accepted offer not found'),
      );
      acceptedDriver = rideProvider.getDriverForOffer(acceptedOffer.driverId);
    }

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
                            style: TextStyle(fontSize: 12, color: Colors.grey),
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
                            style: TextStyle(fontSize: 12, color: Colors.grey),
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
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            '₹${initialFare.toInt()}',
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),

          const SizedBox(height: 16),

          // Driver responses section
          Expanded(
            child:
                activeOffers.isEmpty && _paymentCompleted
                    ? _buildAcceptedRideInfo(context, rideProvider)
                    : activeOffers.isEmpty &&
                        currentRideRequest.status == 'accepted' &&
                        _paymentCompleted // Only show accepted ride info after payment is completed
                    ? _buildAcceptedRideInfo(context, rideProvider)
                    : _buildDriverOffersList(
                      context,
                      activeOffers,
                      rideProvider,
                    ),
          ),

          // Counter offer section (shown only when counter button is clicked)
          if (_showCounterOfferInput && !_selectedDriverIds.isEmpty)
            _buildCounterOfferSection(context, rideProvider),
        ],
      ),
      // Show appropriate bottom sheet
      bottomSheet:
          _showPaymentSheet && acceptedOffer != null && acceptedDriver != null
              ? _buildPaymentMethodSheet(acceptedOffer, acceptedDriver)
              : null,
    );
  }

  Widget _buildDriverOffersList(
    BuildContext context,
    List<FareOffer> offers,
    RideProvider rideProvider,
  ) {
    final currentRideRequest = rideProvider.currentRideRequest;
    if (currentRideRequest == null) return Container();

    return ListView.builder(
      itemCount: offers.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final offer = offers[index];
        final driver = rideProvider.getDriverForOffer(offer.driverId);
        final isSelected = _selectedDriverIds.contains(driver.id);

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
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
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
                        backgroundImage:
                            driver.profileImageUrl != null
                                ? NetworkImage(driver.profileImageUrl!)
                                : null,
                        child:
                            driver.profileImageUrl == null
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
                              style: const TextStyle(fontSize: 14),
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
                          '₹${offer.amount.toInt()}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Ride details section
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              currentRideRequest.rideType == 'shared'
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.deepPurpleAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          currentRideRequest.rideType == 'shared'
                              ? 'Shared Cab'
                              : 'Private Cab',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                currentRideRequest.rideType == 'shared'
                                    ? Colors.green
                                    : Colors.deepPurpleAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (currentRideRequest.rideType == 'shared')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${currentRideRequest.seats} Seats',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          currentRideRequest.scheduledTime != null
                              ? DateFormat(
                                'dd MMM, h:mm a',
                              ).format(currentRideRequest.scheduledTime!)
                              : 'Now',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
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

                  // Only show buttons when this driver is selected
                  if (isSelected) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _showCounterOfferSection(driver.id);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppTheme.primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Counter',
                              style: TextStyle(color: AppTheme.primaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Show payment sheet instead of immediately accepting
                              setState(() {
                                _showPaymentSheet = true;
                                // Store the offer we're accepting
                                rideProvider.acceptCounterOffer(
                                  offer.id,
                                  currentRideRequest.id,
                                );
                              });
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // New helper method to show counter offer section
  void _showCounterOfferSection(String driverId) {
    setState(() {
      _selectedDriverIds = [driverId];
      _showCounterOfferInput = true;
    });
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
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _counterOfferController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Your counter offer',
              prefixText: '₹ ',
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
              onPressed:
                  _isLoading
                      ? null
                      : () {
                        final String amountText =
                            _counterOfferController.text.trim();
                        if (amountText.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter an amount'),
                            ),
                          );
                          return;
                        }

                        double amount =
                            double.tryParse(
                              amountText
                                  .replaceAll('₹', '')
                                  .replaceAll(',', ''),
                            ) ??
                            0;

                        if (amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid amount'),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          _isLoading = true;
                        });

                        try {
                          if (_selectedDriverIds.isNotEmpty) {
                            final driverId = _selectedDriverIds.first;
                            final rideRequestId =
                                rideProvider.currentRideRequest!.id;

                            // Ensure we'll get a response by setting appropriate random seed
                            rideProvider.createRiderCounterOffer(
                              rideRequestId: rideRequestId,
                              driverId: driverId,
                              amount: amount,
                              message: 'I can pay ₹${amount.toInt()}',
                              ensureResponse:
                                  true, // New parameter to ensure we get a response
                            );

                            // Hide the counter section after sending the offer
                            setState(() {
                              _counterOfferController.clear();
                              _showCounterOfferInput = false;
                            });
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: ${e.toString()}')),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Text(
                        'Send Counter Offer',
                        style: TextStyle(color: Colors.white),
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

    return SingleChildScrollView(
      child: Container(
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
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Ride Confirmed!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
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
                  _infoRow(
                    'Vehicle',
                    '${driver.carModel} • ${driver.carColor}',
                  ),
                  const SizedBox(height: 8),
                  _infoRow('License Plate', driver.carNumber),
                  const SizedBox(height: 8),
                  _infoRow('Fare Amount', '₹${acceptedOffer.amount.toInt()}'),
                  const SizedBox(height: 8),
                  _infoRow(
                    'Cab Type',
                    currentRideRequest.rideType == 'shared'
                        ? 'Shared Cab'
                        : 'Private Cab',
                  ),
                  // Show seats only for shared rides
                  if (currentRideRequest.rideType == 'shared') ...[
                    const SizedBox(height: 8),
                    _infoRow('Seats', '${currentRideRequest.seats}'),
                  ],
                  const SizedBox(height: 8),
                  _infoRow(
                    'Time',
                    currentRideRequest.scheduledTime != null
                        ? DateFormat(
                          'dd MMM, h:mm a',
                        ).format(currentRideRequest.scheduledTime!)
                        : 'Now',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.tracking);
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
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPaymentMethodSheet(FareOffer acceptedOffer, DriverModel driver) {
    // Access wallet provider to get current balance
    final walletProvider = Provider.of<WalletProvider>(context);
    final walletBalance = walletProvider.balance;

    // Get ride price
    final price = acceptedOffer.amount.toInt();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Method',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showPaymentSheet = false;
                  });
                },
                child: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Payment methods
          const Text(
            'Select Payment Method',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),

          // Cash option
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedPaymentMethod = 'cash';
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    _selectedPaymentMethod == 'cash'
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      _selectedPaymentMethod == 'cash'
                          ? AppTheme.primaryColor
                          : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.money, color: Colors.green),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cash Payment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Pay with cash on pickup',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedPaymentMethod == 'cash')
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Wallet option
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedPaymentMethod = 'wallet';
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    _selectedPaymentMethod == 'wallet'
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      _selectedPaymentMethod == 'wallet'
                          ? AppTheme.primaryColor
                          : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Wallet Payment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Balance: ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Image.asset(
                              'assets/icons/coin.png',
                              width: 16,
                              height: 16,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.monetization_on,
                                  color: Colors.amber,
                                  size: 16,
                                );
                              },
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$walletBalance',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color:
                                    walletBalance < price
                                        ? Colors.red
                                        : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_selectedPaymentMethod == 'wallet')
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
            ),
          ),

          if (_selectedPaymentMethod == 'wallet') ...[
            const SizedBox(height: 16),
            // Show price info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ride cost:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Row(
                    children: [
                      Image.asset(
                        'assets/icons/coin.png',
                        width: 20,
                        height: 20,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.monetization_on,
                            color: Colors.amber,
                            size: 20,
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$price',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (walletBalance < price) ...[
              const SizedBox(height: 8),
              const Text(
                'Insufficient balance! Please add money to your wallet or select cash payment.',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
            ],
          ],

          const SizedBox(height: 24),

          // Pay button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed:
                  _isLoading
                      ? null
                      : () => _processPayment(acceptedOffer, driver),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Text(
                        _selectedPaymentMethod == 'wallet'
                            ? 'Pay with Wallet'
                            : 'Pay with Cash',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  void _processPayment(FareOffer acceptedOffer, DriverModel driver) async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    final rideHistoryProvider = Provider.of<RideHistoryProvider>(
      context,
      listen: false,
    );

    setState(() {
      _showPaymentSheet = false;
    });

    if (_selectedPaymentMethod == 'wallet') {
      // Get ride price
      final price = acceptedOffer.amount.toInt();

      setState(() {
        _isLoading = true;
      });

      try {
        // Try to deduct money from wallet
        bool success = await walletProvider.deductMoney(
          price,
          'Ride with ${driver.name}',
        );

        if (success) {
          // The ride is already accepted, mark payment as completed
          setState(() {
            _paymentCompleted = true;
            _isLoading = false;
          });

          // Add ride to history
          await _saveRideToHistory(acceptedOffer, driver, 'wallet');
        } else {
          // Show low balance error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Insufficient balance in wallet!'),
              backgroundColor: Colors.red,
            ),
          );

          // Reopen payment sheet to try again
          setState(() {
            _showPaymentSheet = true;
            _isLoading = false;
          });
        }
      } catch (e) {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _showPaymentSheet = true;
            _isLoading = false;
          });
        }
      }
    } else {
      // Cash payment doesn't need processing, just show accepted info
      setState(() {
        _paymentCompleted = true;
      });

      // Add ride to history
      await _saveRideToHistory(acceptedOffer, driver, 'cash');
    }
  }

  // Save ride to history in Firebase
  Future<void> _saveRideToHistory(
    FareOffer acceptedOffer,
    DriverModel driver,
    String paymentMethod,
  ) async {
    try {
      final rideProvider = Provider.of<RideProvider>(context, listen: false);
      final rideHistoryProvider = Provider.of<RideHistoryProvider>(
        context,
        listen: false,
      );

      final currentRide = rideProvider.currentRideRequest;

      if (currentRide != null) {
        // Complete the ride in the ride provider
        rideProvider.completeRide(currentRide.id);

        // Add to ride history
        await rideHistoryProvider.addRideToHistory(
          rideRequest: currentRide,
          driverName: driver.name,
          fare: acceptedOffer.amount,
          paymentMethod: paymentMethod,
        );
      }
    } catch (e) {
      print('Error saving ride history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save ride history: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
