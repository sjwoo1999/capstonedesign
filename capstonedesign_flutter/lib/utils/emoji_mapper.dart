String emojiMapper(String emotion) {
  switch (emotion.toLowerCase()) {
    case 'happiness':
      return '😄';
    case 'sadness':
      return '😢';
    case 'anger':
      return '😠';
    case 'surprise':
      return '😲';
    case 'disgust':
      return '🤢';
    case 'fear':
      return '😨';
    case 'neutral':
      return '😐';
    default:
      return '❓';
  }
}
