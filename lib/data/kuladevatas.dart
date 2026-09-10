/// Common Kuladevata/Kuladevi names within the Daivajna Samaj, offered as a
/// convenience picker on the profile edit screen. NOT an authoritative
/// community-wide list — the backend's own Parampara module deliberately
/// keeps its Kuladevata master list empty, since a family's Kuladevata is
/// genuinely family-specific, never a shared constant (see the server's
/// kuladevata.master.ts doc comment). Selecting one of these still saves as
/// a plain USER_DECLARED free-text value, exactly like typing it by hand —
/// this list only saves people from typing it.
const List<String> kKuladevatas = [
  'Shree Shantadurga / Santeri',
  'Shree Mahalasa',
  'Shree Kalika',
  'Shree Mahamaya',
  'Shree Chamundeshwari',
  'Shree Gajant-Lakshmi',
  'Shree Kamakshi',
  'Shree Bhagavati',
  'Shree Mahalakshmi',
  'Shree Navadurga',
  'Shree Nagesh / Nageshi',
  'Shree Ravalnath',
  'Shree Shivnath',
  'Shree Vimaleshwar',
  'Shree Someshwar',
  'Shree Vetal / Vetaleshwar',
  'Shree Rayeshwar',
  'Shree Ramnath / Ramnathi',
];

/// Bundled deity photos for a handful of Kuladevata entries, shown as a small
/// tappable thumbnail next to the name wherever it's picked or displayed.
/// Entries without a photo here just render as plain text — this is a
/// convenience, not a requirement.
const Map<String, String> kKuladevataImages = {
  'Shree Shantadurga / Santeri':
      'assets/images/kuladevata/shree_shantadurga.png',
  'Shree Mahalasa': 'assets/images/kuladevata/shree_mahalasa.png',
  'Shree Kalika': 'assets/images/kuladevata/shree_kalika.png',
  'Shree Mahamaya': 'assets/images/kuladevata/shree_mahamaya.png',
  'Shree Chamundeshwari': 'assets/images/kuladevata/shree_chamundeshwari.png',
  'Shree Gajant-Lakshmi': 'assets/images/kuladevata/shree_gajant_lakshmi.png',
  'Shree Kamakshi': 'assets/images/kuladevata/shree_kamakshi.png',
  'Shree Bhagavati': 'assets/images/kuladevata/shree_bhagavati.png',
  'Shree Mahalakshmi': 'assets/images/kuladevata/shree_mahalakshmi.png',
  'Shree Navadurga': 'assets/images/kuladevata/shree_navadurga.png',
  'Shree Nagesh / Nageshi': 'assets/images/kuladevata/shree_nagesh.png',
  'Shree Ravalnath': 'assets/images/kuladevata/shree_ravalnath.png',
  'Shree Shivnath': 'assets/images/kuladevata/shree_shivnath.png',
  'Shree Vimaleshwar': 'assets/images/kuladevata/shree_vimaleshwar.png',
  'Shree Someshwar': 'assets/images/kuladevata/shree_someshwar.png',
  'Shree Vetal / Vetaleshwar': 'assets/images/kuladevata/shree_vetal.png',
  'Shree Rayeshwar': 'assets/images/kuladevata/shree_rayeshwar.png',
  'Shree Ramnath / Ramnathi': 'assets/images/kuladevata/shree_ramnath.png',
};
