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

  @override
  void initState() {
    super.initState();
    _loadAdminData();
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

  String _extractError(Object error, {String fallback = 'Something went wrong'}) {
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
                    decoration: const InputDecoration(labelText: 'Order Status'),
                    items: _orderStatuses
                        .map((status) => DropdownMenuItem(value: status, child: Text(status)))
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
                    decoration: const InputDecoration(labelText: 'Payment Status'),
                    items: _paymentStatuses
                        .map((status) => DropdownMenuItem(value: status, child: Text(status)))
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
                          onPressed: isSubmitting ? null : () => Navigator.pop(context),
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
                                    await ref.read(dioProvider).patch(
                                          '/api/orders/$orderId/status',
                                          data: {
                                            'orderStatus': selectedOrderStatus,
                                            'paymentStatus': selectedPaymentStatus,
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
                                      _extractError(error, fallback: 'Failed to update order'),
                                      isError: true,
                                    );
                                  }
                                },
                          child: isSubmitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
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
              title: Text(existing == null ? 'Create Category' : 'Edit Category'),
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
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    if (existing != null) ...[
                      const SizedBox(height: 10),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active'),
                        value: isActive,
                        onChanged: (value) => setLocalState(() => isActive = value),
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
                            _showMessage('Category name is required', isError: true);
                            return;
                          }

                          setLocalState(() => isSubmitting = true);

                          try {
                            if (existing == null) {
                              await ref.read(dioProvider).post(
                                    '/api/categories',
                                    data: {
                                      'name': name,
                                      if (description.isNotEmpty) 'description': description,
                                    },
                                  );
                            } else {
                              await ref.read(dioProvider).patch(
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
                            _showMessage(existing == null
                                ? 'Category created'
                                : 'Category updated');
                            await _loadAdminData();
                          } catch (error) {
                            setLocalState(() => isSubmitting = false);
                            _showMessage(
                              _extractError(error, fallback: 'Failed to save category'),
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
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
                      decoration: const InputDecoration(labelText: 'Description'),
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
                      decoration: const InputDecoration(labelText: 'Discounted Price (optional)'),
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
                      decoration: const InputDecoration(labelText: 'Brand (optional)'),
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
                          final price = num.tryParse(priceController.text.trim());
                          final discounted =
                              num.tryParse(discountedPriceController.text.trim());
                          final stock = int.tryParse(stockController.text.trim());
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

                            await ref.read(dioProvider).post(
                                  '/api/products',
                                  data: payload,
                                );
                            if (!context.mounted) {
                              return;
                            }
                            Navigator.pop(context);
                            _showMessage('Product created');
                            await _loadAdminData();
                          } catch (error) {
                            setLocalState(() => isSubmitting = false);
                            _showMessage(
                              _extractError(error, fallback: 'Failed to create product'),
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
      await ref.read(dioProvider).patch(
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
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

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Row(
          children: [
            BrandLogo(width: 115, showWordmark: false),
            SizedBox(width: 10),
            Text('Admin'),
          ],
        ),
        actions: [
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_errorMessage!, style: textTheme.bodyLarge),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _loadAdminData,
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment<int>(
                          value: 0,
                          icon: Icon(Icons.dashboard_outlined),
                          label: Text('Overview'),
                        ),
                        ButtonSegment<int>(
                          value: 1,
                          icon: Icon(Icons.category_outlined),
                          label: Text('Categories'),
                        ),
                        ButtonSegment<int>(
                          value: 2,
                          icon: Icon(Icons.inventory_2_outlined),
                          label: Text('Products'),
                        ),
                      ],
                      selected: <int>{_selectedTab},
                      onSelectionChanged: (selected) {
                        setState(() {
                          _selectedTab = selected.first;
                        });
                      },
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text(
          'Dashboard Overview',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.55,
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
        ),
        const SizedBox(height: 20),
        Text(
          'Recent Orders',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (_orders.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No orders found.', style: textTheme.bodyMedium),
            ),
          )
        else
          ..._orders.map((order) {
            final item = order as Map<String, dynamic>;
            final orderId = item['_id']?.toString() ?? '-';
            final amount = item['totalAmount'] ?? 0;
            final createdAtRaw = item['createdAt']?.toString();
            final createdAt =
                createdAtRaw != null ? DateTime.tryParse(createdAtRaw) : null;
            final user = item['user'] is Map<String, dynamic>
                ? (item['user'] as Map<String, dynamic>)
                : const <String, dynamic>{};

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ${orderId.length > 10 ? orderId.substring(0, 10) : orderId}',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('Customer: ${user['name'] ?? 'N/A'}'),
                    Text('Email: ${user['email'] ?? 'N/A'}'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Chip(
                          label: Text(
                            'Status: ${item['orderStatus'] ?? 'pending'}',
                          ),
                        ),
                        Chip(
                          label: Text(
                            'Payment: ${item['paymentStatus'] ?? 'pending'}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total: ${currency.format(amount)}',
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (createdAt != null)
                      Text(
                        'Placed: ${dateFormat.format(createdAt.toLocal())}',
                        style: textTheme.bodySmall,
                      ),
                    const SizedBox(height: 8),
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
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCategoriesTab(TextTheme textTheme) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Categories',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            FilledButton.icon(
              onPressed: () => _showCategoryDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_categories.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No categories found.', style: textTheme.bodyMedium),
            ),
          )
        else
          ..._categories.map((item) {
            final category = item as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(category['name']?.toString() ?? '-'),
                subtitle: Text(
                  category['description']?.toString().isNotEmpty == true
                      ? category['description'].toString()
                      : 'No description',
                ),
                trailing: Wrap(
                  spacing: 6,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () => _showCategoryDialog(existing: category),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: () => _deleteCategory(category),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildProductsTab(TextTheme textTheme, NumberFormat currency) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Products',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            FilledButton.icon(
              onPressed: _showProductDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_products.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No products found.', style: textTheme.bodyMedium),
            ),
          )
        else
          ..._products.map((item) {
            final product = item as Map<String, dynamic>;
            final price = product['price'] ?? 0;
            final discounted = product['discountedPrice'];
            final isPublished = product['isPublished'] as bool? ?? true;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['title']?.toString() ?? '-',
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text('Price: ${currency.format(price)}'),
                    if (discounted != null)
                      Text('Discounted: ${currency.format(discounted)}'),
                    Text('Stock: ${product['stock'] ?? 0}'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Text('Published'),
                              const SizedBox(width: 6),
                              Switch.adaptive(
                                value: isPublished,
                                onChanged: (_) => _toggleProductPublish(product),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          onPressed: () => _deleteProduct(product),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ],
                ),
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

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(height: 10),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
