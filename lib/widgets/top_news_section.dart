import 'package:flutter/material.dart';

class TopNewsSection extends StatelessWidget {
  const TopNewsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top News',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey, // Shadow color
                  blurRadius: 8, // Softening the shadow
                  offset: const Offset(0, 4), // Moving the shadow down
                ),
              ],
            ),
            child: Column(
              children: [
                // A space for the top part with circles + players
                SizedBox(
                  height: 180,
                  child: Stack(
                    children: [
                      // Center the news image (e.g., 2 players)
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            // Match image
                            Image.asset(
                              'assets/images/news.jpg',
                              width: double.infinity,
                              height: 200, // Adjust image height
                              fit: BoxFit.cover,
                            ),
                            // Overlaid headline at bottom-left
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // The headline and text
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lakers acquire Luka from Maverick for AD in blockbuster trade',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus et blandit velit. Aliquam convallis nisi et sapien lacinia, sit amet pellentesque leo malesuada.',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
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
