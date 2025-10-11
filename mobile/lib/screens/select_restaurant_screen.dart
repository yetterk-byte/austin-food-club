import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../services/search_service.dart';

class SelectRestaurantScreen extends StatefulWidget {
  const SelectRestaurantScreen({super.key});

  @override
  State<SelectRestaurantScreen> createState() => _SelectRestaurantScreenState();
}

class _SelectRestaurantScreenState extends State<SelectRestaurantScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Restaurant> _results = [];
  bool _loading = false;

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    setState(() => _loading = true);
    final r = await SearchService.searchRestaurants(query: q);
    setState(() {
      _results = r;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Select a Restaurant'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search restaurants...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.orange),
                  onPressed: _search,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 16),
            if (_loading) const LinearProgressIndicator(color: Colors.orange),
            const SizedBox(height: 8),
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Text('Search to select a restaurant', style: TextStyle(color: Colors.grey[500])),
                    )
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                      itemBuilder: (context, index) {
                        final r = _results[index];
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              r.imageUrl ?? 'https://via.placeholder.com/56x56',
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(width: 56, height: 56, color: Colors.grey[800]),
                            ),
                          ),
                          title: Text(r.name, style: const TextStyle(color: Colors.white)),
                          subtitle: Text(r.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[400])),
                          onTap: () => Navigator.pop(context, r),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

