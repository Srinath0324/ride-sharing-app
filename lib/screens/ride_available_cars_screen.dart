import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../constants/app_routes.dart';
import '../constants/app_theme.dart';
import '../widgets/location_button.dart';
import '../widgets/map_widget.dart';
import '../services/map_service.dart';
import '../providers/wallet_provider.dart';

class RideAvailableCarsScreen extends StatefulWidget {
  const RideAvailableCarsScreen({super.key});

  @override
  State<RideAvailableCarsScreen> createState() =>
      _RideAvailableCarsScreenState();
}

class _RideAvailableCarsScreenState extends State<RideAvailableCarsScreen> {
  int _selectedDriverIndex = -1;
  bool _showRideInfoSheet = false;
  bool _showBookingSuccessDialog = false;
  bool _showPaymentSheet = false;
  String _selectedPaymentMethod = 'cash'; // 'cash' or 'wallet'
  MapboxMap? _mapboxMap;

  // Mock data for drivers
  final List<Map<String, dynamic>> _availableDrivers = [
    {
      'name': 'Jane Cooper',
      'rating': 4.9,
      'price': '\$60',
      'time': '10 min',
      'seats': 4,
    },
    {
      'name': 'Esther Howard',
      'rating': 4.9,
      'price': '\$65',
      'time': '12 min',
      'seats': 4,
    },
    {
      'name': 'Leslie Alexander',
      'rating': 5.0,
      'price': '\$70',
      'time': '10 min',
      'seats': 4,
    },
    {
      'name': 'Robert Fox',
      'rating': 4.9,
      'price': '\$68',
      'time': '16 min',
      'seats': 4,
    },
  ];

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
  }

  void _showRideInformation() {
    if (_selectedDriverIndex != -1) {
      setState(() {
        _showRideInfoSheet = true;
      });
    }
  }

  void _confirmRide() {
    setState(() {
      _showRideInfoSheet = false;
      _showPaymentSheet = true;
    });
  }

  void _processPayment() {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    setState(() {
      _showPaymentSheet = false;
    });

    if (_selectedPaymentMethod == 'wallet') {
      // Get ride price - remove the $ and convert to int
      final priceText =
          _availableDrivers[_selectedDriverIndex]['price'] as String;
      final price = int.parse(priceText.replaceAll(RegExp(r'[^\d]'), ''));

      // Try to deduct money from wallet
      bool success = walletProvider.deductMoney(
        price,
        'Ride with ${_availableDrivers[_selectedDriverIndex]['name']}',
      );

      if (success) {
        // Show success dialog
        setState(() {
          _showBookingSuccessDialog = true;
        });
      } else {
        // Show low balance error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Insufficient balance in wallet!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Cash payment doesn't need processing, just show success
      setState(() {
        _showBookingSuccessDialog = true;
      });
    }
  }

  void _goToTracking() {
    setState(() {
      _showBookingSuccessDialog = false;
    });
    Navigator.pushNamed(context, AppRoutes.tracking);
  }

  void _backToHome() {
    setState(() {
      _showBookingSuccessDialog = false;
    });
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, Object?>? routeData =
        ModalRoute.of(context)?.settings.arguments as Map<String, Object?>?;
    final String from = routeData?['from']?.toString() ?? 'From location';
    final String to = routeData?['to']?.toString() ?? 'To location';

    return Scaffold(
      body: Stack(
        children: [
          // Map background
          RydeMapWidget(
            showUserLocation: true,
            onMapCreated: _onMapCreated,
            child:
                _selectedDriverIndex != -1
                    ? Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 250),
                        child: ElevatedButton(
                          onPressed: _showRideInformation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: const Text(
                            'Confirm Ride',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                    : null,
          ),

          // Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // App bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.arrow_back),
                              ),
                            ),
                            const Expanded(
                              child: Center(
                                child: Text(
                                  'Choose a Rider',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            // Empty space to center title
                            const SizedBox(width: 40),
                          ],
                        ),
                      ),

                      SizedBox(
                        height: constraints.maxHeight * 0.19,
                      ), // Spacer replacement
                      // Driver list container
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Driver list
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _availableDrivers.length,
                              itemBuilder: (context, index) {
                                final driver = _availableDrivers[index];
                                final isSelected =
                                    _selectedDriverIndex == index;

                                return GestureDetector(
                                  onTap: () {
                                    // Just select the driver, don't show ride info yet
                                    setState(() {
                                      _selectedDriverIndex = index;
                                    });
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(
                                      top: index == 0 ? 24 : 0,
                                      left: 16,
                                      right: 16,
                                      bottom: 16,
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? AppTheme.primaryColor
                                                  .withOpacity(0.1)
                                              : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? AppTheme.primaryColor
                                                : Colors.grey.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Driver Image
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                          child: Image.asset(
                                            'assets/icons/person.png',
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: 16),

                                        // Driver Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Name and rating
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      driver['name'],
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const Icon(
                                                    Icons.star,
                                                    color: Colors.amber,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    driver['rating'].toString(),
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),

                                              // Price, time and seats
                                              SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: Row(
                                                  children: [
                                                    // Price
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue[50],
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.attach_money,
                                                            size: 14,
                                                            color:
                                                                Colors
                                                                    .blue[700],
                                                          ),
                                                          const SizedBox(
                                                            width: 2,
                                                          ),
                                                          Text(
                                                            driver['price'],
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color:
                                                                  Colors
                                                                      .blue[700],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),

                                                    // Time
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[200],
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.access_time,
                                                            size: 14,
                                                            color:
                                                                Colors
                                                                    .grey[700],
                                                          ),
                                                          const SizedBox(
                                                            width: 2,
                                                          ),
                                                          Text(
                                                            driver['time'],
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color:
                                                                  Colors
                                                                      .grey[700],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),

                                                    // Seats
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[200],
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.event_seat,
                                                            size: 14,
                                                            color:
                                                                Colors
                                                                    .grey[700],
                                                          ),
                                                          const SizedBox(
                                                            width: 2,
                                                          ),
                                                          Text(
                                                            '${driver['seats']} Seats',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color:
                                                                  Colors
                                                                      .grey[700],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Car Image
                                        Container(
                                          margin: const EdgeInsets.only(
                                            left: 8,
                                          ),
                                          child: Image.asset(
                                            'assets/images/Suv car.png',
                                            width: 60,
                                            height: 40,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Location fields
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Column(
                                children: [
                                  // From field
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          from,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // To field
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          to,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // Map icon
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.map,
                                          color: Colors.grey,
                                          size: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Select Ride button
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed:
                                      _selectedDriverIndex != -1
                                          ? _showRideInformation
                                          : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    disabledBackgroundColor: Colors.grey[300],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                  ),
                                  child: const Text(
                                    'Select Ride',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Add location button at the specified position
          Positioned(
            bottom:
                MediaQuery.of(context).size.height *
                0.70, // Adjusted dynamically
            right: 20, // Positioned towards the left side
            child: LocationButton(size: 45, iconSize: 22),
          ),
          // Booking Success Dialog
          if (_showBookingSuccessDialog) _buildBookingSuccessDialog(),
        ],
      ),
      // Show appropriate bottom sheet
      bottomSheet:
          _showPaymentSheet
              ? _buildPaymentMethodSheet()
              : _showRideInfoSheet
              ? _buildRideInformationBottomSheet(
                _availableDrivers[_selectedDriverIndex],
                from,
                to,
              )
              : null,
    );
  }

  Widget _buildPaymentMethodSheet() {
    // Access wallet provider to get current balance
    final walletProvider = Provider.of<WalletProvider>(context);
    final walletBalance = walletProvider.balance;

    // Get ride price for display
    final priceText =
        _availableDrivers[_selectedDriverIndex]['price'] as String;
    final price = int.parse(priceText.replaceAll(RegExp(r'[^\d]'), ''));

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
                    _showRideInfoSheet = true; // Go back to ride info
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
              onPressed: _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: Text(
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

  Widget _buildRideInformationBottomSheet(
    Map<String, dynamic> driver,
    String from,
    String to,
  ) {
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
          // Dialog header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ride Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showRideInfoSheet = false;
                  });
                },
                child: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Driver image and name
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.asset(
                    'assets/icons/person.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  driver['name'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      driver['rating'].toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Ride details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Ride Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ride Price',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    Text(
                      driver['price'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Pickup time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pickup time',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    Text(
                      driver['time'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Car Seats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Car Seats',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    Text(
                      driver['seats'].toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // From and To locations
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 20,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  from,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  to,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _confirmRide,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: const Text(
                'Confirm Ride',
                style: TextStyle(
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

  Widget _buildBookingSuccessDialog() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 24),

              // Success message
              const Text(
                'Booking placed successfully',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Thank you for your booking! Your reservation has been successfully placed. Please proceed with your trip.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // Go Track button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _goToTracking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: const Text(
                    'Go Track',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Back Home button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: _backToHome,
                  child: const Text(
                    'Back Home',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
