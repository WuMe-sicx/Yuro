import 'dart:math' as math;

enum SubtitleState {
  current,  // 当前播放的字幕
  waiting,  // 即将播放的字幕
  passed    // 已经播放过的字幕
}

class Subtitle {
  final Duration start;
  final Duration end;
  final String text;
  final int index;

  const Subtitle({
    required this.start,
    required this.end,
    required this.text,
    required this.index,
  });

  Subtitle? getNext(SubtitleList list) {
    if (index < list.subtitles.length - 1) {
      return list.subtitles[index + 1];
    }
    return null;
  }

  Subtitle? getPrevious(SubtitleList list) {
    if (index > 0) {
      return list.subtitles[index - 1];
    }
    return null;
  }

  @override
  String toString() => '$start --> $end: $text';
}

class SubtitleList {
  final List<Subtitle> subtitles;
  int _currentIndex = -1;

  SubtitleList(List<Subtitle> subtitles) 
    : subtitles = subtitles.asMap().entries.map(
        (entry) => Subtitle(
          start: entry.value.start,
          end: entry.value.end,
          text: entry.value.text,
          index: entry.key,
        )
      ).toList();

  SubtitleWithState? getCurrentSubtitle(Duration position) {
    if (subtitles.isEmpty) return null;

    // Edge: before first subtitle
    if (position < subtitles.first.start) {
      _currentIndex = 0;
      return SubtitleWithState(subtitles.first, SubtitleState.current);
    }

    // Edge: after last subtitle
    if (position > subtitles.last.end) {
      _currentIndex = subtitles.length - 1;
      return SubtitleWithState(subtitles.last, SubtitleState.passed);
    }

    // Quick path: check current index first (O(1))
    if (_currentIndex >= 0 && _currentIndex < subtitles.length) {
      final current = subtitles[_currentIndex];
      // Still within current subtitle
      if (position >= current.start && position <= current.end) {
        return SubtitleWithState(current, SubtitleState.current);
      }
      // Moved to next subtitle (sequential playback)
      if (_currentIndex + 1 < subtitles.length) {
        final next = subtitles[_currentIndex + 1];
        if (position >= next.start && position <= next.end) {
          _currentIndex = _currentIndex + 1;
          return SubtitleWithState(next, SubtitleState.current);
        }
        // In gap between current and next
        if (position > current.end && position < next.start) {
          return SubtitleWithState(current, SubtitleState.passed);
        }
      }
    }

    // Binary search path: for seeks or initial call (O(log n))
    int low = 0;
    int high = subtitles.length - 1;
    int bestMatch = 0;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      if (subtitles[mid].start <= position) {
        bestMatch = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    _currentIndex = bestMatch;
    final subtitle = subtitles[bestMatch];

    if (position >= subtitle.start && position <= subtitle.end) {
      return SubtitleWithState(subtitle, SubtitleState.current);
    }
    return SubtitleWithState(subtitle, SubtitleState.passed);
  }

  List<Subtitle> getSubtitlesInRange(int start, int count) {
    if (start < 0 || start >= subtitles.length) return [];
    final end = math.min(start + count, subtitles.length);
    return subtitles.sublist(start, end);
  }

  (Subtitle?, Subtitle?, Subtitle?) getCurrentContext() {
    if (_currentIndex == -1) return (null, null, null);
    
    final previous = _currentIndex > 0 ? subtitles[_currentIndex - 1] : null;
    final current = subtitles[_currentIndex];
    final next = _currentIndex < subtitles.length - 1 ? subtitles[_currentIndex + 1] : null;
    
    return (previous, current, next);
  }

  static SubtitleList parse(String vttContent) {
    final lines = vttContent.split('\n');
    final subtitles = <Subtitle>[];
    
    int i = 0;
    while (i < lines.length && !lines[i].contains('-->')) {
      i++;
    }

    while (i < lines.length) {
      final line = lines[i].trim();
      
      if (line.contains('-->')) {
        final times = line.split('-->');
        if (times.length == 2) {
          final start = _parseTimestamp(times[0].trim());
          final end = _parseTimestamp(times[1].trim());
          
          i++;
          String text = '';
          while (i < lines.length && lines[i].trim().isNotEmpty) {
            if (text.isNotEmpty) text += '\n';
            text += lines[i].trim();
            i++;
          }
          
          if (start != null && end != null && text.isNotEmpty) {
            subtitles.add(Subtitle(
              start: start,
              end: end,
              text: text,
              index: subtitles.length,
            ));
          }
        }
      }
      i++;
    }

    return SubtitleList(subtitles);
  }

  static Duration? _parseTimestamp(String timestamp) {
    try {
      final parts = timestamp.split(':');
      if (parts.length == 3) {
        final seconds = parts[2].split('.');
        return Duration(
          hours: int.parse(parts[0]),
          minutes: int.parse(parts[1]),
          seconds: int.parse(seconds[0]),
          milliseconds: seconds.length > 1 ? int.parse(seconds[1].padRight(3, '0')) : 0,
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}

class SubtitleWithState {
  final Subtitle subtitle;
  final SubtitleState state;

  SubtitleWithState(this.subtitle, this.state);
} 