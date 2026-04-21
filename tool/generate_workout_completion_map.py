from __future__ import annotations

import ast
import csv
import html
import json
import re
from pathlib import Path

SOURCE_CSV = Path('.tmp/exicon_export.csv')
SOURCE_VIDEO_URLS = Path('.tmp/exicon_video_urls.json')
TARGET_DART = Path('lib/workouts/workout_constants.dart')

BAD_NAMES = {
    '6\\ In the Air Tonight"',
    'Lochness \\Latte\\" Merkins"',
}

FILE_HEADER = '''import 'package:flutter/widgets.dart';

import '../l10n/l10n.dart';

enum ExerciseCategory {
    core,
    cardio,
    strength,
    chest,
    shoulders,
    legs,
    arms,
    coupon,
    fullBody;

    /// Returns a localized display label for this exercise category.
    String displayLabel(BuildContext context) {
        final l10n = L10n.of(context)!;
        return switch (this) {
            .core => l10n.exerciseCategoryCoreLabel,
            .cardio => l10n.exerciseCategoryCardioLabel,
            .strength => l10n.exerciseCategoryStrengthLabel,
            .chest => l10n.exerciseCategoryChestLabel,
            .shoulders => l10n.exerciseCategoryShouldersLabel,
            .legs => l10n.exerciseCategoryLegsLabel,
            .arms => l10n.exerciseCategoryArmsLabel,
            .coupon => l10n.exerciseCategoryCouponLabel,
            .fullBody => l10n.exerciseCategoryFullBodyLabel,
        };
    }
}

final class ExerciseEntry {
    final Set<ExerciseCategory> categories;
    final Uri? videoUrl;

    const ExerciseEntry({required this.categories, this.videoUrl});
}

'''


def read_current_names() -> list[str]:
    text = TARGET_DART.read_text()
    map_keys = [
        ast.literal_eval(f"'{match}'")
        for match in re.findall(r"^  '((?:\\'|[^'])*)':", text, flags=re.MULTILINE)
    ]
    if map_keys:
        return map_keys

    start = text.index('[')
    end = text.rindex(']')
    return ast.literal_eval(text[start : end + 1])


def read_existing_entries() -> dict[str, tuple[set[str], str | None]]:
    text = TARGET_DART.read_text()
    pattern = re.compile(
        r"^  '((?:\\'|[^'])*)': ExerciseEntry\((.*?)\),(?=\n  '(?:\\'|[^'])*': ExerciseEntry|\n};)",
        flags=re.MULTILINE | re.DOTALL,
    )
    entry_map: dict[str, tuple[set[str], str | None]] = {}

    for escaped_name, entry_body in pattern.findall(text):
        name = ast.literal_eval(f"'{escaped_name}'")
        categories_match = re.search(r'categories:\s*\{([^}]*)\}', entry_body)
        if not categories_match:
            continue
        raw_categories = categories_match.group(1)
        categories = {
            category.strip().lstrip('.')
            for category in raw_categories.split(',')
            if category.strip()
        }

        video_match = re.search(r"videoUrl:\s*Uri\.parse\('((?:\\'|[^'])*)'\)", entry_body)
        video_url = None
        if video_match:
            video_url = ast.literal_eval(f"'{video_match.group(1)}'")

        entry_map[name] = (categories, video_url)

    return entry_map


def clean_text(value: str) -> str:
    value = html.unescape(value)
    value = re.sub(r'<[^>]+>', ' ', value)
    value = value.replace('@', ' ')
    value = re.sub(r'\s+', ' ', value)
    return value.strip()


def normalize_name(value: str) -> str:
    return re.sub(r'\s+', ' ', value).strip().casefold()


def infer_categories(name: str, description: str) -> set[str]:
    text = f'{name} {description}'.lower()
    categories: set[str] = set()

    core_keywords = [
        'core', 'ab ', ' abs', 'crunch', 'sit-up', 'sit up', 'v-up', 'v up',
        'flutter', 'lbc', 'plank', 'peter parker', 'dolly', 'heels to heaven',
        'hollow', 'twist', 'supine', 'oblique', 'mountain climber', 'makhtar',
        'groiner', 'mary', '6-inch', '6 inch', 'heel toe'
    ]
    cardio_keywords = [
        'cardio', 'run', 'mosey', 'sprint', 'jog', 'shuffle', 'jump', 'hop',
        'suicide', 'skater', 'high knees', 'imperial walker', 'walker',
        'crawl', 'burpee', 'timed', 'distance', 'stairs', 'hill', 'bleacher'
    ]
    strength_keywords = [
        'strength', 'press', 'curl', 'row', 'deadlift', 'swing', 'thruster',
        'pull-up', 'pull up', 'dip', 'coupon', 'cinderblock', 'block', 'rock',
        'sandbag', 'carry', 'clean', 'military press', 'goblet', 'rifle'
    ]
    chest_keywords = [
        'chest', 'merkin', 'push-up', 'push up', 'derkin', 'irkin', 'webb',
        'floor press', 'chest press', 'fly', 'hand release'
    ]
    shoulders_keywords = [
        'shoulder', 'overhead press', 'military press', 'air press',
        'arm circle', 'arm-up', 'arm up', 'upright row', 'thruster',
        'front raise', 'lateral raise', 'handstand', 'balls to the wall'
    ]
    legs_keywords = [
        'legs', 'squat', 'lunge', 'blair', 'step-up', 'step up', 'wall sit',
        'calf', 'kick', 'walker', 'air chair', 'chair', 'leg hold', 'heel',
        'split jack', 'bunny', 'jump squat', 'broad jump'
    ]
    arms_keywords = [
        'arms', 'arm ', 'shoulder', 'tricep', 'bicep', 'merkin', 'push-up',
        'push up', 'derkin', 'irkin', 'webb', 'press', 'curl', 'row', 'dip',
        'pull-up', 'pull up', 'clap', 'hand release', 'hand-release'
    ]
    coupon_keywords = [
        'coupon', 'cinderblock', 'block', 'brick', 'sandbag', 'bucket',
        'ruck', 'rock', 'plate', 'dumbbell', 'kettle bell', 'kettlebell',
        'goblet', 'carry', 'farmer', 'weighted'
    ]
    full_body_keywords = [
        'full body', 'burpee', 'manmaker', 'blockee', 'murder bunny',
        'bear crawl', 'crawl', 'thruster', 'compound', 'get up', 'get-up',
        'clean and press', 'carry', 'devil', 'broad jump burpee'
    ]

    def any_keyword(keywords: list[str]) -> bool:
        return any(keyword in text for keyword in keywords)

    if any_keyword(core_keywords):
        categories.add('core')
    if any_keyword(cardio_keywords):
        categories.add('cardio')
    if any_keyword(strength_keywords):
        categories.add('strength')
    if any_keyword(chest_keywords):
        categories.add('chest')
    if any_keyword(shoulders_keywords):
        categories.add('shoulders')
    if any_keyword(legs_keywords):
        categories.add('legs')
    if any_keyword(arms_keywords):
        categories.add('arms')
    if any_keyword(coupon_keywords):
        categories.add('coupon')
    if any_keyword(full_body_keywords):
        categories.add('fullBody')

    if 'burpee' in text:
        categories.update({'cardio', 'fullBody'})
    if 'bear crawl' in text or 'crab walk' in text or 'crawl' in text:
        categories.update({'cardio', 'fullBody'})
    if 'merkin' in text or 'push-up' in text or 'push up' in text:
        categories.update({'arms', 'chest', 'strength'})
    if 'shoulder' in text or 'overhead press' in text or 'military press' in text:
        categories.update({'arms', 'shoulders', 'strength'})
    if 'squat' in text or 'lunge' in text or 'blair' in text:
        categories.add('legs')
    if 'press' in text or 'curl' in text or 'row' in text or 'deadlift' in text:
        categories.update({'strength', 'arms'})
    if 'coupon' in text or 'cinderblock' in text or 'block' in text or 'sandbag' in text:
        categories.update({'coupon', 'strength'})
    if 'plank' in text or 'sit-up' in text or 'sit up' in text or 'crunch' in text:
        categories.add('core')
    if 'jump' in text or 'hop' in text:
        categories.add('cardio')

    if len({'arms', 'legs', 'core'} & categories) >= 2 and 'cardio' in categories:
        categories.add('fullBody')
    if len({'arms', 'legs', 'core'} & categories) >= 2 and 'strength' in categories:
        categories.add('fullBody')

    if not categories:
        categories.add('fullBody')

    return categories


def build_category_map() -> dict[str, set[str]]:
    names = read_current_names()
    existing_entries = read_existing_entries()
    descriptions: dict[str, str] = {}

    if SOURCE_CSV.exists():
        with SOURCE_CSV.open(newline='') as f:
            for row in csv.DictReader(f):
                name = row['Name'].strip()
                if not name or name in BAD_NAMES:
                    continue
                descriptions[name.casefold()] = clean_text(row['Description'])

    result: dict[str, set[str]] = {}
    for name in names:
        description = descriptions.get(name.casefold())
        if description is None:
            result[name] = existing_entries.get(name, ({'fullBody'}, None))[0]
            continue
        result[name] = infer_categories(name, description)
    return result


def read_video_urls() -> dict[str, str]:
    current_name_lookup = {
        normalize_name(name): name
        for name in read_current_names()
    }
    existing_entries = read_existing_entries()
    video_urls = {
        current_name_lookup.get(normalize_name(name), name): video_url
        for name, (_, video_url) in existing_entries.items()
        if video_url is not None
    }

    if SOURCE_VIDEO_URLS.exists():
        loaded = json.loads(SOURCE_VIDEO_URLS.read_text())
        video_urls.update({
            current_name_lookup.get(normalize_name(str(name)), str(name)): str(url)
            for name, url in loaded.items()
            if isinstance(name, str)
            and isinstance(url, str)
            and url
            and normalize_name(str(name)) in current_name_lookup
        })

    return video_urls


def write_dart(category_map: dict[str, set[str]], video_urls: dict[str, str]) -> None:
    lines = [
        FILE_HEADER,
        '/// A map of workout token completion strings to exercise metadata.\n',
        'final Map<String, ExerciseEntry> workoutCompletions = {\n',
    ]

    for name in sorted(category_map, key=lambda value: (value.casefold(), value)):
        escaped_name = name.replace('\\', '\\\\').replace("'", "\\'")
        categories = ', '.join(
            f'.{category}'
            for category in sorted(category_map[name], key=lambda value: value)
        )
        video_url = video_urls.get(name)
        if video_url is None:
            lines.append(
                f"  '{escaped_name}': ExerciseEntry(categories: {{{categories}}}),\n"
            )
            continue

        escaped_video_url = video_url.replace('\\', '\\\\').replace("'", "\\'")
        lines.append(
            f"  '{escaped_name}': ExerciseEntry(categories: {{{categories}}}, videoUrl: Uri.parse('{escaped_video_url}')),\n"
        )

    lines.append('};\n')
    TARGET_DART.write_text(''.join(lines))


if __name__ == '__main__':
    write_dart(build_category_map(), read_video_urls())
