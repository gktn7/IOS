class Haber {
  final String title;
  final String? description;
  final String? content;
  final String? imageUrl;
  final String? url;

  Haber({
    required this.title,
    this.description,
    this.content,
    this.imageUrl,
    this.url,
  });

  factory Haber.fromJson(Map<String, dynamic> json) {
    return Haber(
      title: json['title'] ?? '',
      description: json['description'],
      content: json['content'],
      imageUrl: json['urlToImage'] ?? json['imageUrl'],
      url: json['url'],
    );
  }
}