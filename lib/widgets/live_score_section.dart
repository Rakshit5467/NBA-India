import 'package:flutter/material.dart';

class LiveScoreSection extends StatelessWidget {
  const LiveScoreSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Live Score" title
          Text(
            'Live Score',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 23
                ),
          ),
          const SizedBox(height: 8),

          // Main container (300px tall)
          Container(
            height: 300,
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
                // -------------------------
                // TOP: Match Image
                // -------------------------
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      // Match image
                      Image.asset(
                        'assets/images/match.jpg',
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                      // Overlaid headline (EXTRA BOLD)
                      Positioned(
                        bottom: 8,
                        left: 16,
                        child: Text(
                          'MAVS TAKE ON LAKERS',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900, // Extra bold
                                    color: Colors.white,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),

                // -------------------------
                // BOTTOM: Scoreboard
                // -------------------------
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    // Center everything horizontally
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Mavs logo + abbreviation (EXTRA BOLD)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/mavs.png',
                              height: 42,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'DAL',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900, // Extra bold
                                  ),
                            ),
                          ],
                        ),

                        // Spacing
                        const SizedBox(width: 24),

                        // Mavs Score (shifted up slightly)
                        Transform.translate(
                          offset: const Offset(0, -14),
                          child: Text(
                            '88',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),

                        // Spacing
                        const SizedBox(width: 25),

                        // Middle: Red dot + Q3 4:30 (shifted up slightly)
                        Transform.translate(
                          offset: const Offset(0, -14),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.circle,
                                  color: Colors.red, size: 8),
                              const SizedBox(width: 4),
                              Text(
                                'Q3 4:30',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                              ),
                            ],
                          ),
                        ),

                        // Spacing
                        const SizedBox(width: 24),

                        // Lakers Score (shifted up slightly)
                        Transform.translate(
                          offset: const Offset(0, -14),
                          child: Text(
                            '88',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),

                        // Spacing
                        const SizedBox(width: 24),

                        // Lakers logo + abbreviation (EXTRA BOLD)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/lakers.png',
                              height: 38,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'LAL',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900, // Extra bold
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
