import 'package:flutter/material.dart';
import '../../services/feed_service.dart';
import '../../models/feed_post_model.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../product/product_detail_screen.dart'; 
import 'create_post_screen.dart'; // [NEW]
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/comment_model.dart';

class SocialFeedScreen extends StatelessWidget {
  const SocialFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài đăng', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<List<FeedPost>>(
        stream: FeedService.instance.getFeedStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading feed: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Chưa có bài viết nào. Hãy là người đầu tiên!'));
          }

          final posts = snapshot.data!;
          return ListView.separated(
            itemCount: posts.length,
            separatorBuilder: (context, index) => const Divider(height: 1, thickness: 8, color: Color(0xFFF5F5F5)),
            itemBuilder: (context, index) {
              return FeedPostItem(post: posts[index]);
            },
          );
        },
      ),
    );
  }
}



class FeedPostItem extends StatefulWidget {
  final FeedPost post;

  const FeedPostItem({super.key, required this.post});

  @override
  State<FeedPostItem> createState() => _FeedPostItemState();
}

class _FeedPostItemState extends State<FeedPostItem> {
  void _showShopTheLook(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ShopTheLookSheet(linkedProducIds: widget.post.linkedProductIds),
    );
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _CommentsSheet(postId: widget.post.id),
    );
  }

  Future<void> _toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FeedService.instance.toggleLike(widget.post.id, user.uid, widget.post.likedBy);
    } catch (e) {
      debugPrint('Like error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isLiked = user != null && widget.post.likedBy.contains(user.uid);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(widget.post.authorAvatarUrl),
                radius: 20,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.post.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    DateFormat.yMMMd().format(widget.post.timestamp),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              if (user != null && user.uid == widget.post.authorId)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Xóa bài viết?'),
                          content: const Text('Hành động này không thể hoàn tác.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        try {
                          await FeedService.instance.deletePost(widget.post.id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã xóa bài viết')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi: $e')),
                            );
                          }
                        }
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Xóa bài viết', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                )
              else
                IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
            ],
          ),
        ),

        // Image with Tag Overlay
        Stack(
          children: [
            Image.network(
              widget.post.imageUrl,
              width: double.infinity,
              height: 400,
              fit: BoxFit.cover,
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => _showShopTheLook(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.black),
                      SizedBox(width: 4),
                      Text('Shop the Look', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // Actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.black, size: 28),
                onPressed: _toggleLike,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, size: 28),
                onPressed: () => _showComments(context),
              ),
            ],
          ),
        ),

        // Likes & Description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.post.likeCount} likes', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black),
                  children: [
                    TextSpan(text: '${widget.post.authorName} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: widget.post.description),
                  ],
                ),
              ),
              if (widget.post.commentCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: GestureDetector(
                    onTap: () => _showComments(context),
                    child: Text('Xem tất cả ${widget.post.commentCount} bình luận', style: const TextStyle(color: Colors.grey)),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final String postId;
  const _CommentsSheet({required this.postId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _controller = TextEditingController();

  Future<void> _sendComment() async {
    if (_controller.text.trim().isEmpty) return;
    try {
      await FeedService.instance.addComment(widget.postId, _controller.text.trim());
      _controller.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      debugPrint('Comment error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Bình luận', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<Comment>>(
              stream: FeedService.instance.getCommentsStream(widget.postId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final comments = snapshot.data!;
                if (comments.isEmpty) return const Center(child: Text('Chưa có bình luận nào'));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(comment.authorAvatarUrl),
                            radius: 16,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(comment.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat.yMMMd().format(comment.timestamp), // Short date implies logic needed for '2h' etc.
                                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(comment.content),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Thêm bình luận...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _sendComment,
                  child: const Text('Đăng', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopTheLookSheet extends StatelessWidget {
  final List<String> linkedProducIds;

  const _ShopTheLookSheet({required this.linkedProducIds});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      height: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const Text('Shop the Look', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Product>>(
              // For Demo: Fetch random active products instead of specific IDs since we only have mock IDs
              future: ProductService.instance.getProductsStream().first.then((list) => list.take(linkedProducIds.length + 1).toList()), 
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final products = snapshot.data!;
                if (products.isEmpty) return const Center(child: Text('Products not available'));

                return ListView.separated(
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return GestureDetector(
                      onTap: () {
                         Navigator.pop(context); // Close sheet
                         Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)));
                      },
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: product.images.isNotEmpty 
                                ? Image.network(product.images.first, width: 80, height: 80, fit: BoxFit.cover)
                                : Container(width: 80, height: 80, color: Colors.grey[200]),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text('đ${product.price}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
