import 'package:flutter/widgets.dart';

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

/// A map of workout token completion strings to exercise metadata.
final Map<String, ExerciseEntry> workoutCompletions = {
  '1775': ExerciseEntry(categories: {.cardio, .fullBody, .legs}),
  '1984': ExerciseEntry(categories: {.cardio, .legs}),
  '1st & 10': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .strength},
  ),
  '20% Bert variation': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .chest,
      .core,
      .coupon,
      .fullBody,
      .legs,
      .strength,
    },
  ),
  '21s': ExerciseEntry(categories: {.cardio, .legs}),
  '4x4s': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .strength},
  ),
  '5-minute miracle': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .chest,
      .core,
      .fullBody,
      .legs,
      .shoulders,
      .strength,
    },
  ),
  '6" In the Air Tonight': ExerciseEntry(categories: {.fullBody}),
  '7 of Diamonds': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .legs, .strength},
  ),
  '7220': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .legs, .strength},
  ),
  'Abs are all you need': ExerciseEntry(categories: {.cardio, .core}),
  'Absolution': ExerciseEntry(
    categories: {.cardio, .core},
    videoUrl: Uri.parse('https://www.youtube.com/embed/RXUk8NVx-8g'),
  ),
  'Abyss merkin': ExerciseEntry(
    categories: {.arms, .chest, .coupon, .strength},
  ),
  'Acey doucey': ExerciseEntry(categories: {.fullBody}),
  'Agassis': ExerciseEntry(categories: {.cardio}),
  'Aiken legs': ExerciseEntry(categories: {.cardio, .legs}),
  'Air drama': ExerciseEntry(
    categories: {.legs},
    videoUrl: Uri.parse('https://www.youtube.com/embed/JZN8kPqFAKc'),
  ),
  'Air squared': ExerciseEntry(
    categories: {.arms, .legs},
    videoUrl: Uri.parse('https://www.youtube.com/embed/JZN8kPqFAKc'),
  ),
  'Airport security': ExerciseEntry(categories: {.coupon, .strength}),
  'Al Gore': ExerciseEntry(categories: {.core, .legs}),
  'Alabama ass-kickers': ExerciseEntry(
    categories: {.legs},
    videoUrl: Uri.parse('https://www.youtube.com/embed/M9Q5oIaSaRo'),
  ),
  'Alabama prom dates': ExerciseEntry(categories: {.fullBody}),
  'ALARM': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .chest,
      .core,
      .coupon,
      .fullBody,
      .legs,
      .shoulders,
      .strength,
    },
  ),
  'Alarm clock': ExerciseEntry(
    categories: {.arms, .cardio, .core, .fullBody, .legs},
    videoUrl: Uri.parse('https://www.youtube.com/embed/s61-KcIPW24'),
  ),
  'Albatross wings': ExerciseEntry(categories: {.arms, .shoulders, .strength}),
  'All about the Benjamins': ExerciseEntry(categories: {.fullBody}),
  'Alligator merkin': ExerciseEntry(
    categories: {.arms, .chest, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/scdCilYJh-Y'),
  ),
  'Alphabet (or ABCs)': ExerciseEntry(categories: {.core}),
  'Alpine mountain climbers': ExerciseEntry(
    categories: {.core},
    videoUrl: Uri.parse('https://www.youtube.com/embed/j1G9nu96gKE'),
  ),
  'Alternating shoulder taps': ExerciseEntry(
    categories: {.arms, .chest, .shoulders, .strength},
  ),
  'Alternating side squats': ExerciseEntry(categories: {.legs}),
  'American Hammer': ExerciseEntry(
    categories: {.core, .coupon, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/Kz5iZOqQslo'),
  ),
  'American hammers': ExerciseEntry(categories: {.fullBody}),
  'Amish wobble': ExerciseEntry(
    categories: {.coupon, .fullBody, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/5212uNjqmho'),
  ),
  'Angle grinder': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/Nz9ZiceqSsU'),
  ),
  'Animal style squats': ExerciseEntry(
    categories: {.arms, .fullBody, .legs, .strength},
  ),
  'Another Level legs': ExerciseEntry(categories: {.legs}),
  'Apollo Creed burpee': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .coupon, .fullBody, .strength},
  ),
  'Apolo Anton Oh No!': ExerciseEntry(
    categories: {.cardio, .coupon, .legs, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/4tFnPeALL4s'),
  ),
  'Apolo Ohno': ExerciseEntry(
    categories: {.cardio},
    videoUrl: Uri.parse('https://www.youtube.com/embed/j2RcpcwLZPQ'),
  ),
  'Apple turnover': ExerciseEntry(
    categories: {.arms, .cardio, .core, .fullBody, .strength},
  ),
  'Around the world': ExerciseEntry(
    categories: {.core, .coupon, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/S_M3qoW1vjk'),
  ),
  'Ascending curb crawl': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody},
  ),
  'Ascending testicles': ExerciseEntry(
    categories: {.arms, .chest, .shoulders, .strength},
  ),
  'ATMs': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .shoulders, .strength},
  ),
  'Aura farmer': ExerciseEntry(
    categories: {.arms, .coupon, .fullBody, .legs, .shoulders, .strength},
  ),
  'Aussie burpees': ExerciseEntry(categories: {.cardio, .core, .fullBody}),
  'Austin ass-kickers': ExerciseEntry(categories: {.arms, .legs}),
  'Australian mountain climber': ExerciseEntry(
    categories: {.core, .shoulders},
    videoUrl: Uri.parse('https://www.youtube.com/embed/RBXs9tJ9fyc'),
  ),
  'Australian snow angels': ExerciseEntry(
    categories: {.arms, .fullBody, .legs, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/dBzU0Hmu3Y4'),
  ),
  'B.O.M.B.S.': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .legs, .strength},
  ),
  'Baba O\'Riley': ExerciseEntry(categories: {.cardio, .legs}),
  'Back plank (aka knalp)': ExerciseEntry(categories: {.arms, .core, .legs}),
  'Back Widow': ExerciseEntry(categories: {.arms, .shoulders, .strength}),
  'Ballerinas - Toe Squats': ExerciseEntry(
    categories: {.arms, .legs},
    videoUrl: Uri.parse('https://www.youtube.com/embed/eDIOcvLeFpg'),
  ),
  'Balls to the Wall': ExerciseEntry(
    categories: {.shoulders},
    videoUrl: Uri.parse('https://www.youtube.com/embed/1OjiaAzDUi0'),
  ),
  'Balls to the Wall Crawl': ExerciseEntry(
    categories: {.cardio, .fullBody, .shoulders},
  ),
  'Baryshnikov Squats': ExerciseEntry(
    categories: {.legs},
    videoUrl: Uri.parse('https://www.youtube.com/embed/_eV69RUrjJE'),
  ),
  'Bat Wings (aka the Martina Special)': ExerciseEntry(
    categories: {.arms, .shoulders},
    videoUrl: Uri.parse('https://www.youtube.com/embed/KFF6dKL9MTk'),
  ),
  'Bataan Death Crawl': ExerciseEntry(
    categories: {.arms, .cardio, .fullBody, .shoulders, .strength},
  ),
  'Bataan Death March': ExerciseEntry(
    categories: {.arms, .cardio, .fullBody, .shoulders, .strength},
  ),
  'Bay City Scissors': ExerciseEntry(
    categories: {.arms, .core, .fullBody, .legs, .strength},
  ),
  'Beach bunnies': ExerciseEntry(categories: {.fullBody}),
  'Bear Brawl': ExerciseEntry(
    categories: {.arms, .cardio, .fullBody, .shoulders, .strength},
  ),
  'Bear Crawl': ExerciseEntry(
    categories: {.cardio, .core, .fullBody, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/l12vz6FmZtQ'),
  ),
  'Bear Crawl 1-2-3': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .legs, .strength},
  ),
  'Bear Crawl Burpees': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/mK8W3uccb8c'),
  ),
  'Bear Crawl Inch Worm': ExerciseEntry(
    categories: {.cardio, .core, .fullBody},
  ),
  'Bear Crawl Merkin': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .strength},
  ),
  'Bear Crawl Ring of Fire': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .strength},
  ),
  'Bear Crawl Snake': ExerciseEntry(categories: {.cardio, .core, .fullBody}),
  'Bear Hold': ExerciseEntry(categories: {.cardio, .core, .fullBody}),
  'Bear With Me': ExerciseEntry(categories: {.arms, .core, .legs}),
  'Bearmuda Triangle': ExerciseEntry(categories: {.cardio, .fullBody}),
  'Bearpees': ExerciseEntry(categories: {.cardio, .fullBody}),
  'Bears & Blocks': ExerciseEntry(
    categories: {.cardio, .coupon, .fullBody, .legs, .strength},
  ),
  'Bearway to Heaven': ExerciseEntry(categories: {.cardio, .fullBody}),
  'Beat The Clock': ExerciseEntry(categories: {.arms, .chest, .strength}),
  'Beep Test/Highlander': ExerciseEntry(categories: {.cardio}),
  'Belching': ExerciseEntry(categories: {.cardio, .core, .fullBody}),
  'Bent Jacob': ExerciseEntry(categories: {.fullBody}),
  'Berkins': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .coupon, .fullBody, .legs, .strength},
  ),
  'Bernie Sanders': ExerciseEntry(categories: {.cardio}),
  'Big Bang': ExerciseEntry(
    categories: {.arms, .cardio, .core, .fullBody, .shoulders, .strength},
  ),
  'Big Boy Knock Out': ExerciseEntry(categories: {.core, .fullBody}),
  'Big Boy Sit-up-Ups (aka, Bissyous)': ExerciseEntry(
    categories: {.chest, .core},
  ),
  'Big boy sit-ups': ExerciseEntry(categories: {.core}),
  'Big O': ExerciseEntry(categories: {.legs, .strength}),
  'Bill Murray': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .legs, .strength},
  ),
  'Billy Madison': ExerciseEntry(categories: {.cardio}),
  'Billy Run': ExerciseEntry(categories: {.cardio}),
  'Bizarro': ExerciseEntry(
    categories: {.fullBody},
    videoUrl: Uri.parse('https://www.youtube.com/embed/7Zk3-c7wPsI'),
  ),
  'Black Jack': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .strength},
  ),
  'Black Snake': ExerciseEntry(categories: {.cardio}),
  'Blades of Steel': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .shoulders, .strength},
  ),
  'Blart': ExerciseEntry(categories: {.core, .legs}),
  'Blimps': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .legs, .strength},
  ),
  'Block a Dock': ExerciseEntry(categories: {.coupon, .strength}),
  'Block Burners': ExerciseEntry(
    categories: {.arms, .chest, .coupon, .strength},
  ),
  'Block Webbs': ExerciseEntry(
    categories: {.arms, .chest, .coupon, .shoulders, .strength},
  ),
  'Block-Over Burpees': ExerciseEntry(
    categories: {.cardio, .coupon, .fullBody, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/fSv0keQNisI'),
  ),
  'Blockee': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .coupon, .fullBody, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/ChWzrJ4BpEQ'),
  ),
  'Blocko Motor City Shuffle (BMCS)': ExerciseEntry(
    categories: {.cardio, .coupon, .strength},
  ),
  'Blocktanamo': ExerciseEntry(
    categories: {.arms, .cardio, .coupon, .strength},
  ),
  'Blue Falcon': ExerciseEntry(categories: {.cardio, .fullBody}),
  'Boat Canoe': ExerciseEntry(
    categories: {.arms, .chest, .legs},
    videoUrl: Uri.parse('https://www.youtube.com/embed/bx5Sr2DaaAQ'),
  ),
  'Bobby Hurley': ExerciseEntry(categories: {.arms, .cardio, .fullBody, .legs}),
  'Bodies Hit the Floor': ExerciseEntry(
    categories: {.arms, .core, .fullBody, .legs, .strength},
  ),
  'Body Bag Builders': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'Body Builders': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .legs, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/tchbusf8M1k'),
  ),
  'Bohemian rhapsody': ExerciseEntry(categories: {.fullBody}),
  'Bohemian Whap-sody': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .coupon, .fullBody, .legs, .strength},
  ),
  'Bojangles Biscuit': ExerciseEntry(categories: {.cardio, .fullBody}),
  'Bolt 45s': ExerciseEntry(categories: {.cardio, .legs}),
  'Bone The Fish': ExerciseEntry(categories: {.cardio}),
  'Bonnie Blairs': ExerciseEntry(
    categories: {.cardio, .legs},
    videoUrl: Uri.parse('https://www.youtube.com/embed/eFLEBOm4Upo'),
  ),
  'Boo Boo Bear Crawl': ExerciseEntry(
    categories: {.cardio, .fullBody},
    videoUrl: Uri.parse('https://www.youtube.com/embed/y2Sz5-Q-V-c'),
  ),
  'Booyah! Merkin': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .chest,
      .core,
      .fullBody,
      .shoulders,
      .strength,
    },
  ),
  'BOPO': ExerciseEntry(categories: {.cardio, .core, .fullBody}),
  'Born to Lunge': ExerciseEntry(categories: {.cardio, .legs}),
  'Bottom Feeders': ExerciseEntry(categories: {.cardio, .core, .fullBody}),
  'Boxcutter': ExerciseEntry(categories: {.core, .legs}),
  'Breakdancer Merkin': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .legs, .shoulders, .strength},
  ),
  'Brick by Brick Shuttlerun (BBBS)': ExerciseEntry(
    categories: {.cardio, .core, .coupon, .fullBody},
  ),
  'Brickbarrow': ExerciseEntry(
    categories: {.arms, .cardio, .coupon, .fullBody, .legs, .strength},
  ),
  'Bridge of Hate': ExerciseEntry(
    categories: {.arms, .cardio, .shoulders, .strength},
  ),
  'Bridge Over The Nest': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .legs, .strength},
  ),
  'Broad Jump Burpee': ExerciseEntry(categories: {.cardio, .fullBody, .legs}),
  'Broken bicycle': ExerciseEntry(
    categories: {.cardio, .core, .fullBody, .legs},
    videoUrl: Uri.parse('https://www.youtube.com/embed/jCYDqX4wjEU'),
  ),
  'Broken Wheelbarrow': ExerciseEntry(
    categories: {.arms, .core, .fullBody, .legs, .strength},
  ),
  'Bropee': ExerciseEntry(categories: {.cardio, .fullBody, .legs}),
  'Bruce Lee': ExerciseEntry(categories: {.cardio, .core, .fullBody, .legs}),
  'Bucket Brigade': ExerciseEntry(
    categories: {.arms, .cardio, .coupon, .shoulders, .strength},
  ),
  'Bucket Brigade Lunge': ExerciseEntry(
    categories: {.core, .coupon, .fullBody, .legs, .strength},
  ),
  'Bulgarian split squat': ExerciseEntry(
    categories: {.core, .coupon, .fullBody, .legs, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/eqTO9BKvbPg'),
  ),
  'Burp & Groin': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .strength},
  ),
  'Burp & Merk': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .strength},
  ),
  'Burp Back Mountain': ExerciseEntry(categories: {.cardio, .fullBody}),
  'Burp-Ups': ExerciseEntry(
    categories: {.arms, .cardio, .core, .fullBody, .strength},
  ),
  'Burpee': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .legs, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/NEftzEpvkrA'),
  ),
  'Burpee Dans': ExerciseEntry(categories: {.cardio, .core, .fullBody, .legs}),
  'Burpee Mile': ExerciseEntry(categories: {.cardio, .fullBody}),
  'Burpee Sandwich': ExerciseEntry(
    categories: {.cardio, .coupon, .fullBody, .strength},
  ),
  'Burpees': ExerciseEntry(categories: {.cardio, .fullBody}),
  'Burpo': ExerciseEntry(
    categories: {.cardio, .chest, .core, .fullBody, .legs},
  ),
  'Butkus': ExerciseEntry(categories: {.legs}),
  'Butt kickers': ExerciseEntry(categories: {.legs}),
  'Butterfly Sit-up': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .legs, .strength},
  ),
  'C2C': ExerciseEntry(categories: {.cardio, .core}),
  'Cactus Jump Squat': ExerciseEntry(
    categories: {.cardio, .coupon, .legs, .strength},
  ),
  'Capri Lap': ExerciseEntry(categories: {.cardio}),
  'Captain Morgan': ExerciseEntry(categories: {.core}),
  'Captain Therkin': ExerciseEntry(categories: {.arms, .chest, .strength}),
  'Captain Thor': ExerciseEntry(categories: {.core}),
  'Carioca': ExerciseEntry(categories: {.cardio, .core}),
  'Carolina dry docks': ExerciseEntry(
    categories: {.arms, .chest, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/KwJPq0SP9sQ'),
  ),
  'Catalina Wine Mixer': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'Catapillar Walk': ExerciseEntry(categories: {.arms, .fullBody}),
  'Catch Me If You Can': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .strength},
  ),
  'Catch Us If You Can': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .strength},
  ),
  'Caterpillar': ExerciseEntry(categories: {.cardio, .core}),
  'Charles Bronson': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .chest,
      .core,
      .coupon,
      .fullBody,
      .legs,
      .strength,
    },
  ),
  'Cheerleader': ExerciseEntry(categories: {.legs}),
  'Cheerleader Merkin': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .strength},
  ),
  'CHerkin': ExerciseEntry(categories: {.arms, .chest, .strength}),
  'Chicken Peckers': ExerciseEntry(categories: {.arms, .shoulders, .strength}),
  'Chilcutt Peter Parkers': ExerciseEntry(categories: {.arms, .core}),
  'Chilcutts': ExerciseEntry(categories: {.core}),
  'Chilly Broad Jumps': ExerciseEntry(categories: {.cardio, .legs}),
  'Chilly Jacks': ExerciseEntry(categories: {.cardio, .core}),
  'Chinook Squats': ExerciseEntry(categories: {.arms, .legs, .shoulders}),
  'Chuck Norris Merkins': ExerciseEntry(categories: {.arms, .chest, .strength}),
  'Chumbaburpee': ExerciseEntry(categories: {.cardio, .fullBody}),
  'Ciabatta': ExerciseEntry(categories: {.fullBody}),
  'Cindy': ExerciseEntry(
    categories: {.arms, .chest, .fullBody, .legs, .strength},
  ),
  'Cindy Crawford': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .legs, .strength},
  ),
  'Circle Burp': ExerciseEntry(categories: {.cardio, .fullBody}),
  'Classic Sit-Up': ExerciseEntry(categories: {.chest, .core}),
  'Clerkin': ExerciseEntry(categories: {.arms, .chest, .strength}),
  'Cliff Hanger Arm-ups': ExerciseEntry(
    categories: {.arms, .chest, .fullBody, .legs, .shoulders, .strength},
  ),
  'Cliff Hanger Merkins': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .legs, .strength},
  ),
  'Climate Change': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .legs, .strength},
  ),
  'Clock Merkins': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .strength},
  ),
  'Clock Pendulum': ExerciseEntry(categories: {.coupon, .strength}),
  'Clowney': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .legs, .strength},
  ),
  'Clurpee': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .strength},
  ),
  'Coach': ExerciseEntry(categories: {.arms, .cardio, .strength}),
  'Cocaine bear crawl': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/VCusCUNzD9E'),
  ),
  'Cockroach Resurrection': ExerciseEntry(
    categories: {.arms, .chest, .core, .legs},
  ),
  'Code Red': ExerciseEntry(categories: {.cardio, .fullBody}),
  'Colonel Trautman': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .strength},
  ),
  'Colt 45': ExerciseEntry(categories: {.arms, .coupon, .shoulders, .strength}),
  'Commando Jacks': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .legs, .strength},
  ),
  'Concrete Canoe': ExerciseEntry(
    categories: {.chest, .core, .coupon, .fullBody, .legs, .strength},
  ),
  'Contra Burpees': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .legs, .strength},
  ),
  'Control Freak Merkins': ExerciseEntry(
    categories: {.arms, .chest, .strength},
  ),
  'Conveyor Belt': ExerciseEntry(categories: {.fullBody}),
  'Cooler / Super Duper Cooler': ExerciseEntry(
    categories: {.arms, .core, .legs},
  ),
  'Copperhead Lunge': ExerciseEntry(categories: {.legs}),
  'Copperhead Merkins': ExerciseEntry(
    categories: {.arms, .chest, .fullBody, .legs, .strength},
  ),
  'Copperhead Squat': ExerciseEntry(categories: {.legs}),
  'Cosey': ExerciseEntry(categories: {.cardio, .coupon, .strength}),
  'Cotton-eyed Joe': ExerciseEntry(categories: {.cardio}),
  'Coupon Crucible': ExerciseEntry(
    categories: {.arms, .coupon, .shoulders, .strength},
  ),
  'Coupon Curl': ExerciseEntry(
    categories: {.arms, .coupon, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/NQeXE4jAMB0'),
  ),
  'Coupon Kettle Bell Swing': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .chest,
      .core,
      .coupon,
      .fullBody,
      .legs,
      .shoulders,
      .strength,
    },
    videoUrl: Uri.parse('https://www.youtube.com/embed/2DjPUTF8nAc'),
  ),
  'Coupon Military Press': ExerciseEntry(
    categories: {.arms, .core, .coupon, .fullBody, .shoulders, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/IPAtrugyGBA'),
  ),
  'Coupon rows': ExerciseEntry(categories: {.arms, .coupon, .strength}),
  'Coupon Salt Shaker': ExerciseEntry(
    categories: {.arms, .coupon, .fullBody, .legs, .shoulders, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/6Rk4OKmU39A'),
  ),
  'Coyote Uglys': ExerciseEntry(
    categories: {.arms, .chest, .fullBody, .legs, .strength},
  ),
  'CPRs': ExerciseEntry(categories: {.arms, .coupon, .strength}),
  'Crab Cakes': ExerciseEntry(categories: {.cardio, .core, .fullBody}),
  'Crab Humper': ExerciseEntry(categories: {.cardio, .core, .fullBody}),
  'Crab Jacks': ExerciseEntry(categories: {.cardio, .core, .fullBody}),
  'Crab vs. Bear Soccer': ExerciseEntry(
    categories: {.cardio, .core, .fullBody},
  ),
  'Crab Walk': ExerciseEntry(categories: {.cardio, .core, .fullBody}),
  'Cracker Jacks': ExerciseEntry(
    categories: {.arms, .cardio, .fullBody, .legs},
  ),
  'Crawl Bear': ExerciseEntry(categories: {.cardio, .fullBody}),
  'Crawl Bear 360': ExerciseEntry(categories: {.cardio, .fullBody}),
  'Creapees': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .strength},
  ),
  'Creature Merkins': ExerciseEntry(
    categories: {.arms, .chest, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/pRiq3cH3tIQ'),
  ),
  'Cross Climbers': ExerciseEntry(categories: {.core}),
  'Crowd Pleaser': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'Crucible Merkin': ExerciseEntry(
    categories: {.arms, .chest, .shoulders, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/OwfBMHOD-gM'),
  ),
  'Crunchy Frog': ExerciseEntry(
    categories: {.arms, .cardio, .core, .fullBody, .legs},
    videoUrl: Uri.parse('https://www.youtube.com/embed/0AlV31sQ3co'),
  ),
  'Cumberland County Viaduct (CCV)': ExerciseEntry(categories: {.fullBody}),
  'Cupid Shuffle': ExerciseEntry(categories: {.cardio, .core}),
  'Curb Alpert': ExerciseEntry(categories: {.arms, .chest, .strength}),
  'Curls': ExerciseEntry(categories: {.arms, .strength}),
  'Cut A Flip': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/x6M7yhzIM80'),
  ),
  'Daft Punk': ExerciseEntry(categories: {.legs}),
  'Dan Taylor': ExerciseEntry(
    categories: {.arms, .chest, .legs},
    videoUrl: Uri.parse('https://www.youtube.com/embed/fQNX5EmSemU'),
  ),
  'Dancing Bear Pyramid': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .legs, .strength},
  ),
  'Dancing Bears': ExerciseEntry(categories: {.arms}),
  'Dancing Chilcutt': ExerciseEntry(categories: {.core}),
  'Danger Zone': ExerciseEntry(categories: {.cardio}),
  'Daniel-Son': ExerciseEntry(categories: {.legs}),
  'DareKong Merkins': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .chest,
      .fullBody,
      .legs,
      .shoulders,
      .strength,
    },
  ),
  'Dark Webbs': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .legs, .strength},
  ),
  'DaVinci Cartwheel': ExerciseEntry(
    categories: {.arms, .cardio, .fullBody, .legs, .shoulders, .strength},
  ),
  'Dayton Flyers': ExerciseEntry(
    categories: {.cardio, .chest, .fullBody, .legs},
  ),
  'Death Star': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .strength},
  ),
  'Deck of Death': ExerciseEntry(categories: {.fullBody}),
  'Deconstructed Burpees': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .legs, .strength},
  ),
  'Deep Sea Diver': ExerciseEntry(categories: {.fullBody}),
  'Del Brown': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .strength},
  ),
  'Derkin': ExerciseEntry(
    categories: {.arms, .chest, .fullBody, .legs, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/a3UWiiUXH1E'),
  ),
  'Derkin N\'Diayes': ExerciseEntry(categories: {.arms, .chest, .core}),
  'Derkins': ExerciseEntry(categories: {.arms, .chest}),
  'Derricks': ExerciseEntry(categories: {.arms, .shoulders}),
  'Devin Hester': ExerciseEntry(categories: {.cardio, .coupon, .strength}),
  'Diamond David Lee Roth Burpee': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .strength},
  ),
  'Diamond Merkin': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .shoulders, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/hPQ77OizZoA'),
  ),
  'Diego': ExerciseEntry(
    categories: {
      .arms,
      .chest,
      .core,
      .coupon,
      .fullBody,
      .legs,
      .shoulders,
      .strength,
    },
  ),
  'Dips': ExerciseEntry(
    categories: {.arms, .core, .fullBody, .legs, .shoulders, .strength},
  ),
  'Dirty Harry': ExerciseEntry(categories: {.cardio, .core, .fullBody}),
  'Dirty Hookup': ExerciseEntry(
    categories: {.arms, .core, .fullBody, .strength},
  ),
  'Dirty Mac Deuce': ExerciseEntry(categories: {.cardio, .chest, .core}),
  'Dirty Man Maker': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .chest,
      .coupon,
      .fullBody,
      .legs,
      .shoulders,
      .strength,
    },
  ),
  'Dive Bombers': ExerciseEntry(
    categories: {.arms, .chest, .shoulders, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/VxRB-bE_d68'),
  ),
  'Dizzy Bear': ExerciseEntry(
    categories: {.cardio, .coupon, .fullBody, .strength},
  ),
  'DMC': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .strength},
  ),
  'DMX': ExerciseEntry(
    categories: {.fullBody},
    videoUrl: Uri.parse('https://www.youtube.com/embed/ZvmOFic5VR0'),
  ),
  'Do-ah-diddy': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .legs, .strength},
  ),
  'Doc Ock\'s Octogon of Pain': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .legs, .strength},
  ),
  'Dodo bird': ExerciseEntry(
    categories: {
      .arms,
      .chest,
      .coupon,
      .fullBody,
      .legs,
      .shoulders,
      .strength,
    },
  ),
  'Dog': ExerciseEntry(categories: {.fullBody}),
  'Doggie Paddle': ExerciseEntry(categories: {.arms, .strength}),
  'Dolly': ExerciseEntry(
    categories: {.core, .legs},
    videoUrl: Uri.parse('https://www.youtube.com/embed/ZXiJVYcAAj4'),
  ),
  'Dominos': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'Donkey Kick-offs': ExerciseEntry(categories: {.legs}),
  'Donkey Kicks': ExerciseEntry(categories: {.core, .legs}),
  'Dora 1-2-3': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .legs, .strength},
  ),
  'DORA 2100': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .chest,
      .core,
      .coupon,
      .fullBody,
      .legs,
      .strength,
    },
  ),
  'Doracides': ExerciseEntry(categories: {.cardio, .fullBody}),
  'Double Applesauce': ExerciseEntry(categories: {.cardio}),
  'Double Merkin Burpee': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .strength},
  ),
  'Double Shot of Jackies': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .strength},
  ),
  'Dr. W': ExerciseEntry(
    categories: {.arms, .core, .fullBody, .legs, .strength},
  ),
  'Dragon Walk': ExerciseEntry(
    categories: {.core},
    videoUrl: Uri.parse('https://www.youtube.com/embed/qj5BHzR6zUA'),
  ),
  'Dragon Wing': ExerciseEntry(categories: {.fullBody}),
  'Dreadbow': ExerciseEntry(categories: {.coupon, .strength}),
  'Drill Instructors': ExerciseEntry(categories: {.fullBody}),
  'Dropzone': ExerciseEntry(categories: {.fullBody}),
  'Dry Dock Crabs': ExerciseEntry(categories: {.fullBody}),
  'Dubya': ExerciseEntry(categories: {.arms, .core, .fullBody, .strength}),
  'Duck and Weave': ExerciseEntry(categories: {.cardio, .legs}),
  'Duck Jousting': ExerciseEntry(categories: {.arms, .chest, .legs}),
  'Duck Walk': ExerciseEntry(categories: {.legs}),
  'Dumbees': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .chest,
      .coupon,
      .fullBody,
      .shoulders,
      .strength,
    },
  ),
  'Dutch Skate': ExerciseEntry(categories: {.cardio, .legs}),
  'Dwight Howard': ExerciseEntry(
    categories: {.cardio, .coupon, .legs, .strength},
  ),
  'Dying Cockroach': ExerciseEntry(categories: {.core}),
  'E2K': ExerciseEntry(categories: {.cardio, .core}),
  'Earl Fonda': ExerciseEntry(
    categories: {.cardio, .chest},
    videoUrl: Uri.parse('https://www.youtube.com/embed/9YGwVw22OxA'),
  ),
  'Edisons': ExerciseEntry(categories: {.fullBody}),
  'El Capitan': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .coupon, .fullBody, .legs, .strength},
  ),
  'Elaine Benes': ExerciseEntry(categories: {.arms, .shoulders}),
  'Elevens': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .strength},
  ),
  'Elf on the Shelf': ExerciseEntry(
    categories: {.core, .coupon, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/bUpFN7WQMCg'),
  ),
  'Elizabeth Warren': ExerciseEntry(categories: {.cardio, .legs}),
  'Elizabeth Warrens': ExerciseEntry(categories: {.fullBody}),
  'Elvis Meets Forrest': ExerciseEntry(
    categories: {.arms, .cardio, .fullBody, .legs, .strength},
  ),
  'Empty Wheelbarrow': ExerciseEntry(
    categories: {.arms, .core, .fullBody, .legs, .strength},
  ),
  'Energizer bunnies': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .legs, .strength},
  ),
  'Escalator': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .legs, .strength},
  ),
  'Everest': ExerciseEntry(categories: {.cardio, .legs}),
  'F3 Baseball': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .legs, .strength},
  ),
  'Failure to Launch': ExerciseEntry(categories: {.cardio}),
  'Fairy Jack': ExerciseEntry(categories: {.cardio}),
  'Febreze': ExerciseEntry(
    categories: {.arms, .fullBody, .legs, .shoulders, .strength},
  ),
  'Ferkin (aka FiA Merkin)': ExerciseEntry(
    categories: {.arms, .chest, .strength},
  ),
  'Fiddler Crab': ExerciseEntry(categories: {.cardio, .core, .fullBody}),
  'Field of Dreams': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .chest,
      .core,
      .coupon,
      .fullBody,
      .legs,
      .strength,
    },
  ),
  'Finger-tip Merkin': ExerciseEntry(categories: {.arms, .chest, .strength}),
  'Finkle Swings': ExerciseEntry(
    categories: {.arms, .fullBody, .legs, .shoulders, .strength},
  ),
  'Fire Drill': ExerciseEntry(categories: {.cardio}),
  'Fireworks': ExerciseEntry(categories: {.cardio, .fullBody}),
  'Flamingo merkins': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'Flat Tire': ExerciseEntry(
    categories: {.arms, .chest, .fullBody, .legs, .strength},
  ),
  'Flip Flops': ExerciseEntry(categories: {.cardio, .fullBody}),
  'Flora 1-2-3': ExerciseEntry(
    categories: {.arms, .chest, .core, .coupon, .fullBody, .legs, .strength},
  ),
  'Floyd Mayweather - Plank Punch': ExerciseEntry(categories: {.core, .coupon}),
  'Floyd Plank': ExerciseEntry(
    categories: {.core},
    videoUrl: Uri.parse('https://www.youtube.com/embed/z9N9MOVIQas'),
  ),
  'Flutter kicks': ExerciseEntry(
    categories: {.core, .legs},
    videoUrl: Uri.parse('https://www.youtube.com/embed/oB3f8Bh__Pg'),
  ),
  'Flying Nun': ExerciseEntry(categories: {.arms, .chest, .legs, .shoulders}),
  'Flying Squirrel': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .legs, .strength},
  ),
  'Flying sun gods sobriety style (AKA Nancy Kerrigans)': ExerciseEntry(
    categories: {.arms, .chest, .legs, .shoulders},
  ),
  'Forest to the Sea': ExerciseEntry(
    categories: {.arms, .cardio, .core, .fullBody, .strength},
  ),
  'Fornicola’s': ExerciseEntry(categories: {.arms, .shoulders}),
  'Four Corners Escalator': ExerciseEntry(categories: {.cardio}),
  'Foxhole': ExerciseEntry(categories: {.fullBody}),
  'Frankenstein Squat': ExerciseEntry(categories: {.legs}),
  'Frankensteins': ExerciseEntry(
    categories: {.arms},
    videoUrl: Uri.parse('https://www.youtube.com/embed/M0ABsSU--DM'),
  ),
  'Freddie Mercuries': ExerciseEntry(categories: {.fullBody}),
  'Freddie Mercury': ExerciseEntry(
    categories: {.arms, .core, .legs},
    videoUrl: Uri.parse('https://www.youtube.com/embed/8Xpf6kwKSLM'),
  ),
  'Friday Night Lights': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .coupon, .fullBody, .legs, .strength},
  ),
  'Frog squats': ExerciseEntry(
    categories: {.cardio, .coupon, .fullBody, .legs, .strength},
  ),
  'Froggies': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .shoulders, .strength},
  ),
  'Gargoyle': ExerciseEntry(
    categories: {.coupon, .legs, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/Sa9KdAJRk3Y'),
  ),
  'Gas Pump': ExerciseEntry(categories: {.core, .legs}),
  'Get Low': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .legs, .shoulders, .strength},
  ),
  'Get Low or Buried Face': ExerciseEntry(
    categories: {.arms, .chest, .coupon, .shoulders, .strength},
  ),
  'Get Lucky or not so much': ExerciseEntry(categories: {.fullBody}),
  'Glen Campbells': ExerciseEntry(categories: {.coupon, .fullBody, .strength}),
  'Global Warming': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .strength},
  ),
  'Golden Arches': ExerciseEntry(categories: {.core, .legs}),
  'Good Morning Abby': ExerciseEntry(categories: {.core, .fullBody, .legs}),
  'Good Morning Burpees': ExerciseEntry(categories: {.cardio, .fullBody}),
  'Good Morning Squat': ExerciseEntry(categories: {.coupon, .legs, .strength}),
  'Google Bun Shaper': ExerciseEntry(categories: {.legs}),
  'Gorilla Complex': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .coupon, .shoulders, .strength},
  ),
  'Gorilla Humpers': ExerciseEntry(
    categories: {.arms, .fullBody, .legs, .shoulders, .strength},
  ),
  'Grady Corn': ExerciseEntry(categories: {.fullBody}),
  'Grave Diggers': ExerciseEntry(
    categories: {.arms, .coupon, .shoulders, .strength},
  ),
  'Green Sally Up': ExerciseEntry(categories: {.chest}),
  'Greg Louganis Merkin': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .legs, .strength},
  ),
  'Greta 1-2-3': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .coupon,
      .fullBody,
      .legs,
      .shoulders,
      .strength,
    },
  ),
  'Griff': ExerciseEntry(categories: {.cardio}),
  'Grip, Rip, and Roll (GRRs)': ExerciseEntry(
    categories: {.core, .coupon, .strength},
  ),
  'Grizzcalator': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .strength},
  ),
  'Grocery carry': ExerciseEntry(
    categories: {.arms, .coupon, .fullBody, .strength},
  ),
  'Groiners': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'Ground Pounder': ExerciseEntry(
    categories: {.chest, .coupon, .legs, .strength},
  ),
  'Growing Pains': ExerciseEntry(
    categories: {.arms, .core, .fullBody, .strength},
  ),
  'Guantanamo': ExerciseEntry(categories: {.cardio, .legs}),
  'Gunji Squat': ExerciseEntry(
    categories: {.arms, .core, .fullBody, .legs, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/XuDN3kU5L6k'),
  ),
  'Gunners': ExerciseEntry(categories: {.cardio, .fullBody, .legs}),
  'Gut Busters': ExerciseEntry(categories: {.core}),
  'Gwerkin': ExerciseEntry(categories: {.legs}),
  'Hail Mary': ExerciseEntry(
    categories: {.arms, .core, .fullBody, .legs, .strength},
  ),
  'Hair Burners': ExerciseEntry(categories: {.cardio, .coupon}),
  'Hairband Mile': ExerciseEntry(categories: {.cardio}),
  'Hairy Rockettes': ExerciseEntry(
    categories: {.arms, .coupon, .shoulders, .strength},
  ),
  'Hand Release Prisoner Cell Merkin Burpees aka HRPCMBs': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .strength},
  ),
  'Hand-release Mike Tysons': ExerciseEntry(
    categories: {.arms, .chest, .core, .legs},
  ),
  'Hands of Time': ExerciseEntry(
    categories: {.arms, .fullBody, .legs, .strength},
  ),
  'Hang Clean': ExerciseEntry(
    categories: {.chest, .coupon, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/3RVPJgkswfY'),
  ),
  'Hanging Overhead Press (H.O.P.)': ExerciseEntry(
    categories: {.arms, .chest, .coupon, .shoulders, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/DOD6Gz1f8r0'),
  ),
  'Hanging Toe Touch': ExerciseEntry(categories: {.strength}),
  'Happy Jacks': ExerciseEntry(categories: {.cardio, .legs}),
  'Harley Quinn\'s': ExerciseEntry(categories: {.cardio}),
  'Hash Pipe': ExerciseEntry(categories: {.fullBody}),
  'Hatching Butterfly': ExerciseEntry(categories: {.chest, .core}),
  'Head, Shoulders, Knees & Toes': ExerciseEntry(
    categories: {.arms, .chest, .coupon, .shoulders, .strength},
  ),
  'Heartbreak 1, 2, 3s': ExerciseEntry(categories: {.cardio}),
  'Heavy Freddies': ExerciseEntry(
    categories: {.coupon, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/9D7XuKLCjCM'),
  ),
  'Heel Toe Rocks': ExerciseEntry(
    categories: {.core, .coupon, .fullBody, .legs, .shoulders, .strength},
  ),
  'Heels to Heaven': ExerciseEntry(categories: {.core, .legs}),
  'Hernia': ExerciseEntry(
    categories: {.arms, .core, .coupon, .fullBody, .strength},
  ),
  'Hernias': ExerciseEntry(categories: {.fullBody}),
  'High knees': ExerciseEntry(categories: {.cardio}),
  'Hillbillies': ExerciseEntry(
    categories: {.cardio, .core},
    videoUrl: Uri.parse('https://www.youtube.com/embed/UyYjc1tuBOY'),
  ),
  'Hillbilly Climbers': ExerciseEntry(categories: {.cardio, .core}),
  'Hillbilly Squats': ExerciseEntry(
    categories: {.cardio, .core, .fullBody, .legs},
    videoUrl: Uri.parse('https://www.youtube.com/embed/vNWUyh-OCQM'),
  ),
  'Hindenburg BLIMPS': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .legs, .strength},
  ),
  'Hip Slapper': ExerciseEntry(categories: {.fullBody}),
  'Homer to Marge to Mr. Burns (also submitted as Homer-to-Marge Merry Relay)':
      ExerciseEntry(categories: {.core, .legs}),
  'Hot Potato': ExerciseEntry(categories: {.core, .coupon, .strength}),
  'Howling Monkeys': ExerciseEntry(categories: {.fullBody}),
  'HRBs': ExerciseEntry(categories: {.arms, .cardio, .fullBody}),
  'Hundreds': ExerciseEntry(
    categories: {.arms, .core, .fullBody, .legs, .shoulders, .strength},
  ),
  'Hurpees': ExerciseEntry(categories: {.arms, .cardio, .fullBody}),
  'Hurricane Hoedown': ExerciseEntry(
    categories: {.arms, .core, .fullBody, .legs, .strength},
  ),
  'Hustle Mosey': ExerciseEntry(
    categories: {.cardio},
    videoUrl: Uri.parse('https://www.youtube.com/embed/6WRbKn0KxU8'),
  ),
  'Hydraulic Humper': ExerciseEntry(categories: {.legs}),
  'Hydraulic Squat': ExerciseEntry(categories: {.legs}),
  'IHOP': ExerciseEntry(categories: {.cardio}),
  'Imperial Blockee': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .chest,
      .coupon,
      .fullBody,
      .legs,
      .shoulders,
      .strength,
    },
    videoUrl: Uri.parse('https://www.youtube.com/embed/K_c5euKjmeA'),
  ),
  'Imperial blocker': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .core,
      .coupon,
      .fullBody,
      .legs,
      .shoulders,
      .strength,
    },
    videoUrl: Uri.parse('https://www.youtube.com/embed/RtYIK3WZtKg'),
  ),
  'Imperial Squat Walker': ExerciseEntry(
    categories: {.cardio, .legs},
    videoUrl: Uri.parse('https://www.youtube.com/embed/gCunrlg2YQY'),
  ),
  'Imperial Stormkickers': ExerciseEntry(
    categories: {.arms, .legs},
    videoUrl: Uri.parse('https://www.youtube.com/embed/rmCzQAwUXUE'),
  ),
  'Imperial Walker': ExerciseEntry(
    categories: {.cardio, .core, .fullBody, .legs},
  ),
  'Imperial walkers': ExerciseEntry(categories: {.cardio, .legs}),
  'In the plank tonight': ExerciseEntry(categories: {.core}),
  'Inch-Worm N\'Diayes': ExerciseEntry(categories: {.cardio, .core}),
  'Inchworm blockees': ExerciseEntry(
    categories: {.cardio, .coupon, .fullBody, .shoulders, .strength},
  ),
  'Indian Bear Crawl': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .strength},
  ),
  'Indian Crab Walk': ExerciseEntry(categories: {.cardio, .core, .fullBody}),
  'Indian Run 11s': ExerciseEntry(categories: {.cardio}),
  'Individual Medley': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .legs, .strength},
  ),
  'Intentional Thinker': ExerciseEntry(categories: {.fullBody}),
  'Irkins': ExerciseEntry(categories: {.arms, .chest}),
  'Iron Hulk': ExerciseEntry(
    categories: {.arms, .chest, .shoulders, .strength},
  ),
  'Iron Squat': ExerciseEntry(
    categories: {.arms, .coupon, .fullBody, .legs, .shoulders, .strength},
  ),
  'Island Hoppers': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .strength},
  ),
  'J-Los': ExerciseEntry(categories: {.chest, .core, .strength}),
  'Jabber-Walker-Squat': ExerciseEntry(
    categories: {.arms, .cardio, .fullBody, .legs, .shoulders, .strength},
  ),
  'Jack Jack Webbs': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'Jack Knives': ExerciseEntry(categories: {.arms, .chest, .coupon}),
  'Jack Moses': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .shoulders, .strength},
  ),
  'Jackass Burpee Webb': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .legs},
  ),
  'JackAss Merkin': ExerciseEntry(
    categories: {.arms, .chest, .fullBody, .legs, .strength},
  ),
  'Jacked Up': ExerciseEntry(categories: {.cardio, .core, .fullBody, .legs}),
  'Jackees': ExerciseEntry(categories: {.cardio, .fullBody}),
  'Jackhammer': ExerciseEntry(categories: {.cardio, .legs}),
  'Jacob\'s Ladder': ExerciseEntry(categories: {.cardio, .fullBody}),
  'James Bonds': ExerciseEntry(
    categories: {.arms, .fullBody, .legs, .strength},
  ),
  'Jim Braddock': ExerciseEntry(
    categories: {.arms, .core, .fullBody, .strength},
  ),
  'Jingle Balls': ExerciseEntry(categories: {.core}),
  'Joe Derk': ExerciseEntry(categories: {.arms, .chest}),
  'Joe Hendricks': ExerciseEntry(
    categories: {.cardio, .coupon, .fullBody, .strength},
  ),
  'Joe Louis': ExerciseEntry(categories: {.fullBody}),
  'Johnny Cash': ExerciseEntry(categories: {.core}),
  'Johnny Drama': ExerciseEntry(categories: {.cardio, .legs}),
  'Johnny Roscoes': ExerciseEntry(categories: {.cardio}),
  'Juggernaut': ExerciseEntry(
    categories: {.coupon, .fullBody, .legs, .strength},
  ),
  'Juicer': ExerciseEntry(categories: {.fullBody}),
  'Jump Squat': ExerciseEntry(
    categories: {.cardio, .core, .fullBody, .legs},
    videoUrl: Uri.parse('https://www.youtube.com/embed/g6Q60wPJEOw'),
  ),
  'Jump Squat Holds': ExerciseEntry(categories: {.cardio, .legs}),
  'Jump Ups': ExerciseEntry(categories: {.cardio}),
  'Jumping Jack Burpee Flash': ExerciseEntry(
    categories: {.cardio, .core, .fullBody},
  ),
  'Jumping Jack Burpee Flash Pull-ups': ExerciseEntry(
    categories: {.arms, .cardio, .core, .fullBody, .strength},
  ),
  'Jumping Spider': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .strength},
  ),
  'Jungle Boy Squat': ExerciseEntry(
    categories: {.arms, .cardio, .fullBody, .legs, .shoulders, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/VBSOL1kUXBw'),
  ),
  'Killer Bees': ExerciseEntry(categories: {.cardio, .fullBody, .legs}),
  'Killer roos': ExerciseEntry(
    categories: {.cardio, .coupon, .legs, .strength},
  ),
  'King Arthur': ExerciseEntry(categories: {.cardio}),
  'King of Hearts': ExerciseEntry(categories: {.cardio}),
  'Knockout of Death': ExerciseEntry(
    categories: {.arms, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/IHkYnANRTN0'),
  ),
  'Kobe': ExerciseEntry(
    categories: {.cardio, .core, .coupon, .fullBody, .legs, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/yxFftxo7ug8'),
  ),
  'Kraken Burpee': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/JV2FZUY-TJE'),
  ),
  'Kurpee': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .coupon, .fullBody, .strength},
  ),
  'La La Leggy': ExerciseEntry(categories: {.cardio, .legs}),
  'Ladder Jacks': ExerciseEntry(categories: {.cardio, .core}),
  'Laney Lu Plank and Merk': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'Lawn mowers': ExerciseEntry(categories: {.fullBody}),
  'Lazy Doras': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .legs, .strength},
  ),
  'Lazy Susan': ExerciseEntry(categories: {.arms, .chest, .coupon, .strength}),
  'LBCC\'s': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .coupon, .fullBody, .strength},
  ),
  'LBCs': ExerciseEntry(categories: {.cardio, .core}),
  'LBFCs': ExerciseEntry(categories: {.cardio, .core, .fullBody, .legs}),
  'Leeroy Jenkins': ExerciseEntry(categories: {.cardio, .fullBody}),
  'Leg Wrecker': ExerciseEntry(categories: {.cardio, .legs}),
  'Lemur Jump': ExerciseEntry(
    categories: {.arms, .cardio, .core, .fullBody, .legs, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/jikU38adMms'),
  ),
  'Lindsays aka Forties': ExerciseEntry(categories: {.arms, .chest, .strength}),
  'Little Merkin Boy': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'Little Mermaid': ExerciseEntry(categories: {.arms, .core, .legs}),
  'LL Cool J': ExerciseEntry(categories: {.cardio, .fullBody, .legs}),
  'London Bridge': ExerciseEntry(categories: {.core}),
  'Lounge Act': ExerciseEntry(categories: {.fullBody}),
  'Low Country Crab': ExerciseEntry(categories: {.core}),
  'Low Country Crap Boil': ExerciseEntry(
    categories: {.arms, .core, .fullBody, .strength},
  ),
  'Low flutters': ExerciseEntry(categories: {.core}),
  'Lt. Danger': ExerciseEntry(
    categories: {.arms, .chest, .fullBody, .legs, .strength},
  ),
  'Lt. Dans': ExerciseEntry(categories: {.legs}),
  'Lt. Get-ups': ExerciseEntry(categories: {.fullBody, .legs}),
  'Luge': ExerciseEntry(categories: {.chest}),
  'Lunge worm': ExerciseEntry(
    categories: {.arms, .chest, .fullBody, .legs, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/CGq4HHj2oLs'),
  ),
  'Lunges': ExerciseEntry(categories: {.legs}),
  'M.E.R.C.Y. High Fives': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .coupon, .fullBody, .legs, .strength},
  ),
  'MABAta': ExerciseEntry(categories: {.cardio, .fullBody, .legs, .shoulders}),
  'Makhtar N\'Diayes': ExerciseEntry(
    categories: {.core},
    videoUrl: Uri.parse('https://www.youtube.com/embed/GZopmQiM3zI'),
  ),
  'Man makers': ExerciseEntry(categories: {.fullBody}),
  'Manatee': ExerciseEntry(categories: {.core}),
  'Manmaker': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .chest,
      .fullBody,
      .legs,
      .shoulders,
      .strength,
    },
  ),
  'Manmaker Burpee': ExerciseEntry(
    categories: {.cardio, .coupon, .fullBody, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/Mt3JzJ-xXlg'),
  ),
  'Manmaker Merkin': ExerciseEntry(
    categories: {.arms, .chest, .core, .coupon, .fullBody, .strength},
  ),
  'Mario': ExerciseEntry(categories: {.cardio}),
  'Marionettes': ExerciseEntry(categories: {.core, .legs}),
  'Mary In The Middle': ExerciseEntry(
    categories: {.cardio, .core, .fullBody, .shoulders, .strength},
  ),
  'Matt Biondi': ExerciseEntry(
    categories: {.arms, .fullBody, .legs, .shoulders, .strength},
  ),
  'McDuck': ExerciseEntry(categories: {.legs}),
  'McFly Run': ExerciseEntry(categories: {.cardio, .chest}),
  'Mega Man': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .legs, .strength},
  ),
  'Men Makers': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .legs, .strength},
  ),
  'Merkin': ExerciseEntry(categories: {.arms, .chest, .strength}),
  'Merkin Jack': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .legs, .strength},
  ),
  'Merkin Jax': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'Merkin Ladder': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .strength},
  ),
  'Merkin Mania': ExerciseEntry(categories: {.arms, .chest, .strength}),
  'Merkin Mile': ExerciseEntry(categories: {.arms, .cardio, .chest, .strength}),
  'Merkin Mountain': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .strength},
  ),
  'Merkin Pyramid': ExerciseEntry(categories: {.arms, .chest, .strength}),
  'Merkin Roll': ExerciseEntry(categories: {.arms, .chest, .strength}),
  'Merkin Wipes': ExerciseEntry(categories: {.arms, .chest, .strength}),
  'Merkins': ExerciseEntry(categories: {.arms, .chest, .strength}),
  'Mexican Jumping Bean Pull-ups': ExerciseEntry(
    categories: {.arms, .cardio, .fullBody, .legs, .strength},
  ),
  'Mexican Jumping Bean Squats': ExerciseEntry(categories: {.cardio, .legs}),
  'Michelin Man Bolt': ExerciseEntry(categories: {.fullBody}),
  'Mickey Mouse Merkin': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'Mike Tyson Merkin': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .legs, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/4m8u0gSqkfs'),
  ),
  'Mike Tyson Taps': ExerciseEntry(categories: {.arms, .shoulders, .strength}),
  'Mile of 50s': ExerciseEntry(categories: {.cardio}),
  'Millenial': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .legs, .strength},
  ),
  'Mini Chesto': ExerciseEntry(categories: {.chest}),
  'Mini-Hair Burners': ExerciseEntry(categories: {.core, .coupon, .strength}),
  'Minnesota Burpee': ExerciseEntry(categories: {.cardio, .fullBody}),
  'Miracle Mile': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .legs, .strength},
  ),
  'Mjolnir': ExerciseEntry(
    categories: {.core, .coupon, .fullBody, .legs, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/wjQ_dMOwVC4'),
  ),
  'Monkey Crunches': ExerciseEntry(
    categories: {.cardio, .core, .fullBody, .legs},
  ),
  'Monkey Drill': ExerciseEntry(categories: {.legs}),
  'Monkey Humpers': ExerciseEntry(categories: {.legs}),
  'Monkey Humping Goblet Squat': ExerciseEntry(
    categories: {.arms, .chest, .core, .coupon, .fullBody, .legs, .strength},
  ),
  'Monkey Jumpers': ExerciseEntry(categories: {.cardio, .legs}),
  'Monkey Rolls': ExerciseEntry(categories: {.arms, .shoulders, .strength}),
  'Monkey Squats': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .core,
      .fullBody,
      .legs,
      .shoulders,
      .strength,
    },
  ),
  'Moon Gods': ExerciseEntry(categories: {.core}),
  'Morning Call': ExerciseEntry(categories: {.arms, .chest, .strength}),
  'Morning Wood': ExerciseEntry(categories: {.arms, .core, .coupon, .fullBody}),
  'Moroccan Nightclub': ExerciseEntry(
    categories: {.arms, .shoulders, .strength},
  ),
  'Mosey': ExerciseEntry(categories: {.cardio}),
  'Motor City Shuffle': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .legs, .strength},
  ),
  'Mountain Climber Merkin': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'Mountain climbers': ExerciseEntry(categories: {.cardio, .core}),
  'Mountain Goats': ExerciseEntry(
    categories: {.core, .legs},
    videoUrl: Uri.parse('https://www.youtube.com/embed/vfGdHkPxlxw'),
  ),
  'Mountain Man Pooper': ExerciseEntry(
    categories: {.arms, .cardio, .coupon, .fullBody, .legs, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/1Y3C8oZ8jhI'),
  ),
  'Mountain Merkins': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/CZ1-3rZ_Vko'),
  ),
  'Mountaineer Motivators': ExerciseEntry(categories: {.arms, .cardio}),
  'Mucho Chesto': ExerciseEntry(categories: {.arms, .chest, .strength}),
  'Mucho Leg-o': ExerciseEntry(
    categories: {.arms, .cardio, .fullBody, .legs, .strength},
  ),
  'Muffin Man': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .chest,
      .coupon,
      .fullBody,
      .legs,
      .shoulders,
      .strength,
    },
  ),
  'Multi-Merkin (M&M)': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'Murder Blockee': ExerciseEntry(
    categories: {.arms, .cardio, .coupon, .fullBody, .legs, .strength},
  ),
  'Murder Bunny': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .core,
      .coupon,
      .fullBody,
      .legs,
      .shoulders,
      .strength,
    },
    videoUrl: Uri.parse('https://www.youtube.com/embed/MRay9ttTfCk'),
  ),
  'Murder Burpees': ExerciseEntry(categories: {.cardio, .fullBody}),
  'Murder Hornet': ExerciseEntry(
    categories: {.cardio, .coupon, .fullBody, .legs, .strength},
  ),
  'Musical Dora': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .chest,
      .coupon,
      .fullBody,
      .legs,
      .shoulders,
      .strength,
    },
  ),
  'Ménage': ExerciseEntry(categories: {.core}),
  'Nadal': ExerciseEntry(categories: {.cardio}),
  'Navy Seal Burpee': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/1OT43riPRsw'),
  ),
  'Necro bunny': ExerciseEntry(categories: {.cardio, .fullBody, .legs}),
  'NEMOs': ExerciseEntry(
    categories: {
      .arms,
      .chest,
      .core,
      .coupon,
      .fullBody,
      .legs,
      .shoulders,
      .strength,
    },
  ),
  'Never Cross Dolly': ExerciseEntry(categories: {.core}),
  'New Test': ExerciseEntry(categories: {.fullBody}),
  'Newton\'s Cradle': ExerciseEntry(
    categories: {.arms, .core, .coupon, .fullBody, .strength},
  ),
  'Nicole': ExerciseEntry(categories: {.arms, .cardio, .strength}),
  'Ninnie Knockers': ExerciseEntry(categories: {.chest}),
  'Nipple Scraper Merkin': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'No Cheat Merkin': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .shoulders, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/ZE_nB1neqp0'),
  ),
  'No Surrender': ExerciseEntry(
    categories: {.fullBody},
    videoUrl: Uri.parse('https://www.youtube.com/embed/19LhGlHEBKY'),
  ),
  'No Surrender Indian Plank': ExerciseEntry(categories: {.core}),
  'NoHo Row': ExerciseEntry(
    categories: {.arms, .core, .coupon, .fullBody, .legs, .strength},
  ),
  'Nolan Richardson': ExerciseEntry(categories: {.cardio}),
  'Nolan Ryan': ExerciseEntry(categories: {.arms, .core}),
  'Non-Alternating Shoulder Taps': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .shoulders, .strength},
  ),
  'Noodling for Catfish': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'Noonan': ExerciseEntry(categories: {.cardio, .coupon, .strength}),
  'Not-So Lazy Boys': ExerciseEntry(categories: {.arms, .core, .legs}),
  'Nutcracker': ExerciseEntry(categories: {.arms, .coupon, .legs}),
  'O.P.P.': ExerciseEntry(categories: {.arms, .core, .legs}),
  'Obama': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .strength},
  ),
  'Old Flame Drill (OFD)': ExerciseEntry(categories: {.cardio, .legs}),
  'Old Town Pain Train': ExerciseEntry(
    categories: {.cardio, .coupon, .fullBody, .strength},
  ),
  'Ollie Norths': ExerciseEntry(categories: {.coupon, .fullBody, .strength}),
  'One Calls': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'One-armed Pickle Pounder with Coupon': ExerciseEntry(
    categories: {.arms, .coupon, .strength},
  ),
  'One-legged Burpee': ExerciseEntry(categories: {.cardio, .fullBody}),
  'Orangutans': ExerciseEntry(
    categories: {.legs, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/xXsGDZvJsbE'),
  ),
  'Outlaw': ExerciseEntry(categories: {.core, .legs}),
  'Overhead press': ExerciseEntry(categories: {.arms, .shoulders, .strength}),
  'Pain Maker': ExerciseEntry(
    categories: {.arms, .chest, .coupon, .fullBody, .shoulders, .strength},
  ),
  'Painkillers': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'Pamela Anderson': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .strength},
  ),
  'Pansey': ExerciseEntry(categories: {.arms, .fullBody, .legs, .strength}),
  'Parker Peter': ExerciseEntry(categories: {.core}),
  'Parking Space Tracer': ExerciseEntry(categories: {.cardio}),
  'Partner Carry': ExerciseEntry(
    categories: {.cardio, .coupon, .fullBody, .strength},
  ),
  'Partner Coupon Swing': ExerciseEntry(
    categories: {.cardio, .coupon, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/Ok3pGZGPGno'),
  ),
  'Partner Derkin': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'Partner Plank Curls': ExerciseEntry(
    categories: {.arms, .core, .fullBody, .legs, .strength},
  ),
  'Partner Shrug': ExerciseEntry(
    categories: {.arms, .core, .fullBody, .shoulders, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/yZh7zkMDXGU'),
  ),
  'Pattycake Merkin': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'Paula Abdul': ExerciseEntry(categories: {.cardio}),
  'PBK (Patrick Brian Kenny)': ExerciseEntry(categories: {.fullBody}),
  'Peeping Lipstick': ExerciseEntry(categories: {.cardio}),
  'People\'s Air Presses': ExerciseEntry(
    categories: {.arms, .fullBody, .legs, .shoulders, .strength},
  ),
  'People\'s Chair': ExerciseEntry(categories: {.legs}),
  'People\'s Chair Modification': ExerciseEntry(
    categories: {.arms, .chest, .fullBody, .legs, .shoulders, .strength},
  ),
  'Peter Parker': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'Peter Parker Peter': ExerciseEntry(categories: {.core}),
  'Pick Your Poison': ExerciseEntry(categories: {.fullBody}),
  'Pickle Grinders': ExerciseEntry(categories: {.coupon, .legs, .strength}),
  'Pickle Pointers': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .legs, .shoulders, .strength},
  ),
  'Pickle Pounder': ExerciseEntry(categories: {.core}),
  'Pickle Push It': ExerciseEntry(categories: {.fullBody}),
  'Pike Pleaser': ExerciseEntry(categories: {.arms, .strength}),
  'Pinocchio': ExerciseEntry(
    categories: {.arms, .core, .coupon, .fullBody, .shoulders, .strength},
  ),
  'Pinochle': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .legs, .strength},
  ),
  'Pistol Squats': ExerciseEntry(
    categories: {.legs},
    videoUrl: Uri.parse('https://www.youtube.com/embed/8tqKpdY7_vE'),
  ),
  'Piston': ExerciseEntry(categories: {.coupon, .legs, .strength}),
  'Plank Compass': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'Plank Destroyer': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .shoulders, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/16-M_ekKKoM'),
  ),
  'Plank Dips': ExerciseEntry(categories: {.arms, .core, .fullBody, .strength}),
  'Plank Fonda': ExerciseEntry(categories: {.arms, .core}),
  'Plank Hurdles': ExerciseEntry(categories: {.cardio, .core}),
  'Plank jacks': ExerciseEntry(
    categories: {.cardio, .core},
    videoUrl: Uri.parse('https://www.youtube.com/embed/-079mPgNccE'),
  ),
  'Plankorama': ExerciseEntry(categories: {.cardio, .core}),
  'Plankorama-mama': ExerciseEntry(
    categories: {.arms, .core, .fullBody, .shoulders, .strength},
  ),
  'Play it Cool': ExerciseEntry(categories: {.legs}),
  'Poker Chips': ExerciseEntry(categories: {.coupon, .strength}),
  'Pole Dancing': ExerciseEntry(categories: {.core, .legs}),
  'Pop-up Merkins': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .strength},
  ),
  'Popeye punches': ExerciseEntry(categories: {.arms, .shoulders, .strength}),
  'Post Hole Diggers': ExerciseEntry(
    categories: {.arms, .fullBody, .legs, .shoulders, .strength},
  ),
  'Power Merkin': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/9LWwLZ6nodE'),
  ),
  'Prayer Squat': ExerciseEntry(
    categories: {.chest, .coupon, .legs, .strength},
  ),
  'Pretzel Crunch': ExerciseEntry(
    categories: {.arms, .cardio, .core, .fullBody, .legs},
  ),
  'Pretzel Stick': ExerciseEntry(
    categories: {.cardio, .core, .fullBody, .legs},
  ),
  'Primate humper o-rama': ExerciseEntry(
    categories: {.arms, .shoulders, .strength},
  ),
  'Prime Time Merkin': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .legs, .strength},
  ),
  'Princess Tea Party': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .legs, .strength},
  ),
  'Prisindian Run aka Prisoner Indian Run': ExerciseEntry(
    categories: {.cardio},
  ),
  'Prisoner Cell Merkin Burpees aka PCMBs.': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .strength},
  ),
  'Prisoner squats': ExerciseEntry(categories: {.legs}),
  'Prisoner\'s Squat': ExerciseEntry(categories: {.legs}),
  'Protractor': ExerciseEntry(categories: {.legs}),
  'Proud Mary': ExerciseEntry(categories: {.core}),
  'Pseudo Planche Merkins': ExerciseEntry(
    categories: {.arms, .chest, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/C-SML6xnVkI'),
  ),
  'Pull-up Squats': ExerciseEntry(
    categories: {.arms, .fullBody, .legs, .strength},
  ),
  'Pullerama': ExerciseEntry(categories: {.arms, .strength}),
  'Pump Jack': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .legs, .strength},
  ),
  'Punch-up Merkin': ExerciseEntry(categories: {.arms, .chest, .strength}),
  'Pure BURN': ExerciseEntry(categories: {.legs}),
  'Push-ups': ExerciseEntry(categories: {.arms, .chest, .strength}),
  'Pusherama': ExerciseEntry(categories: {.chest}),
  'Quadraphilia': ExerciseEntry(categories: {.cardio}),
  'Quarter Pounder': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .chest,
      .core,
      .coupon,
      .fullBody,
      .legs,
      .strength,
    },
  ),
  'Quick feet': ExerciseEntry(categories: {.fullBody}),
  'Racoon Crawl': ExerciseEntry(
    categories: {.arms, .cardio, .fullBody, .strength},
  ),
  'Railroad Tracks': ExerciseEntry(categories: {.cardio, .core}),
  'Railroaders': ExerciseEntry(
    categories: {.arms, .core, .fullBody, .legs, .shoulders, .strength},
  ),
  'Rampage': ExerciseEntry(categories: {.cardio, .fullBody}),
  'Randorama': ExerciseEntry(categories: {.fullBody}),
  'Randys': ExerciseEntry(categories: {.arms, .chest, .shoulders, .strength}),
  'Ranger Merkins': ExerciseEntry(
    categories: {.arms, .chest, .shoulders, .strength},
  ),
  'Rapid Fire Rock Set': ExerciseEntry(
    categories: {.arms, .core, .coupon, .fullBody, .shoulders, .strength},
  ),
  'Red Bull Smurf Jack': ExerciseEntry(categories: {.fullBody}),
  'Redrum': ExerciseEntry(
    categories: {.cardio, .coupon, .fullBody, .legs, .strength},
  ),
  'Redrum Bunnies': ExerciseEntry(categories: {.cardio, .fullBody, .legs}),
  'Reverse Crunch': ExerciseEntry(categories: {.cardio, .chest, .core}),
  'Reverse Indian Run aka Indian Giver': ExerciseEntry(categories: {.cardio}),
  'Robert Plants': ExerciseEntry(categories: {.cardio}),
  'Rochamburpees': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .coupon, .fullBody, .strength},
  ),
  'Rock-a-bye Baby': ExerciseEntry(
    categories: {.chest, .core, .coupon, .fullBody, .legs, .strength},
  ),
  'Rock-ee': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .coupon, .fullBody, .strength},
  ),
  'Rockette Dips': ExerciseEntry(
    categories: {.arms, .coupon, .fullBody, .legs, .strength},
  ),
  'Rockette Hillbillies': ExerciseEntry(
    categories: {.cardio, .coupon, .legs, .strength},
  ),
  'Rocking Chairs': ExerciseEntry(
    categories: {.arms, .coupon, .fullBody, .legs, .strength},
  ),
  'Rocks Up': ExerciseEntry(
    categories: {.arms, .coupon, .shoulders, .strength},
  ),
  'Rocky Balboa': ExerciseEntry(categories: {.coupon, .legs, .strength}),
  'Romanian Deadlift': ExerciseEntry(
    categories: {.arms, .coupon, .fullBody, .legs, .strength},
  ),
  'Rosalita': ExerciseEntry(categories: {.core, .legs}),
  'Rosalita Wip': ExerciseEntry(categories: {.core, .legs}),
  'Route 66': ExerciseEntry(categories: {.cardio, .fullBody}),
  'Rowboat': ExerciseEntry(categories: {.arms, .chest, .strength}),
  'Roxanne': ExerciseEntry(categories: {.core}),
  'Ruck Hammer': ExerciseEntry(
    categories: {.core, .coupon, .fullBody, .legs, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/FXXcAFaoOn4'),
  ),
  'Rucking Bricks': ExerciseEntry(
    categories: {.arms, .cardio, .coupon, .fullBody, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/EsHTL34qotE'),
  ),
  'Run DMC': ExerciseEntry(categories: {.cardio}),
  'Runaway': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .legs, .strength},
  ),
  'Runny-Joggy': ExerciseEntry(categories: {.cardio}),
  'Russian Dips': ExerciseEntry(categories: {.arms, .shoulders, .strength}),
  'Russies': ExerciseEntry(categories: {.arms, .fullBody, .legs, .strength}),
  'San Antonio Shuffle': ExerciseEntry(
    categories: {.cardio, .core, .fullBody, .legs},
  ),
  'Sandbag is Friend': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .coupon, .fullBody, .legs, .strength},
  ),
  'Sandstorm': ExerciseEntry(categories: {.arms, .cardio}),
  'Santa\'s Ladder': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .strength},
  ),
  'Sauron\'s Ladder': ExerciseEntry(categories: {.cardio}),
  'Scissor Lifts': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'Scorpion Dry Dock': ExerciseEntry(
    categories: {.arms, .chest, .fullBody, .legs, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/0y6oazM8tEQ'),
  ),
  'Scout Run': ExerciseEntry(categories: {.cardio}),
  'Seal claps': ExerciseEntry(categories: {.arms}),
  'Seal Crawl': ExerciseEntry(categories: {.arms, .cardio, .fullBody}),
  'Seal Jacks': ExerciseEntry(categories: {.arms, .cardio}),
  'SheHateMe': ExerciseEntry(categories: {.cardio, .fullBody, .legs}),
  'Shoots and Ladders': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .legs, .strength},
  ),
  'Shortcake Special': ExerciseEntry(categories: {.cardio}),
  'Shortie Squats': ExerciseEntry(
    categories: {.arms, .coupon, .fullBody, .legs, .shoulders, .strength},
  ),
  'Shoulder Blaster Special': ExerciseEntry(
    categories: {.arms, .shoulders, .strength},
  ),
  'Side Straddle Hop': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .core,
      .fullBody,
      .legs,
      .shoulders,
      .strength,
    },
    videoUrl: Uri.parse('https://www.youtube.com/embed/Kr3c7NEX14Y'),
  ),
  'Side Straddle Hop Burpees': ExerciseEntry(categories: {.cardio, .fullBody}),
  'Side Straddle Hop Jumps': ExerciseEntry(
    categories: {.arms, .cardio, .fullBody, .legs},
  ),
  'Side straddle hops': ExerciseEntry(categories: {.cardio}),
  'Side Straddle Squats': ExerciseEntry(
    categories: {.arms, .cardio, .fullBody, .legs},
  ),
  'Sideways Shoulder Stands': ExerciseEntry(
    categories: {
      .arms,
      .chest,
      .core,
      .coupon,
      .fullBody,
      .shoulders,
      .strength,
    },
  ),
  'Sinatras': ExerciseEntry(categories: {.core, .legs}),
  'Single Arm Row': ExerciseEntry(
    categories: {.arms, .core, .coupon, .fullBody, .shoulders, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/NI0Uqa1obto'),
  ),
  'Single Leg Pickle Pusher': ExerciseEntry(categories: {.cardio, .core}),
  'Singlet Merkin': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'Sit up & Scuttle': ExerciseEntry(
    categories: {.cardio, .core, .coupon, .fullBody, .strength},
  ),
  'Six Minutes Of Mary': ExerciseEntry(categories: {.core}),
  'Six Minutes of Uncle': ExerciseEntry(
    categories: {.arms, .cardio, .core, .fullBody, .strength},
  ),
  'Six Pack': ExerciseEntry(categories: {.arms, .chest, .strength}),
  'Sixty Second Arm Circles aka SSACs': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .shoulders, .strength},
  ),
  'Skull crushers': ExerciseEntry(categories: {.fullBody}),
  'Slaughter Starter': ExerciseEntry(categories: {.cardio, .fullBody}),
  'Sleep Walkers 123': ExerciseEntry(categories: {.cardio, .legs}),
  'Sleeping bunny': ExerciseEntry(categories: {.cardio, .fullBody, .legs}),
  'Sleeping Hillbillies': ExerciseEntry(categories: {.arms, .cardio}),
  'Slinky': ExerciseEntry(categories: {.arms, .cardio, .fullBody, .legs}),
  'Slugger': ExerciseEntry(categories: {.arms, .cardio, .chest, .strength}),
  'Smurf Jacks': ExerciseEntry(
    categories: {.cardio, .legs},
    videoUrl: Uri.parse('https://www.youtube.com/embed/4z6t28LudwA'),
  ),
  'Snapper Burpee': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .legs, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/856tKh0gsDU'),
  ),
  'Snapshot': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .core,
      .coupon,
      .fullBody,
      .legs,
      .shoulders,
      .strength,
    },
  ),
  'Sneaky Gorilla': ExerciseEntry(categories: {.cardio, .legs}),
  'Snowflake Plank': ExerciseEntry(categories: {.core}),
  'Snowman Shuffle': ExerciseEntry(categories: {.arms, .cardio}),
  'Snuffy': ExerciseEntry(categories: {.fullBody}),
  'Solo Tesh': ExerciseEntry(
    categories: {.arms, .coupon, .shoulders, .strength},
  ),
  'Solstice Burpee': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .legs, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/48Phq1lKwjM'),
  ),
  'SPAM': ExerciseEntry(
    categories: {.arms, .cardio, .core, .fullBody, .legs, .strength},
  ),
  'Spartan': ExerciseEntry(categories: {.arms, .cardio, .chest, .strength}),
  'Spartan Hammer': ExerciseEntry(categories: {.core}),
  'Special Merkins': ExerciseEntry(categories: {.arms, .chest, .strength}),
  'Speed Humpers': ExerciseEntry(categories: {.fullBody}),
  'Sphinx Merkin': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'Spiced Rum Squat': ExerciseEntry(categories: {.legs}),
  'Spiderman Crawl': ExerciseEntry(categories: {.cardio, .core, .fullBody}),
  'Spiderman Merkin': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'Sprinkler': ExerciseEntry(categories: {.arms, .core}),
  'Squat Jacks': ExerciseEntry(
    categories: {.arms, .cardio, .fullBody, .legs, .strength},
  ),
  'Squat Potato': ExerciseEntry(categories: {.legs}),
  'Squat Rocket': ExerciseEntry(
    categories: {.arms, .core, .coupon, .fullBody, .legs, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/w_8XWo3XHOo'),
  ),
  'Squat Thrust': ExerciseEntry(
    categories: {.arms, .fullBody, .legs, .strength},
  ),
  'Squat Walking Rockette': ExerciseEntry(
    categories: {.arms, .coupon, .fullBody, .legs, .strength},
  ),
  'Squats': ExerciseEntry(categories: {.legs}),
  'Squeezer': ExerciseEntry(categories: {.fullBody}),
  'Squerkin': ExerciseEntry(
    categories: {.arms, .chest, .fullBody, .legs, .strength},
  ),
  'Squirrel': ExerciseEntry(
    categories: {.arms, .chest, .coupon, .fullBody, .legs, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/a8zHUR3oPkI'),
  ),
  'Squirrel Splat': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .legs, .strength},
  ),
  'Squirrel splats': ExerciseEntry(categories: {.fullBody}),
  'Stagger Merkins': ExerciseEntry(categories: {.arms, .chest, .strength}),
  'StairBarrows': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .legs, .strength},
  ),
  'Stairway to Seven': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .legs, .strength},
  ),
  'Star Jack Burpee': ExerciseEntry(
    categories: {.arms, .cardio, .fullBody, .legs},
    videoUrl: Uri.parse('https://www.youtube.com/embed/nevefXTk2Lc'),
  ),
  'Star jumps': ExerciseEntry(categories: {.cardio}),
  'Starfish Crunch': ExerciseEntry(
    categories: {.arms, .cardio, .core, .fullBody},
  ),
  'Steel Blades': ExerciseEntry(categories: {.core, .legs}),
  'Step into the Circle': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .shoulders, .strength},
  ),
  'Step Ups': ExerciseEntry(categories: {.chest, .legs}),
  'Step-ups': ExerciseEntry(categories: {.legs}),
  'Steve Earle': ExerciseEntry(
    categories: {.arms, .cardio, .fullBody, .legs, .strength},
  ),
  'Still C.A.L.V.E.S.': ExerciseEntry(categories: {.fullBody}),
  'Stink B.O.M.B.S.': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .legs, .strength},
  ),
  'Stirkin': ExerciseEntry(categories: {.arms, .chest}),
  'Stump Huggers': ExerciseEntry(
    categories: {.arms, .cardio, .core, .fullBody},
  ),
  'Subprime punches': ExerciseEntry(categories: {.fullBody}),
  'Sugar Bear Crawls': ExerciseEntry(categories: {.cardio, .fullBody, .legs}),
  'Sugar Cookie': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .legs, .strength},
  ),
  'Suicide Ladder': ExerciseEntry(categories: {.cardio}),
  'Suicide Squats': ExerciseEntry(categories: {.cardio, .legs, .shoulders}),
  'Suicides': ExerciseEntry(categories: {.cardio}),
  'Sumo Deadlift High Pull (SDHP)': ExerciseEntry(
    categories: {.arms, .core, .coupon, .fullBody, .shoulders, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/6uS-XDV_mnM'),
  ),
  'Sumo Squat': ExerciseEntry(categories: {.cardio, .legs}),
  'Sumo squats': ExerciseEntry(categories: {.legs}),
  'Super 21': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'Superman': ExerciseEntry(categories: {.arms, .legs}),
  'Superman holds': ExerciseEntry(categories: {.fullBody}),
  'Superman Merkin': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'Superman Yellow Sun (and Red Sun)': ExerciseEntry(categories: {.fullBody}),
  'Supines': ExerciseEntry(categories: {.core}),
  'Surfees': ExerciseEntry(categories: {.cardio, .fullBody}),
  'Surfer Merkin': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .strength},
  ),
  'Surftanamo': ExerciseEntry(categories: {.fullBody}),
  'Suzanne Somers': ExerciseEntry(categories: {.legs}),
  'Sweat Angels': ExerciseEntry(categories: {.arms, .core, .legs}),
  'Swerkins': ExerciseEntry(categories: {.chest, .strength}),
  'Swingset Orangutans': ExerciseEntry(categories: {.cardio, .core, .strength}),
  'Swirley': ExerciseEntry(
    categories: {.arms, .chest, .fullBody, .legs, .shoulders, .strength},
  ),
  'T-Bomb': ExerciseEntry(categories: {.core, .legs}),
  'TaMABA': ExerciseEntry(categories: {.cardio, .fullBody}),
  'Tammy Wynette': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'Tempo Merkin': ExerciseEntry(
    categories: {.arms, .chest, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/zUQJDjb3L_M'),
  ),
  'Tennessee Iditarod': ExerciseEntry(categories: {.cardio}),
  'The 2020 Gobbler Challenge': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .chest,
      .coupon,
      .fullBody,
      .legs,
      .shoulders,
      .strength,
    },
    videoUrl: Uri.parse('https://www.youtube.com/embed/m16h07lyNCE'),
  ),
  'The 2021 Gobbler Challenge': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .legs, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/wg_ahVcr5_M'),
  ),
  'The 2022 Gobbler Challenge': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .chest,
      .core,
      .coupon,
      .fullBody,
      .legs,
      .shoulders,
      .strength,
    },
    videoUrl: Uri.parse('https://www.youtube.com/embed/cjSPVj6NWOA'),
  ),
  'The 2023 Gobbler Challenge': ExerciseEntry(
    categories: {.arms, .coupon, .fullBody, .legs, .shoulders, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/nAFBSG1c9mc'),
  ),
  'The 2024 Gobbler Challenge': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .coupon,
      .fullBody,
      .legs,
      .shoulders,
      .strength,
    },
    videoUrl: Uri.parse('https://www.youtube.com/embed/z6upM8KNgiE'),
  ),
  'The 2025 Gobbler Challenge - “Ladder of Pain” AMRAP': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .chest,
      .core,
      .coupon,
      .fullBody,
      .legs,
      .strength,
    },
  ),
  'The Bruce and the Cait': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'The Butkus': ExerciseEntry(categories: {.cardio, .coupon, .strength}),
  'The Cooper': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .legs, .strength},
  ),
  'The Cycle': ExerciseEntry(categories: {.cardio, .coupon, .fullBody}),
  'The Dab': ExerciseEntry(categories: {.cardio, .core, .fullBody}),
  'The Dirty Dog': ExerciseEntry(categories: {.core}),
  'The Donatello': ExerciseEntry(categories: {.cardio}),
  'The Doogie': ExerciseEntry(
    categories: {.cardio, .coupon, .fullBody, .legs, .strength},
  ),
  'The Dumbledore': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .chest,
      .fullBody,
      .legs,
      .shoulders,
      .strength,
    },
  ),
  'The Elwood': ExerciseEntry(categories: {.arms, .cardio}),
  'The Grateful Dead (aka Dancing Bear)': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'The Gross': ExerciseEntry(categories: {.fullBody}),
  'The Hightower': ExerciseEntry(categories: {.fullBody}),
  'The Hodor': ExerciseEntry(
    categories: {.arms, .coupon, .fullBody, .legs, .strength},
  ),
  'The Incredible Murder Bunny': ExerciseEntry(
    categories: {.cardio, .coupon, .fullBody, .legs, .strength},
  ),
  'The Jeffrey Leonard': ExerciseEntry(
    categories: {.arms, .cardio, .coupon, .shoulders},
  ),
  'The Killer Gnat': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .legs, .strength},
  ),
  'The King Louie': ExerciseEntry(categories: {.cardio, .fullBody, .legs}),
  'The Lion King': ExerciseEntry(
    categories: {.chest, .coupon, .legs, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/-CjNbx3gjOc'),
  ),
  'The Maggie': ExerciseEntry(
    categories: {.arms, .chest, .core, .coupon, .fullBody, .legs, .strength},
  ),
  'The Man from LARAMIE': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .core,
      .fullBody,
      .legs,
      .shoulders,
      .strength,
    },
  ),
  'The Oddjob': ExerciseEntry(categories: {.cardio, .fullBody}),
  'The Pete Hegseth Mile': ExerciseEntry(categories: {.cardio, .strength}),
  'The Sheldon Cooper': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .legs, .strength},
  ),
  'The Sketch': ExerciseEntry(categories: {.fullBody}),
  'The Swimmer': ExerciseEntry(categories: {.coupon}),
  'The W.A.S.H.': ExerciseEntry(categories: {.arms, .cardio, .fullBody, .legs}),
  'The Wifey': ExerciseEntry(categories: {.core}),
  'The Wolverine': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .strength},
  ),
  'Theresa': ExerciseEntry(categories: {.cardio, .core}),
  'Thigh Master': ExerciseEntry(categories: {.legs}),
  'Three Amigos': ExerciseEntry(categories: {.cardio, .fullBody, .legs}),
  'Thruster Mountain': ExerciseEntry(
    categories: {.core, .coupon, .fullBody, .shoulders, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/Rc4sxBe6bSg'),
  ),
  'Thrusters': ExerciseEntry(
    categories: {.arms, .coupon, .fullBody, .shoulders, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/5NjbJnofiSI'),
  ),
  'Thunderstruck': ExerciseEntry(
    categories: {.arms, .chest, .core, .coupon, .fullBody, .strength},
  ),
  'Till I Collapse': ExerciseEntry(categories: {.core}),
  'Tippin\' Coupons Workout': ExerciseEntry(
    categories: {.cardio, .coupon, .fullBody, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/ajebkw4w4_Q'),
  ),
  'Tony Hawk Burpee': ExerciseEntry(
    categories: {.cardio, .fullBody},
    videoUrl: Uri.parse('https://www.youtube.com/embed/-1vvMhbDi-A'),
  ),
  'TONYA HARDING': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/wTIOzm92tEE'),
  ),
  'Tooth Fairy': ExerciseEntry(categories: {.arms, .cardio, .chest, .strength}),
  'Top Gun': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .coupon,
      .fullBody,
      .legs,
      .shoulders,
      .strength,
    },
  ),
  'Tortoise and the Hare B.O.M.B.S.': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .chest,
      .core,
      .coupon,
      .fullBody,
      .legs,
      .strength,
    },
  ),
  'Tour de Humpers': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .legs, .strength},
  ),
  'Towel Circuit (Multiple Resistance Exercises)': ExerciseEntry(
    categories: {.arms, .chest, .fullBody, .legs, .shoulders, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/zEmvEXmiuuE'),
  ),
  'Tower of Power': ExerciseEntry(
    categories: {
      .arms,
      .chest,
      .core,
      .coupon,
      .fullBody,
      .shoulders,
      .strength,
    },
    videoUrl: Uri.parse('https://www.youtube.com/embed/1phHZt0SHFE'),
  ),
  'Toxic Run': ExerciseEntry(
    categories: {.arms, .cardio, .coupon, .fullBody, .shoulders, .strength},
  ),
  'Traveling Side Straddle Hop': ExerciseEntry(
    categories: {.cardio},
    videoUrl: Uri.parse('https://www.youtube.com/embed/-XbT5mFhFCU'),
  ),
  'Travolta Merkins': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'Travoltas': ExerciseEntry(categories: {.arms, .core, .shoulders}),
  'Tricep dips': ExerciseEntry(categories: {.arms, .strength}),
  'Triple check': ExerciseEntry(categories: {.cardio, .core, .fullBody, .legs}),
  'Triple nickel': ExerciseEntry(categories: {.cardio}),
  'Triple pump squat jumps': ExerciseEntry(categories: {.cardio, .legs}),
  'Tunnel of love': ExerciseEntry(
    categories: {.cardio, .core, .coupon, .fullBody},
    videoUrl: Uri.parse('https://www.youtube.com/embed/PQUJsG8j9jo'),
  ),
  'Turk n burp': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .legs, .strength},
  ),
  'Turkish get up': ExerciseEntry(categories: {.arms, .fullBody, .legs}),
  'Turn and bounce': ExerciseEntry(categories: {.fullBody}),
  'Twerkin': ExerciseEntry(categories: {.arms, .chest, .shoulders, .strength}),
  'Twin Tower of Trust': ExerciseEntry(
    categories: {.cardio, .coupon, .fullBody},
  ),
  'Twinkle toes': ExerciseEntry(categories: {.arms, .legs}),
  'Two Coupon Dip': ExerciseEntry(
    categories: {
      .arms,
      .chest,
      .core,
      .coupon,
      .fullBody,
      .legs,
      .shoulders,
      .strength,
    },
    videoUrl: Uri.parse('https://www.youtube.com/embed/4sTmrEwElgU'),
  ),
  'TYFBAF (Thank You For Being A Friend)': ExerciseEntry(
    categories: {.cardio, .fullBody},
  ),
  'UHaul': ExerciseEntry(categories: {.arms, .chest, .coupon, .strength}),
  'Ultimate football': ExerciseEntry(
    categories: {.arms, .cardio, .core, .fullBody, .strength},
  ),
  'Ultimate frisburpee': ExerciseEntry(categories: {.cardio, .core, .fullBody}),
  'Uncle Mary': ExerciseEntry(categories: {.core}),
  'Underdog': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'Up Dog': ExerciseEntry(categories: {.fullBody}),
  'Up downs': ExerciseEntry(categories: {.cardio, .chest}),
  'Up straddle hop': ExerciseEntry(
    categories: {.arms, .cardio, .core, .coupon, .fullBody, .legs, .strength},
  ),
  'Upper Decker': ExerciseEntry(
    categories: {.cardio, .legs},
    videoUrl: Uri.parse('https://www.youtube.com/embed/ndVBV8J_Ddg'),
  ),
  'Upright row': ExerciseEntry(
    categories: {.arms, .core, .coupon, .fullBody, .shoulders, .strength},
  ),
  'Uptown 50': ExerciseEntry(
    categories: {.arms, .cardio, .core, .coupon, .fullBody, .legs, .strength},
  ),
  'V-Up': ExerciseEntry(
    categories: {.arms, .core, .fullBody, .legs, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/u6-ABXuejjU'),
  ),
  'V-up roll up': ExerciseEntry(categories: {.core}),
  'V-Up Roll-Up': ExerciseEntry(
    categories: {.arms, .cardio, .core, .fullBody, .legs},
    videoUrl: Uri.parse('https://www.youtube.com/embed/JG_26sQhJfc'),
  ),
  'V-ups': ExerciseEntry(categories: {.core}),
  'Vacuum cleaners': ExerciseEntry(
    categories: {.arms, .chest, .fullBody, .legs, .strength},
  ),
  'Van Goghda': ExerciseEntry(categories: {.core, .legs}),
  'Vertigos': ExerciseEntry(categories: {.cardio}),
  'Vevo punches': ExerciseEntry(categories: {.fullBody}),
  'Vevos': ExerciseEntry(categories: {.fullBody}),
  'Vicious circle': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .legs, .strength},
  ),
  'Wake Up! (Chop Suey!)': ExerciseEntry(categories: {.cardio}),
  'Walk Like An Egyptian': ExerciseEntry(categories: {.chest, .core, .legs}),
  'Walk The Dog': ExerciseEntry(
    categories: {.arms, .coupon, .fullBody, .shoulders, .strength},
  ),
  'Walkerstrong': ExerciseEntry(categories: {.cardio, .legs}),
  'Wall conveyor': ExerciseEntry(categories: {.cardio, .shoulders}),
  'Wall sit': ExerciseEntry(categories: {.legs}),
  'Wall worms': ExerciseEntry(categories: {.shoulders}),
  'Walls of Jericho': ExerciseEntry(categories: {.cardio}),
  'Walmart Burpee': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .chest,
      .core,
      .fullBody,
      .legs,
      .shoulders,
      .strength,
    },
    videoUrl: Uri.parse('https://www.youtube.com/embed/eNECV4x6xRM'),
  ),
  'War hammer': ExerciseEntry(categories: {.core}),
  'Water wheel': ExerciseEntry(categories: {.legs}),
  'Wave of merkins': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
  ),
  'We\'re Not Worthy': ExerciseEntry(
    categories: {.fullBody},
    videoUrl: Uri.parse('https://www.youtube.com/embed/vde8UShX4f4'),
  ),
  'Webbicide': ExerciseEntry(categories: {.arms, .cardio, .chest, .strength}),
  'Weezy Jefferson': ExerciseEntry(categories: {.core, .legs}),
  'Welcome party': ExerciseEntry(categories: {.fullBody}),
  'Welsh dragons': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .chest,
      .core,
      .fullBody,
      .shoulders,
      .strength,
    },
  ),
  'Werewolf': ExerciseEntry(
    categories: {.arms, .core, .fullBody, .shoulders, .strength},
  ),
  'Werkin': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .shoulders, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/9l3Rj4kFInA'),
  ),
  'Werkins': ExerciseEntry(categories: {.fullBody}),
  'Whamo lunge walks': ExerciseEntry(
    categories: {.arms, .cardio, .core, .fullBody, .legs, .strength},
  ),
  'Wheel of animal walk': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .core, .fullBody, .legs, .strength},
  ),
  'Wheel of merkin': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .legs, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/XNY0COXZLPs'),
  ),
  'When Animals Attack': ExerciseEntry(categories: {.fullBody}),
  'Wilson\'s Wife': ExerciseEntry(categories: {.fullBody}),
  'Wilt Chamberlains': ExerciseEntry(
    categories: {.cardio, .core, .fullBody, .legs},
  ),
  'Windmill': ExerciseEntry(
    categories: {.arms, .shoulders, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/lSwhW-X3Ijo'),
  ),
  'Windshield wipers': ExerciseEntry(categories: {.core, .legs}),
  'Wing nut': ExerciseEntry(categories: {.arms, .chest, .shoulders, .strength}),
  'Wmd': ExerciseEntry(categories: {.fullBody}),
  'Wmd crawl': ExerciseEntry(categories: {.cardio, .fullBody}),
  'Wojo squats': ExerciseEntry(categories: {.legs}),
  'Wood chopper': ExerciseEntry(
    categories: {
      .arms,
      .cardio,
      .core,
      .coupon,
      .fullBody,
      .shoulders,
      .strength,
    },
  ),
  'Wooly worm aka inch worm.': ExerciseEntry(
    categories: {.cardio, .chest, .core, .strength},
  ),
  'World War I Sit-up': ExerciseEntry(categories: {.arms, .core, .legs}),
  'World War I Snow Angel': ExerciseEntry(
    categories: {.core},
    videoUrl: Uri.parse('https://www.youtube.com/embed/0Z-sMDq9soc'),
  ),
  'World War II Sit-up': ExerciseEntry(
    categories: {.arms, .core},
    videoUrl: Uri.parse('https://www.youtube.com/embed/_WZWdDRYcSs'),
  ),
  'World War III Sit-up': ExerciseEntry(
    categories: {
      .arms,
      .chest,
      .core,
      .coupon,
      .fullBody,
      .shoulders,
      .strength,
    },
    videoUrl: Uri.parse('https://www.youtube.com/embed/r7AAZU_TZx8'),
  ),
  'Worst merkin ever': ExerciseEntry(
    categories: {.arms, .chest, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/RSaMakUl7X0'),
  ),
  'Worst Merkin Ever Crawl': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .strength},
  ),
  'Worst worst merkin ever': ExerciseEntry(
    categories: {.arms, .chest, .strength},
  ),
  'Wounded bear crawl': ExerciseEntry(
    categories: {.arms, .cardio, .fullBody},
    videoUrl: Uri.parse('https://www.youtube.com/embed/a4S0E9ZHvc4'),
  ),
  'X Gon\' Give It To Ya': ExerciseEntry(
    categories: {.arms, .cardio, .core, .fullBody, .legs},
  ),
  'X-Cross Sit-up': ExerciseEntry(
    categories: {.arms, .core, .fullBody, .legs, .shoulders, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/9WFz28z96rE'),
  ),
  'X-Factor': ExerciseEntry(
    categories: {.arms, .core, .legs},
    videoUrl: Uri.parse('https://www.youtube.com/embed/WEvHN6PqckU'),
  ),
  'Xs and Os': ExerciseEntry(
    categories: {.arms, .fullBody, .legs, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/1IGc4GiC67M'),
  ),
  'XYs': ExerciseEntry(
    categories: {.core, .legs},
    videoUrl: Uri.parse('https://www.youtube.com/embed/LMAojhsg2FA'),
  ),
  'Yoke walk': ExerciseEntry(
    categories: {.arms, .coupon, .fullBody, .shoulders, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/oEv5fH53dW8'),
  ),
  'Yul Brynner': ExerciseEntry(
    categories: {.arms, .chest, .core, .fullBody, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/aY7PUCnn3Mo'),
  ),
  'Yurpee': ExerciseEntry(
    categories: {.arms, .cardio, .chest, .fullBody, .strength},
    videoUrl: Uri.parse('https://www.youtube.com/embed/KCtWKjZTtW0'),
  ),
  'Yves Poll': ExerciseEntry(categories: {.cardio}),
  'Zebra butt-kicks': ExerciseEntry(
    categories: {.cardio, .core, .fullBody, .legs},
    videoUrl: Uri.parse('https://www.youtube.com/embed/JojIvtvvCxk'),
  ),
  'Zig-zag hops': ExerciseEntry(
    categories: {.cardio},
    videoUrl: Uri.parse('https://www.youtube.com/embed/_zQGUWYx_rY'),
  ),
  'Zombie crawl': ExerciseEntry(
    categories: {.cardio, .core, .fullBody, .legs},
    videoUrl: Uri.parse('https://www.youtube.com/embed/_P8xVO1ubyg'),
  ),
  'Zombie crunch': ExerciseEntry(
    categories: {.cardio, .core, .fullBody, .legs},
    videoUrl: Uri.parse('https://www.youtube.com/embed/pA73P0QFOcA'),
  ),
  'Zombie Merkins': ExerciseEntry(
    categories: {.arms, .chest, .shoulders, .strength},
  ),
  'Zombie walk': ExerciseEntry(categories: {.cardio, .legs}),
};
