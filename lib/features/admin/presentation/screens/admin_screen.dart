import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/brand_logo.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  static const _orderStatuses = [
    'placed',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
  ];
  static const _paymentStatuses = ['pending', 'paid', 'failed', 'refunded'];

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _dashboard = const {};
  List<dynamic> _orders = const [];
  List<dynamic> _categories = const [];
  List<dynamic> _products = const [];
  int _selectedTab = 0;
  String _orderSearchQuery = '';
  String _orderStatusFilter = 'all';
  String _productSearchQuery = '';
  String _productSort = 'latest';
  Timer? _orderSearchDebounce;
  Timer? _productSearchDebounce;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  @override
  void dispose() {
    _orderSearchDebounce?.cancel();
    _productSearchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final dio = ref.read(dioProvider);

    try {
      final responses = await Future.wait([
        dio.get('/api/admin/dashboard'),
        dio.get('/api/admin/orders', queryParameters: {'page': 1, 'limit': 10}),
        dio.get('/api/categories'),
        dio.get('/api/products', queryParameters: {'page': 1, 'limit': 30}),
      ]);

      final dashboardResponse = responses[0].data as Map<String, dynamic>;
      final ordersResponse = responses[1].data as Map<String, dynamic>;
      final categoriesResponse = responses[2].data as Map<String, dynamic>;
      final productsResponse = responses[3].data as Map<String, dynamic>;

      setState(() {
        _dashboard = (dashboardResponse['data'] ?? {}) as Map<String, dynamic>;
        _orders = (ordersResponse['data'] as List<dynamic>? ?? []);
        _categories = (categoriesResponse['data'] as List<dynamic>? ?? []);
        _products = (productsResponse['data'] as List<dynamic>? ?? []);
        _isLoading = false;
      });
    } on DioException catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            error.response?.data?['message']?.toString() ??
            'Failed to load admin data';
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load admin data';
      });
    }
  }

  String _extractError(
    Object error, {
    String fallback = 'Something went wrong',
  }) {
    if (error is DioException) {
      return error.response?.data?['message']?.toString() ?? fallback;
    }
    return fallback;
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredOrders() {
    final query = _orderSearchQuery.trim().toLowerCase();
    final mapped = _orders
        .whereType<Map<String, dynamic>>()
        .where((order) {
          if (_orderStatusFilter == 'all') {
            return true;
          }
          final status = order['orderStatus']?.toString().toLowerCase() ?? '';
          return status == _orderStatusFilter;
        })
        .where((order) {
          if (query.isEmpty) {
            return true;
          }
          final user = order['user'] is Map<String, dynamic>
              ? (order['user'] as Map<String, dynamic>)
              : const <String, dynamic>{};
          final orderId = order['_id']?.toString().toLowerCase() ?? '';
          final name = user['name']?.toString().toLowerCase() ?? '';
          final email = user['email']?.toString().toLowerCase() ?? '';
          return orderId.contains(query) ||
              name.contains(query) ||
              email.contains(query);
        })
        .toList();

    mapped.sort((a, b) {
      final aTime = DateTime.tryParse(a['createdAt']?.toString() ?? '');
      final bTime = DateTime.tryParse(b['createdAt']?.toString() ?? '');
      if (aTime == null && bTime == null) {
        return 0;
      }
      if (aTime == null) {
        return 1;
      }
      if (bTime == null) {
        return -1;
      }
      return bTime.compareTo(aTime);
    });

    return mapped;
  }

  List<Map<String, dynamic>> _getFilteredProducts() {
    final query = _productSearchQuery.trim().toLowerCase();
    final mapped = _products.whereType<Map<String, dynamic>>().where((product) {
      if (query.isEmpty) {
        return true;
      }
      final title = product['title']?.toString().toLowerCase() ?? '';
      final brand = product['brand']?.toString().toLowerCase() ?? '';
      final category = _resolveProductCategoryName(product).toLowerCase();
      return title.contains(query) ||
          brand.contains(query) ||
          category.contains(query);
    }).toList();

    switch (_productSort) {
      case 'priceHigh':
        mapped.sort((a, b) => _toNum(b['price']).compareTo(_toNum(a['price'])));
        break;
      case 'priceLow':
        mapped.sort((a, b) => _toNum(a['price']).compareTo(_toNum(b['price'])));
        break;
      case 'stockLow':
        mapped.sort((a, b) => _toNum(a['stock']).compareTo(_toNum(b['stock'])));
        break;
      case 'latest':
        mapped.sort((a, b) {
          final aTime = DateTime.tryParse(a['createdAt']?.toString() ?? '');
          final bTime = DateTime.tryParse(b['createdAt']?.toString() ?? '');
          if (aTime == null && bTime == null) {
            return 0;
          }
          if (aTime == null) {
            return 1;
          }
          if (bTime == null) {
            return -1;
          }
          return bTime.compareTo(aTime);
        });
        break;
    }

    return mapped;
  }

  num _toNum(dynamic value) {
    if (value is num) {
      return value;
    }
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _resolveProductCategoryName(Map<String, dynamic> product) {
    if (product['category'] is Map<String, dynamic>) {
      return (product['category'] as Map<String, dynamic>)['name']
              ?.toString() ??
          'Uncategorized';
    }
    return 'Uncategorized';
  }

  Future<void> _showUpdateOrderSheet(Map<String, dynamic> order) async {
    final orderId = order['_id']?.toString() ?? '';
    var selectedOrderStatus = order['orderStatus']?.toString() ?? 'placed';
    var selectedPaymentStatus = order['paymentStatus']?.toString() ?? 'pending';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        var isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setLocalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Update Order Status',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedOrderStatus,
                    decoration: const InputDecoration(
                      labelText: 'Order Status',
                    ),
                    items: _orderStatuses
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setLocalState(() => selectedOrderStatus = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPaymentStatus,
                    decoration: const InputDecoration(
                      labelText: 'Payment Status',
                    ),
                    items: _paymentStatuses
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setLocalState(() => selectedPaymentStatus = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (orderId.isEmpty) {
                                    return;
                                  }
                                  setLocalState(() => isSubmitting = true);
                                  try {
                                    await ref
                                        .read(dioProvider)
                                        .patch(
                                          '/api/orders/$orderId/status',
                                          data: {
                                            'orderStatus': selectedOrderStatus,
                                            'paymentStatus':
                                                selectedPaymentStatus,
                                          },
                                        );
                                    if (!context.mounted) {
                                      return;
                                    }
                                    Navigator.pop(context);
                                    _showMessage('Order updated successfully');
                                    await _loadAdminData();
                                  } catch (error) {
                                    setLocalState(() => isSubmitting = false);
                                    _showMessage(
                                      _extractError(
                                        error,
                                        fallback: 'Failed to update order',
                                      ),
                                      isError: true,
                                    );
                                  }
                                },
                          child: isSubmitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showCategoryDialog({Map<String, dynamic>? existing}) async {
    final nameController = TextEditingController(
      text: existing?['name']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: existing?['description']?.toString() ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        var isSubmitting = false;
        var isActive = existing?['isActive'] as bool? ?? true;

        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Create Category' : 'Edit Category',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    if (existing != null) ...[
                      const SizedBox(height: 10),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active'),
                        value: isActive,
                        onChanged: (value) =>
                            setLocalState(() => isActive = value),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final description = descriptionController.text.trim();

                          if (name.isEmpty) {
                            _showMessage(
                              'Category name is required',
                              isError: true,
                            );
                            return;
                          }

                          setLocalState(() => isSubmitting = true);

                          try {
                            if (existing == null) {
                              await ref
                                  .read(dioProvider)
                                  .post(
                                    '/api/categories',
                                    data: {
                                      'name': name,
                                      if (description.isNotEmpty)
                                        'description': description,
                                    },
                                  );
                            } else {
                              await ref
                                  .read(dioProvider)
                                  .patch(
                                    '/api/categories/${existing['_id']}',
                                    data: {
                                      'name': name,
                                      'description': description,
                                      'isActive': isActive,
                                    },
                                  );
                            }
                            if (!context.mounted) {
                              return;
                            }
                            Navigator.pop(context);
                            _showMessage(
                              existing == null
                                  ? 'Category created'
                                  : 'Category updated',
                            );
                            await _loadAdminData();
                          } catch (error) {
                            setLocalState(() => isSubmitting = false);
                            _showMessage(
                              _extractError(
                                error,
                                fallback: 'Failed to save category',
                              ),
                              isError: true,
                            );
                          }
                        },
                  child: Text(existing == null ? 'Create' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteCategory(Map<String, dynamic> category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "${category['name'] ?? 'category'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    try {
      await ref.read(dioProvider).delete('/api/categories/${category['_id']}');
      _showMessage('Category deleted');
      await _loadAdminData();
    } catch (error) {
      _showMessage(
        _extractError(error, fallback: 'Failed to delete category'),
        isError: true,
      );
    }
  }

  Future<void> _showProductDialog() async {
    if (_categories.isEmpty) {
      _showMessage('Create a category first', isError: true);
      return;
    }

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final discountedPriceController = TextEditingController();
    final stockController = TextEditingController();
    final brandController = TextEditingController();
    final tagsController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        var isSubmitting = false;
        var selectedCategory = _categories.first['_id']?.toString() ?? '';

        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Create Product'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: discountedPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Discounted Price (optional)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stock'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: brandController,
                      decoration: const InputDecoration(
                        labelText: 'Brand (optional)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags (comma separated, optional)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _categories
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item['_id']?.toString() ?? '',
                              child: Text(item['name']?.toString() ?? '-'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setLocalState(() => selectedCategory = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          final description = descriptionController.text.trim();
                          final price = num.tryParse(
                            priceController.text.trim(),
                          );
                          final discounted = num.tryParse(
                            discountedPriceController.text.trim(),
                          );
                          final stock = int.tryParse(
                            stockController.text.trim(),
                          );
                          final tags = tagsController.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();

                          if (title.isEmpty ||
                              description.isEmpty ||
                              price == null ||
                              stock == null ||
                              selectedCategory.isEmpty) {
                            _showMessage(
                              'Title, description, price, stock and category are required',
                              isError: true,
                            );
                            return;
                          }

                          setLocalState(() => isSubmitting = true);

                          try {
                            final payload = <String, dynamic>{
                              'title': title,
                              'description': description,
                              'price': price,
                              'stock': stock,
                              'category': selectedCategory,
                              'tags': tags,
                            };
                            if (discounted != null) {
                              payload['discountedPrice'] = discounted;
                            }
                            if (brandController.text.trim().isNotEmpty) {
                              payload['brand'] = brandController.text.trim();
                            }

                            await ref
                                .read(dioProvider)
                                .post('/api/products', data: payload);
                            if (!context.mounted) {
                              return;
                            }
                            Navigator.pop(context);
                            _showMessage('Product created');
                            await _loadAdminData();
                          } catch (error) {
                            setLocalState(() => isSubmitting = false);
                            _showMessage(
                              _extractError(
                                error,
                                fallback: 'Failed to create product',
                              ),
                              isError: true,
                            );
                          }
                        },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _toggleProductPublish(Map<String, dynamic> product) async {
    final productId = product['_id']?.toString() ?? '';
    if (productId.isEmpty) {
      return;
    }

    try {
      await ref
          .read(dioProvider)
          .patch(
            '/api/products/$productId',
            data: {'isPublished': !(product['isPublished'] as bool? ?? true)},
          );
      _showMessage('Product updated');
      await _loadAdminData();
    } catch (error) {
      _showMessage(
        _extractError(error, fallback: 'Failed to update product'),
        isError: true,
      );
    }
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "${product['title'] ?? 'product'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    try {
      await ref.read(dioProvider).delete('/api/products/${product['_id']}');
      _showMessage('Product deleted');
      await _loadAdminData();
    } catch (error) {
      _showMessage(
        _extractError(error, fallback: 'Failed to delete product'),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'INR ');
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final totalUsers = (_dashboard['usersCount'] as num?)?.toInt() ?? 0;
    final totalProducts = (_dashboard['productsCount'] as num?)?.toInt() ?? 0;
    final totalOrders = (_dashboard['ordersCount'] as num?)?.toInt() ?? 0;
    final totalRevenue = (_dashboard['totalRevenue'] as num?) ?? 0;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandLogo(width: 96, showWordmark: false),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin',
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleLarge,
                  ),
                  Text(
                    'Control Center',
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadAdminData,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAdminData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          color: colorScheme.error,
                          size: 26,
                        ),
                        const SizedBox(height: 10),
                        Text(_errorMessage!, style: textTheme.bodyLarge),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _loadAdminData,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: _DashboardHero(
                      totalUsers: totalUsers,
                      totalOrders: totalOrders,
                      totalRevenue: currency.format(totalRevenue),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _TabPill(
                            label: 'Overview',
                            icon: Icons.dashboard_customize_outlined,
                            countLabel: '$totalProducts',
                            selected: _selectedTab == 0,
                            onTap: () => setState(() => _selectedTab = 0),
                          ),
                          const SizedBox(width: 8),
                          _TabPill(
                            label: 'Categories',
                            icon: Icons.category_outlined,
                            countLabel: '${_categories.length}',
                            selected: _selectedTab == 1,
                            onTap: () => setState(() => _selectedTab = 1),
                          ),
                          const SizedBox(width: 8),
                          _TabPill(
                            label: 'Products',
                            icon: Icons.inventory_2_outlined,
                            countLabel: '${_products.length}',
                            selected: _selectedTab == 2,
                            onTap: () => setState(() => _selectedTab = 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _selectedTab == 0
                        ? _buildOverviewTab(currency, dateFormat, textTheme)
                        : _selectedTab == 1
                        ? _buildCategoriesTab(textTheme)
                        : _buildProductsTab(textTheme, currency),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOverviewTab(
    NumberFormat currency,
    DateFormat dateFormat,
    TextTheme textTheme,
  ) {
    final filteredOrders = _getFilteredOrders();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      cacheExtent: 900,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text(
          'Dashboard Overview',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Track performance and manage orders quickly.',
          style: textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 880;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isWide ? 4 : 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: isWide ? 1.35 : 1.55,
              children: [
                _StatTile(
                  label: 'Users',
                  value: '${_dashboard['usersCount'] ?? 0}',
                  icon: Icons.people_outline,
                ),
                _StatTile(
                  label: 'Products',
                  value: '${_dashboard['productsCount'] ?? 0}',
                  icon: Icons.inventory_2_outlined,
                ),
                _StatTile(
                  label: 'Orders',
                  value: '${_dashboard['ordersCount'] ?? 0}',
                  icon: Icons.receipt_long_outlined,
                ),
                _StatTile(
                  label: 'Revenue',
                  value: currency.format(_dashboard['totalRevenue'] ?? 0),
                  icon: Icons.payments_outlined,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text(
              'Recent Orders',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${filteredOrders.length}',
                style: textTheme.labelMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 300,
              child: TextField(
                onChanged: (value) {
                  _orderSearchDebounce?.cancel();
                  _orderSearchDebounce = Timer(
                    const Duration(milliseconds: 220),
                    () {
                      if (!mounted) {
                        return;
                      }
                      setState(() => _orderSearchQuery = value);
                    },
                  );
                },
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  labelText: 'Search order, customer or email',
                ),
              ),
            ),
            SizedBox(
              width: 190,
              child: DropdownButtonFormField<String>(
                value: _orderStatusFilter,
                decoration: const InputDecoration(labelText: 'Order status'),
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('All')),
                  ..._orderStatuses.map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(
                        status[0].toUpperCase() + status.substring(1),
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _orderStatusFilter = value);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (filteredOrders.isEmpty)
          _EmptyPanel(
            icon: Icons.receipt_long_outlined,
            title: 'No matching orders',
            subtitle: 'Try changing the search or status filter.',
          )
        else
          ...filteredOrders.map((item) {
            final orderId = item['_id']?.toString() ?? '-';
            final amount = item['totalAmount'] ?? 0;
            final createdAtRaw = item['createdAt']?.toString();
            final createdAt = createdAtRaw != null
                ? DateTime.tryParse(createdAtRaw)
                : null;
            final user = item['user'] is Map<String, dynamic>
                ? (item['user'] as Map<String, dynamic>)
                : const <String, dynamic>{};

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order ${orderId.length > 10 ? orderId.substring(0, 10) : orderId}',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Customer: ${user['name'] ?? 'N/A'}',
                              style: textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        currency.format(amount),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Email: ${user['email'] ?? 'N/A'}',
                    style: textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoBadge(
                        icon: Icons.local_shipping_outlined,
                        label: '${item['orderStatus'] ?? 'pending'}',
                      ),
                      _InfoBadge(
                        icon: Icons.payments_outlined,
                        label: '${item['paymentStatus'] ?? 'pending'}',
                      ),
                    ],
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Placed: ${dateFormat.format(createdAt.toLocal())}',
                      style: textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => _showUpdateOrderSheet(item),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Update Status'),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCategoriesTab(TextTheme textTheme) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      cacheExtent: 800,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Categories',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${_categories.length}',
                style: textTheme.labelMedium,
              ),
            ),
            FilledButton.icon(
              onPressed: () => _showCategoryDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Category'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_categories.isEmpty)
          _EmptyPanel(
            icon: Icons.category_outlined,
            title: 'No categories found',
            subtitle: 'Create your first category to organize products.',
          )
        else
          ..._categories.map((item) {
            final category = item as Map<String, dynamic>;
            final isActive = category['isActive'] as bool? ?? true;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          category['name']?.toString() ?? '-',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _InfoBadge(
                        icon: isActive
                            ? Icons.check_circle_outline
                            : Icons.pause_circle_outline,
                        label: isActive ? 'Active' : 'Inactive',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category['description']?.toString().isNotEmpty == true
                        ? category['description'].toString()
                        : 'No description',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () =>
                            _showCategoryDialog(existing: category),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _deleteCategory(category),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildProductsTab(TextTheme textTheme, NumberFormat currency) {
    final filteredProducts = _getFilteredProducts();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      cacheExtent: 900,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Products',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${filteredProducts.length}/${_products.length}',
                style: textTheme.labelMedium,
              ),
            ),
            FilledButton.icon(
              onPressed: _showProductDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 300,
              child: TextField(
                onChanged: (value) {
                  _productSearchDebounce?.cancel();
                  _productSearchDebounce = Timer(
                    const Duration(milliseconds: 220),
                    () {
                      if (!mounted) {
                        return;
                      }
                      setState(() => _productSearchQuery = value);
                    },
                  );
                },
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  labelText: 'Search product, brand or category',
                ),
              ),
            ),
            SizedBox(
              width: 190,
              child: DropdownButtonFormField<String>(
                value: _productSort,
                decoration: const InputDecoration(labelText: 'Sort by'),
                items: const [
                  DropdownMenuItem(value: 'latest', child: Text('Latest')),
                  DropdownMenuItem(
                    value: 'priceHigh',
                    child: Text('Price: High to Low'),
                  ),
                  DropdownMenuItem(
                    value: 'priceLow',
                    child: Text('Price: Low to High'),
                  ),
                  DropdownMenuItem(
                    value: 'stockLow',
                    child: Text('Stock: Low to High'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _productSort = value);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (filteredProducts.isEmpty)
          _EmptyPanel(
            icon: Icons.inventory_2_outlined,
            title: 'No matching products',
            subtitle: 'Try changing search text or sort option.',
          )
        else
          ...filteredProducts.map((product) {
            final price = product['price'] ?? 0;
            final discounted = product['discountedPrice'];
            final isPublished = product['isPublished'] as bool? ?? true;
            final category = _resolveProductCategoryName(product);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['title']?.toString() ?? '-',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoBadge(
                        icon: Icons.sell_outlined,
                        label: currency.format(price),
                      ),
                      if (discounted != null)
                        _InfoBadge(
                          icon: Icons.discount_outlined,
                          label: currency.format(discounted),
                        ),
                      _InfoBadge(
                        icon: Icons.category_outlined,
                        label: category,
                      ),
                      _InfoBadge(
                        icon: Icons.inventory_outlined,
                        label: 'Stock ${product['stock'] ?? 0}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Published'),
                          const SizedBox(width: 6),
                          Switch.adaptive(
                            value: isPublished,
                            onChanged: (_) => _toggleProductPublish(product),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _deleteProduct(product),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 82;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.surface,
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          padding: EdgeInsets.all(compact ? 10 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.primary,
                  size: compact ? 18 : 20,
                ),
              ),
              SizedBox(height: compact ? 6 : 10),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.1),
              ),
              SizedBox(height: compact ? 1 : 2),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.totalUsers,
    required this.totalOrders,
    required this.totalRevenue,
  });

  final int totalUsers;
  final int totalOrders;
  final String totalRevenue;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.22),
            colorScheme.primaryContainer.withValues(alpha: 0.24),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.66),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.workspace_premium_outlined,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Store Performance',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroMetric(label: 'Users', value: '$totalUsers'),
              _HeroMetric(label: 'Orders', value: '$totalOrders'),
              _HeroMetric(label: 'Revenue', value: totalRevenue),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.icon,
    required this.countLabel,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String countLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.2)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? colorScheme.primary : colorScheme.onSurface,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.primary.withValues(alpha: 0.18)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  countLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
