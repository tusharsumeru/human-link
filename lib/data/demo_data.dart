// Daivajna Samaja — demo data ported verbatim from the web app's lib/data.ts.
// Used as the offline source of truth and as a fallback when the Next.js API
// is unreachable. Field names match the web objects exactly so screens read
// values the same way the React pages do.
import 'avatars.dart';

// Goldsmith lineage from Kundapura/Kumta, now rooted in Bengaluru.
const List<Map<String, dynamic>> kFamilyMembers = [
  {
    'id': '1', 'name': 'Ramachandra Suvarna', 'status': 'Late', 'gotra': 'Kashyap',
    'native': 'Kundapura, Karnataka', 'relation': 'Great Grandfather', 'avatar': 'RS',
    'occupation': 'Master Goldsmith & Jeweller', 'birthYear': '1920', 'children': ['2', '3'],
  },
  {
    'id': '2', 'name': 'Savitribai Suvarna', 'status': 'Late', 'gotra': 'Kashyap',
    'native': 'Kundapura, Karnataka', 'relation': 'Great Grandmother', 'avatar': 'SS',
    'occupation': 'Homemaker & Samaj Seva', 'birthYear': '1925', 'spouse': '1',
    'children': <String>[], 'parent': '1',
  },
  {
    'id': '3', 'name': 'Venkatesh Haldankar', 'status': 'Active', 'gotra': 'Bharadwaja',
    'native': 'Kumta, Uttara Kannada', 'relation': 'Grandfather', 'avatar': 'VH',
    'occupation': 'Retired Jewellery Business Owner', 'birthYear': '1952', 'parent': '1',
    'children': ['4', '5'],
  },
  {
    'id': '4', 'name': 'Suresh Haldankar', 'status': 'Active', 'gotra': 'Kashyap',
    'native': 'Udupi, Karnataka', 'relation': 'Father', 'avatar': 'SH',
    'occupation': 'Senior Software Engineer, Infosys, Bengaluru', 'birthYear': '1978',
    'parent': '3', 'children': ['6'],
  },
  {
    'id': '5', 'name': 'Rekha Diwakar', 'status': 'Active', 'gotra': 'Bharadwaja',
    'native': 'Mangaluru, Karnataka', 'relation': 'Aunt', 'avatar': 'RD',
    'occupation': 'Principal, Kendriya Vidyalaya, Bengaluru', 'birthYear': '1975',
    'parent': '3', 'children': <String>[],
  },
  {
    'id': '6', 'name': 'Priya Haldankar', 'status': 'Active', 'gotra': 'Kashyap',
    'native': 'Bengaluru, Karnataka', 'relation': 'Self', 'avatar': 'PH',
    'occupation': 'UX Designer, Razorpay, Bengaluru', 'birthYear': '1999',
    'parent': '4', 'children': <String>[],
  },
];

final List<Map<String, dynamic>> kMatrimonialCandidates = [
  {
    'id': 'ananya-k', 'name': 'Ananya Kolwekar', 'age': 27, 'gender': 'F',
    'location': 'Bengaluru', 'gotra': 'Bharadwaja',
    'education': 'MBA Finance, IIM Bangalore', 'company': 'HDFC Bank — Wealth Management',
    'designation': 'Assistant Vice President', 'income': '₹22–28L', 'height': "5'4\"",
    'complexion': 'Wheatish', 'familyType': 'Joint',
    'fatherOccupation': 'Jeweller & Proprietor, Kolwekar Gold House, Commercial Street',
    'motherOccupation': 'Teacher, MES College, Bengaluru',
    'siblings': '1 Younger Brother, B.Tech, PESIT Bengaluru',
    'star': 'Rohini', 'rashi': 'Vrishabha', 'mangal': 'No', 'gotraSurname': 'Bharadwaja',
    'timeOfBirth': '10:45 AM',
    'partnerExpectations': [
      'Well-educated professional from Daivajna Samaja',
      'Preferably based in Bengaluru or Karnataka',
      'Family values and respect for Samaj traditions',
      'Age preference: 28–32 years',
    ],
    'about':
        'Raised in a traditional Daivajna Samaja family in Basavanagudi, Bengaluru. I love Carnatic music, cooking authentic Malvani cuisine, and participating in Samaj cultural events every year. Looking for a life partner who values both heritage and growth.',
    'verified': true, 'matrimonialFee': true, 'avatar': 'AK', 'photo': px(17184880),
  },
  {
    'id': 'rohit-s', 'name': 'Rohit Suvarna', 'age': 30, 'gender': 'M',
    'location': 'Bengaluru', 'gotra': 'Kashyap',
    'education': 'B.Tech Computer Science, NIT Surathkal', 'company': 'Wipro — Product Division',
    'designation': 'Senior Software Engineer', 'income': '₹20–25L', 'height': "5'10\"",
    'complexion': 'Wheatish', 'familyType': 'Joint',
    'fatherOccupation': 'Proprietor, Suvarna Jewellers, Chickpete, Bengaluru',
    'motherOccupation': 'Homemaker',
    'siblings': '1 Elder Sister, Married into Raikar family, Mangaluru',
    'star': 'Uttara Phalguni', 'rashi': 'Kanya', 'mangal': 'No', 'gotraSurname': 'Kashyap',
    'timeOfBirth': '08:20 AM',
    'partnerExpectations': [
      'Working professional from Daivajna Samaja',
      'Family-oriented and respects Samaj culture',
      'Comfortable with joint family in Bengaluru',
    ],
    'about':
        'Born and raised in R.T. Nagar, Bengaluru. Our family has been in the jewellery business for three generations in Chickpete. I enjoy trekking in the Western Ghats and volunteering at Samaj community events. Looking for a partner who balances tradition with a modern outlook.',
    'verified': true, 'matrimonialFee': false, 'avatar': 'RS', 'photo': px(3131428),
  },
  {
    'id': 'sneha-n', 'name': 'Sneha Nethalkar', 'age': 25, 'gender': 'F',
    'location': 'Mangaluru', 'gotra': 'Vasishtha',
    'education': 'CA (ICAI), B.Com St. Aloysius College, Mangaluru',
    'company': 'Deloitte India — Audit', 'designation': 'Deputy Manager, Audit & Assurance',
    'income': '₹18–22L', 'height': "5'3\"", 'complexion': 'Fair', 'familyType': 'Nuclear',
    'fatherOccupation': 'Senior Goldsmith, Nethalkar & Sons Jewellers, Mangaluru',
    'motherOccupation': 'Homemaker', 'siblings': '1 Younger Brother, CA Articleship',
    'star': 'Ashwini', 'rashi': 'Mesha', 'mangal': 'Yes', 'gotraSurname': 'Vasishtha',
    'timeOfBirth': '02:30 PM',
    'partnerExpectations': [
      'Mangalik preferred',
      'Willing to relocate to Bengaluru or Mangaluru',
      'Professionally qualified (CA / MBA / Engineer)',
    ],
    'about':
        'A first-generation CA from a proud Daivajna Samaja family from Mangaluru. Passionate about finance, Tulu folk arts, and cooking traditional Kundapur cuisine. Weekends are for temple visits and Samaj bhajans. I believe a strong marriage rests on shared cultural roots.',
    'verified': true, 'matrimonialFee': true, 'avatar': 'SN', 'photo': px(29201034),
  },
  {
    'id': 'karthik-p', 'name': 'Karthik Revankar', 'age': 29, 'gender': 'M',
    'location': 'Bengaluru', 'gotra': 'Atreya',
    'education': 'MBA IIM Bangalore, B.E. R.V. College of Engineering',
    'company': 'Razorpay — Growth', 'designation': 'Senior Product Manager',
    'income': '₹32–38L', 'height': "5'9\"", 'complexion': 'Wheatish', 'familyType': 'Nuclear',
    'fatherOccupation': 'Advocate, Karnataka High Court, Bengaluru',
    'motherOccupation': 'Sanskrit Lecturer, Bengaluru University', 'siblings': 'None',
    'star': 'Mrigashira', 'rashi': 'Mithuna', 'mangal': 'No', 'gotraSurname': 'Atreya',
    'timeOfBirth': '06:15 PM',
    'partnerExpectations': [
      'Educated and independent-minded woman from the Samaj',
      'Based in or willing to move to Bengaluru',
      'Values Sanskrit, classical music, and Samaj traditions',
    ],
    'about':
        'Raised in Jayanagar, Bengaluru — a true product of the Daivajna Samaja diaspora. Product manager by day, Carnatic vocalist and Samaj committee volunteer by weekend. Deeply proud of my goldsmith heritage while thriving in the startup world. Looking for a life partner who loves both heritage and adventure.',
    'verified': true, 'matrimonialFee': false, 'avatar': 'KR', 'photo': px(1856477),
  },
];

const List<Map<String, dynamic>> kWelfareCampaigns = [
  {
    'id': 'samaj-bhavan', 'title': 'Samaj Bhavan Renovation', 'category': 'Infrastructure',
    'description':
        'Renovation and expansion of the Daivajna Samaja Bhavan in Basavanagudi, Bengaluru — adding a 500-seat auditorium, digital library, and modern kitchen for community feasts.',
    'goal': 5000000, 'raised': 4250000, 'daysLeft': 12, 'backers': 328,
    'image': '🏛️', 'colorA': 0xFF166534, 'colorB': 0xFF16A34A,
  },
  {
    'id': 'annual-samaja-function', 'title': 'Annual Samaja Utsava 2025', 'category': 'Cultural Heritage',
    'description':
        'Funding for the flagship annual Samaj cultural event: classical Carnatic & Tulu performances, elder felicitation, Samaj talent showcase, and merit scholarships for 50 students.',
    'goal': 2500000, 'raised': 2000000, 'daysLeft': 28, 'backers': 214,
    'image': '🪔', 'colorA': 0xFF92400E, 'colorB': 0xFFD97706,
  },
  {
    'id': 'student-scholarship', 'title': 'Daivajna Vidya Nidhi — Scholarships', 'category': 'Education',
    'description':
        'Merit-cum-need scholarships for Samaj students pursuing engineering, medicine, and law. 30 scholarships of ₹50,000 each for the academic year 2025–26.',
    'goal': 1500000, 'raised': 875000, 'daysLeft': 45, 'backers': 167,
    'image': '🎓', 'colorA': 0xFF1E3A8A, 'colorB': 0xFF1D4ED8,
  },
];

final List<Map<String, dynamic>> kDashboardActivity = [
  {
    'id': 1, 'user': 'Venkatesh Haldankar', 'action': 'shared a memory',
    'detail': '"1968 Samaj Utsava in Kumta"', 'time': '2 hours ago', 'type': 'archive',
    'avatar': 'VH', 'photo': px(2601464),
  },
  {
    'id': 2, 'user': 'Shri Narayanarao Suvarna', 'action': 'verified the lineage of',
    'detail': 'Rohit Suvarna — Chickpete branch', 'time': 'Yesterday', 'type': 'tree',
    'avatar': 'NS', 'photo': px(17815020),
  },
  {
    'id': 3, 'user': 'Rekha Diwakar', 'action': 'has a birthday today!',
    'detail': 'Wishing her from the Samaj 🎉', 'time': 'Today', 'type': 'birthday',
    'avatar': 'RD', 'photo': px(34515496),
  },
];

const List<Map<String, dynamic>> kElderQueue = [
  {
    'id': 'arjun-s', 'name': 'Arjun Shirodkar',
    'claimingFrom': 'Kundapura Branch (Udupi District)',
    'relation': 'Grandson of Late Govind Shirodkar (Kundapura)',
    'hasDocument': true, 'vouches': 2, 'avatar': 'AS',
  },
  {
    'id': 'divya-n', 'name': 'Divya Pednekar',
    'claimingFrom': 'Kumta Branch (Uttara Kannada)',
    'relation': 'Daughter of Prakash Pednekar (3 elder vouches pending)',
    'hasDocument': false, 'hasPhoto': true, 'vouches': 3, 'avatar': 'DP',
  },
];

// 24 verified Daivajna Samaja members.
final List<Map<String, dynamic>> kCommunityMembers = [
  {'id': 'm1', 'name': 'Gopalakrishna Suvarna', 'age': 68, 'gender': 'M', 'branch': 'Kundapura', 'gotra': 'Kashyap', 'occupation': 'Retired Master Goldsmith', 'location': 'Kundapura, Udupi', 'status': 'Active', 'verified': true, 'joinedYear': 2019, 'photo': px(4053536)},
  {'id': 'm2', 'name': 'Mangala Suvarna', 'age': 64, 'gender': 'F', 'branch': 'Kundapura', 'gotra': 'Kashyap', 'occupation': 'Homemaker & Samaj Seva', 'location': 'Kundapura, Udupi', 'status': 'Active', 'verified': true, 'joinedYear': 2019, 'photo': px(11138457)},
  {'id': 'm3', 'name': 'Ganesh Suvarna', 'age': 42, 'gender': 'M', 'branch': 'Kundapura', 'gotra': 'Kashyap', 'occupation': 'Jewellery Business Owner', 'location': 'Kundapura, Udupi', 'status': 'Active', 'verified': true, 'joinedYear': 2021, 'photo': px(2601464)},
  {'id': 'm4', 'name': 'Rupa Madikar', 'age': 65, 'gender': 'F', 'branch': 'Kundapura', 'gotra': 'Vasishtha', 'occupation': 'Retired School Teacher', 'location': 'Kundapura, Udupi', 'status': 'Active', 'verified': true, 'joinedYear': 2020, 'photo': px(29201034)},
  {'id': 'm5', 'name': 'Akash Suvarna', 'age': 19, 'gender': 'M', 'branch': 'Kundapura', 'gotra': 'Kashyap', 'occupation': 'Engineering Student, NIT Surathkal', 'location': 'Kundapura, Udupi', 'status': 'Active', 'verified': false, 'joinedYear': 2025, 'photo': px(7345266)},
  {'id': 'm6', 'name': 'Vasudeva Vernekar', 'age': 57, 'gender': 'M', 'branch': 'Kumta', 'gotra': 'Bharadwaja', 'occupation': 'Chartered Accountant (Own Practice)', 'location': 'Kumta, Uttara Kannada', 'status': 'Active', 'verified': true, 'joinedYear': 2018, 'photo': px(5746790)},
  {'id': 'm7', 'name': 'Savita Haldankar', 'age': 52, 'gender': 'F', 'branch': 'Kumta', 'gotra': 'Atreya', 'occupation': 'Principal, Govt. High School, Kumta', 'location': 'Kumta, Uttara Kannada', 'status': 'Active', 'verified': true, 'joinedYear': 2018, 'photo': px(30004176)},
  {'id': 'm8', 'name': 'Deepak Vernekar', 'age': 31, 'gender': 'M', 'branch': 'Kumta', 'gotra': 'Bharadwaja', 'occupation': 'Software Engineer, Infosys, Pune', 'location': 'Kumta / Pune', 'status': 'Active', 'verified': true, 'joinedYear': 2022, 'photo': px(3131428)},
  {'id': 'm9', 'name': 'Nandini Kolwekar', 'age': 27, 'gender': 'F', 'branch': 'Kumta', 'gotra': 'Bharadwaja', 'occupation': 'CA Articleship, Bengaluru', 'location': 'Bengaluru, Karnataka', 'status': 'Active', 'verified': false, 'joinedYear': 2024, 'photo': px(17184880)},
  {'id': 'm10', 'name': 'Ravi Kumar Potdar', 'age': 50, 'gender': 'M', 'branch': 'Mangaluru', 'gotra': 'Kashyap', 'occupation': 'Textile Merchant, Hampankatta', 'location': 'Mangaluru, Karnataka', 'status': 'Active', 'verified': true, 'joinedYear': 2017, 'photo': px(17815020)},
  {'id': 'm11', 'name': 'Sumitra Potdar', 'age': 47, 'gender': 'F', 'branch': 'Mangaluru', 'gotra': 'Kashyap', 'occupation': 'General Physician, KMC Hospital', 'location': 'Mangaluru, Karnataka', 'status': 'Active', 'verified': true, 'joinedYear': 2017, 'photo': px(7485047)},
  {'id': 'm12', 'name': 'Girish Raikar', 'age': 44, 'gender': 'M', 'branch': 'Mangaluru', 'gotra': 'Atreya', 'occupation': 'Advocate, Karnataka High Court', 'location': 'Mangaluru, Karnataka', 'status': 'Active', 'verified': true, 'joinedYear': 2020, 'photo': px(1856477)},
  {'id': 'm13', 'name': 'Pooja Karekar', 'age': 29, 'gender': 'F', 'branch': 'Mangaluru', 'gotra': 'Vasishtha', 'occupation': 'HR Manager, TCS Mangaluru', 'location': 'Mangaluru, Karnataka', 'status': 'Active', 'verified': true, 'joinedYear': 2023, 'photo': px(34515496)},
  {'id': 'm14', 'name': 'Narayana Revankar', 'age': 62, 'gender': 'M', 'branch': 'Bengaluru', 'gotra': 'Bharadwaja', 'occupation': 'Retired IAS Officer', 'location': 'Bengaluru, Karnataka', 'status': 'Active', 'verified': true, 'joinedYear': 2016, 'photo': px(4053536)},
  {'id': 'm15', 'name': 'Lakshmi Revankar', 'age': 58, 'gender': 'F', 'branch': 'Bengaluru', 'gotra': 'Kashyap', 'occupation': 'Sanskrit Lecturer, Bengaluru Univ.', 'location': 'Bengaluru, Karnataka', 'status': 'Active', 'verified': true, 'joinedYear': 2016, 'photo': px(11138457)},
  {'id': 'm16', 'name': 'Vivek Kolwekar', 'age': 35, 'gender': 'M', 'branch': 'Bengaluru', 'gotra': 'Bharadwaja', 'occupation': 'Product Manager, Flipkart', 'location': 'Bengaluru, Karnataka', 'status': 'Active', 'verified': true, 'joinedYear': 2022, 'photo': px(2601464)},
  {'id': 'm17', 'name': 'Tejaswini Balgi', 'age': 32, 'gender': 'F', 'branch': 'Bengaluru', 'gotra': 'Kashyap', 'occupation': 'UI/UX Designer, Myntra', 'location': 'Bengaluru, Karnataka', 'status': 'Active', 'verified': true, 'joinedYear': 2023, 'photo': px(7485047)},
  {'id': 'm18', 'name': 'Rajesh Bidnolikar', 'age': 47, 'gender': 'M', 'branch': 'Bengaluru', 'gotra': 'Atreya', 'occupation': 'Entrepreneur, Bidnolikar Jewels Pvt.', 'location': 'Bengaluru, Karnataka', 'status': 'Active', 'verified': true, 'joinedYear': 2019, 'photo': px(5746790)},
  {'id': 'm19', 'name': 'Kavitha Pednekar', 'age': 55, 'gender': 'F', 'branch': 'Bengaluru', 'gotra': 'Vasishtha', 'occupation': 'Principal, Kendriya Vidyalaya', 'location': 'Bengaluru, Karnataka', 'status': 'Active', 'verified': true, 'joinedYear': 2018, 'photo': px(30004176)},
  {'id': 'm20', 'name': 'Yash Vernekar', 'age': 23, 'gender': 'M', 'branch': 'Bengaluru', 'gotra': 'Bharadwaja', 'occupation': 'B.Tech Student, RV College', 'location': 'Bengaluru, Karnataka', 'status': 'Active', 'verified': false, 'joinedYear': 2025, 'photo': px(7345266)},
  {'id': 'm21', 'name': 'Usha Gaunkar', 'age': 43, 'gender': 'F', 'branch': 'Bengaluru', 'gotra': 'Atreya', 'occupation': 'Gynecologist, Manipal Hospital', 'location': 'Bengaluru, Karnataka', 'status': 'Active', 'verified': true, 'joinedYear': 2020, 'photo': px(17184880)},
  {'id': 'm22', 'name': 'Subramanya Shirodkar', 'age': 70, 'gender': 'M', 'branch': 'Udupi', 'gotra': 'Kashyap', 'occupation': 'Retired Bank Manager, SBI', 'location': 'Udupi, Karnataka', 'status': 'Active', 'verified': true, 'joinedYear': 2015, 'photo': px(17815020)},
  {'id': 'm23', 'name': 'Parvati Shirodkar', 'age': 67, 'gender': 'F', 'branch': 'Udupi', 'gotra': 'Kashyap', 'occupation': 'Homemaker & Temple Trustee', 'location': 'Udupi, Karnataka', 'status': 'Active', 'verified': true, 'joinedYear': 2015, 'photo': px(29201034)},
  {'id': 'm24', 'name': 'Sudarshan Lotlikar', 'age': 55, 'gender': 'M', 'branch': 'Out-of-State', 'gotra': 'Atreya', 'occupation': 'Mechanical Engineer, Pune', 'location': 'Pune, Maharashtra', 'status': 'Active', 'verified': true, 'joinedYear': 2021, 'photo': px(1856477)},
];

// 10 detailed pending verification records.
final List<Map<String, dynamic>> kVerificationRequests = [
  {
    'id': 'arjun-s', 'name': 'Arjun Shirodkar', 'age': 28, 'gender': 'M', 'photo': px(7345266),
    'location': 'Bengaluru, Karnataka', 'phone': '98765 ••••••',
    'claimingFrom': 'Kundapura Branch (Udupi District)',
    'claimingAncestor': 'Late Govind Shirodkar (Kundapura, 1938–2012)',
    'relation': 'Grandson — father: Mohan Shirodkar (not yet registered in system)',
    'submittedOn': '12 May 2026', 'aadhaarStatus': 'Verified', 'hasDocument': true, 'hasPhoto': true,
    'documents': ["Aadhaar Card", "Birth Certificate", "Parents' Marriage Certificate"],
    'vouches': 2, 'vouchesRequired': 3,
    'vouchDetails': [
      {'name': 'Shri Narayanarao Suvarna', 'role': 'Elder, Kumta Branch', 'status': 'Approved'},
      {'name': 'Gopalakrishna Suvarna', 'role': 'Member, Kundapura Branch', 'status': 'Approved'},
      {'name': 'Elder Sub-committee', 'role': '3rd vouch required', 'status': 'Pending'},
    ],
    'lineageNotes': 'Father Mohan Shirodkar is not yet registered. Cross-reference with Kundapura branch records from 1982 recommended before final approval.',
    'riskLevel': 'low', 'status': 'pending', 'occupation': 'Software Developer, Accenture', 'gotra': 'Kashyap',
  },
  {
    'id': 'divya-n', 'name': 'Divya Pednekar', 'age': 26, 'gender': 'F', 'photo': px(30004176),
    'location': 'Kumta, Uttara Kannada', 'phone': '97712 ••••••',
    'claimingFrom': 'Kumta Branch (Uttara Kannada)',
    'claimingAncestor': 'Prakash Pednekar (Kumta, registered member since 2018)',
    'relation': 'Daughter of Prakash Pednekar — birth certificate submitted',
    'submittedOn': '10 May 2026', 'aadhaarStatus': 'Pending', 'hasDocument': false, 'hasPhoto': true,
    'documents': ['Photo Proof (Selfie with Prakash Pednekar)', 'School Leaving Certificate'],
    'vouches': 3, 'vouchesRequired': 3,
    'vouchDetails': [
      {'name': 'Vasudeva Vernekar', 'role': 'Elder, Kumta Branch', 'status': 'Approved'},
      {'name': 'Savita Haldankar', 'role': 'Member, Kumta Branch', 'status': 'Approved'},
      {'name': 'Shri Narayanarao Suvarna', 'role': 'Elder, Committee Head', 'status': 'Approved'},
    ],
    'lineageNotes': 'All 3 vouches confirmed. Aadhaar upload pending from applicant. Can proceed to conditional approval while Aadhaar is uploaded.',
    'riskLevel': 'low', 'status': 'pending', 'occupation': 'B.Com Student, SDM College, Kumta', 'gotra': 'Vasishtha',
  },
  {
    'id': 'mahesh-v', 'name': 'Mahesh Vernekar', 'age': 45, 'gender': 'M', 'photo': px(5746790),
    'location': 'Bengaluru, Karnataka', 'phone': '99001 ••••••',
    'claimingFrom': 'Mangaluru Branch',
    'claimingAncestor': 'Late Krishnarao Vernekar (Mangaluru, 1930–1998)',
    'relation': 'Grandson via father Ramesh Vernekar (deceased, 1967–2019)',
    'submittedOn': '08 May 2026', 'aadhaarStatus': 'Verified', 'hasDocument': true, 'hasPhoto': false,
    'documents': ['Aadhaar Card', "Father's Death Certificate", 'Ancestral Property Paper mentioning lineage'],
    'vouches': 1, 'vouchesRequired': 3,
    'vouchDetails': [
      {'name': 'Ravi Kumar Potdar', 'role': 'Member, Mangaluru Branch', 'status': 'Approved'},
      {'name': 'Elder Sub-committee', 'role': '2nd vouch required', 'status': 'Pending'},
      {'name': 'Elder Sub-committee', 'role': '3rd vouch required', 'status': 'Pending'},
    ],
    'lineageNotes': 'Ancestral property record references Krishnarao Vernekar as goldsmith in Mangaluru, 1960s. Father\'s branch not found in registry. Requires deeper genealogical audit.',
    'riskLevel': 'medium', 'status': 'pending', 'occupation': 'IT Manager, Wipro, Bengaluru', 'gotra': 'Kashyap',
  },
  {
    'id': 'preethi-s', 'name': 'Preethi Suvarna', 'age': 23, 'gender': 'F', 'photo': px(17184880),
    'location': 'Bengaluru, Karnataka', 'phone': '90081 ••••••',
    'claimingFrom': 'Bengaluru Branch (First Registration)',
    'claimingAncestor': 'Sudhir Suvarna (father, registered member m3)',
    'relation': 'Daughter of Sudhir Suvarna — direct first-time registration',
    'submittedOn': '14 May 2026', 'aadhaarStatus': 'Verified', 'hasDocument': true, 'hasPhoto': true,
    'documents': ['Aadhaar Card', 'Birth Certificate', 'College ID'],
    'vouches': 0, 'vouchesRequired': 2,
    'vouchDetails': [
      {'name': 'Elder Sub-committee', 'role': '1st vouch required', 'status': 'Pending'},
      {'name': 'Elder Sub-committee', 'role': '2nd vouch required', 'status': 'Pending'},
    ],
    'lineageNotes': 'Fresh registration. Father Sudhir Suvarna already in system. Simplest case — just needs elder vouch formality.',
    'riskLevel': 'low', 'status': 'pending', 'occupation': 'B.Tech Final Year, PES University', 'gotra': 'Kashyap',
  },
  {
    'id': 'varun-s', 'name': 'Varun Shirvadkar', 'age': 31, 'gender': 'M', 'photo': px(3131428),
    'location': 'Singapore (NRI)', 'phone': '+65 9••• ••••',
    'claimingFrom': 'Kundapura Branch (NRI)',
    'claimingAncestor': 'Suresh Shirvadkar (Kundapura, registered member m4)',
    'relation': 'Son of Suresh Shirvadkar — currently based in Singapore',
    'submittedOn': '05 May 2026', 'aadhaarStatus': 'Mismatch', 'hasDocument': true, 'hasPhoto': true,
    'documents': ['Aadhaar Card (old address)', 'Singapore PR Card', "Suresh Shirvadkar's letter of confirmation"],
    'vouches': 2, 'vouchesRequired': 3,
    'vouchDetails': [
      {'name': 'Gopalakrishna Suvarna', 'role': 'Elder, Kundapura Branch', 'status': 'Approved'},
      {'name': 'Suresh Shirvadkar', 'role': 'Parent (self-declared)', 'status': 'Approved'},
      {'name': 'Elder Sub-committee', 'role': 'NRI verification required', 'status': 'Pending'},
    ],
    'lineageNotes': 'Aadhaar address mismatch — old Karnataka address vs Singapore residency. NRI members need special committee clearance as per 2023 policy update.',
    'riskLevel': 'medium', 'status': 'pending', 'occupation': 'Senior Software Engineer, Grab (Singapore)', 'gotra': 'Vasishtha',
  },
  {
    'id': 'nalini-b', 'name': 'Nalini Malnikar', 'age': 37, 'gender': 'F', 'photo': px(34515496),
    'location': 'Udupi, Karnataka', 'phone': '94496 ••••••',
    'claimingFrom': 'Udupi Branch',
    'claimingAncestor': 'Late Ananth Rao Malnikar (Udupi, 1892–1954) — disputed record',
    'relation': 'Great-granddaughter via oral lineage (disputed)',
    'submittedOn': '01 May 2026', 'aadhaarStatus': 'Verified', 'hasDocument': true, 'hasPhoto': false,
    'documents': ['Aadhaar Card', 'Handwritten family record (1940s)', 'Temple prasad receipt with family name'],
    'vouches': 0, 'vouchesRequired': 3,
    'vouchDetails': [
      {'name': 'Elder Sub-committee', 'role': '1st vouch required', 'status': 'Pending'},
      {'name': 'Elder Sub-committee', 'role': '2nd vouch required', 'status': 'Pending'},
      {'name': 'Elder Sub-committee', 'role': '3rd vouch required', 'status': 'Pending'},
    ],
    'lineageNotes': '⚠ High caution — Ananth Rao Malnikar (1892–1954) has a flagged duplicate conflict between Mysore and Bangalore branches. This claim should be frozen until the duplicate is resolved. Refer to Tree Alert #AK412.',
    'riskLevel': 'high', 'status': 'pending', 'occupation': 'Medical Lab Technician, Manipal Hospital, Udupi', 'gotra': 'Kashyap',
  },
  {
    'id': 'kamala-d', 'name': 'Kamala Diwakar', 'age': 67, 'gender': 'F', 'photo': px(11138457),
    'location': 'Udupi, Karnataka', 'phone': '98443 ••••••',
    'claimingFrom': 'Udupi Branch (Late Registration)',
    'claimingAncestor': 'Subramanya Shirodkar (registered member m22)',
    'relation': 'Sister-in-law of Subramanya Shirodkar — late registration (previously unregistered)',
    'submittedOn': '28 Apr 2026', 'aadhaarStatus': 'Verified', 'hasDocument': true, 'hasPhoto': true,
    'documents': ['Aadhaar Card', 'Ration Card (1985, family name matches)', 'Letter from Subramanya Shirodkar'],
    'vouches': 3, 'vouchesRequired': 3,
    'vouchDetails': [
      {'name': 'Subramanya Shirodkar', 'role': 'Member, Udupi Branch', 'status': 'Approved'},
      {'name': 'Shri Narayanarao Suvarna', 'role': 'Elder, Committee Head', 'status': 'Approved'},
      {'name': 'Parvati Shirodkar', 'role': 'Member, Udupi Branch', 'status': 'Approved'},
    ],
    'lineageNotes': 'All vouches cleared. This is a routine late-registration case. Elder committee has verbally approved — formal sign-off pending in system.',
    'riskLevel': 'low', 'status': 'pending', 'occupation': 'Retired, Temple Committee Volunteer', 'gotra': 'Kashyap',
  },
  {
    'id': 'rakshit-s', 'name': 'Rakshit Suvarna', 'age': 21, 'gender': 'M', 'photo': px(1856477),
    'location': 'Bengaluru, Karnataka', 'phone': '91008 ••••••',
    'claimingFrom': 'Bengaluru Branch',
    'claimingAncestor': 'Ganesh Suvarna (father, registered member m3)',
    'relation': 'Son of Ganesh Suvarna — student first-time registration',
    'submittedOn': '02 May 2026', 'aadhaarStatus': 'Verified', 'hasDocument': true, 'hasPhoto': true,
    'documents': ['Aadhaar Card', 'College Enrollment Certificate (MSRIT)', 'Parent consent form'],
    'vouches': 1, 'vouchesRequired': 2,
    'vouchDetails': [
      {'name': 'Ganesh Suvarna', 'role': 'Parent (registered member)', 'status': 'Approved'},
      {'name': 'Elder Sub-committee', 'role': '2nd vouch required', 'status': 'Pending'},
    ],
    'lineageNotes': 'Minor note: applicant is 21. Routine student registration. Father already a verified member. Quick formality.',
    'riskLevel': 'low', 'status': 'pending', 'occupation': 'B.E. Student, MSRIT, Bengaluru', 'gotra': 'Kashyap',
  },
  {
    'id': 'swathi-b', 'name': 'Swathi Bidnolikar', 'age': 29, 'gender': 'F', 'photo': px(29201034),
    'location': 'Bengaluru, Karnataka', 'phone': '87654 ••••••',
    'claimingFrom': 'Bengaluru Branch (Name Change)',
    'claimingAncestor': 'Rajesh Bidnolikar (father, registered member m18)',
    'relation': 'Daughter of Rajesh Bidnolikar — name change update after marriage into Gaunkar family',
    'submittedOn': '06 May 2026', 'aadhaarStatus': 'Verified', 'hasDocument': true, 'hasPhoto': true,
    'documents': ['Marriage Certificate', 'New Aadhaar (post name change)', 'Gazette notification'],
    'vouches': 2, 'vouchesRequired': 2,
    'vouchDetails': [
      {'name': 'Rajesh Bidnolikar', 'role': 'Parent (registered member)', 'status': 'Approved'},
      {'name': 'Usha Gaunkar', 'role': 'Family member (registered)', 'status': 'Approved'},
    ],
    'lineageNotes': "Name change — updating registry entry from 'Swathi Bidnolikar' to 'Swathi Gaunkar (née Bidnolikar)'. All documents clear.",
    'riskLevel': 'low', 'status': 'pending', 'occupation': 'HR Executive, Bengaluru', 'gotra': 'Atreya',
  },
  {
    'id': 'sudarshan-l', 'name': 'Sudarshan Lotlikar', 'age': 55, 'gender': 'M', 'photo': px(2601464),
    'location': 'Pune, Maharashtra', 'phone': '98220 ••••••',
    'claimingFrom': 'Out-of-State Branch',
    'claimingAncestor': 'Late Vishwanath Lotlikar (Kumta, 1948–2010)',
    'relation': 'Son of Late Vishwanath Lotlikar — relocated to Pune in 1995',
    'submittedOn': '25 Apr 2026', 'aadhaarStatus': 'Verified', 'hasDocument': true, 'hasPhoto': false,
    'documents': ['Aadhaar Card (Pune address)', "Father's Kumta property record", 'Samaj membership from Pune Daivadnya chapter'],
    'vouches': 2, 'vouchesRequired': 3,
    'vouchDetails': [
      {'name': 'Vasudeva Vernekar', 'role': 'Elder, Kumta Branch', 'status': 'Approved'},
      {'name': 'Deepak Vernekar', 'role': 'Member, Kumta Branch', 'status': 'Approved'},
      {'name': 'Elder Sub-committee', 'role': '3rd vouch from HQ required', 'status': 'Pending'},
    ],
    'lineageNotes': 'Out-of-state case. Pune Daivadnya chapter has given informal clearance. Kumta branch vouches match lineage records. One HQ elder vouch pending.',
    'riskLevel': 'low', 'status': 'pending', 'occupation': 'Mechanical Engineer, Thermax, Pune', 'gotra': 'Atreya',
  },
];

// Invitation Route Planner families — Bengaluru Daivajna Samaja.
final List<Map<String, dynamic>> kInvitationFamilies = [
  {'id': 'if1', 'name': 'Venkatesh Haldankar', 'relation': 'Grandfather · Bharadwaja Gotra', 'address': '12, Saraswathipuram, Basavanagudi, Bengaluru — 560004', 'area': 'Basavanagudi', 'lat': 12.9419, 'lng': 77.5732, 'photo': px(2601464), 'phone': '+91 98765 43210', 'note': 'Prefers morning visits before 11 AM. Please bring prasad from the Samaj temple.', 'estimatedVisit': '45 min'},
  {'id': 'if2', 'name': 'Rekha Diwakar', 'relation': 'Aunt · Bharadwaja Gotra', 'address': '34, 4th Cross, Jayanagar 3rd Block, Bengaluru — 560011', 'area': 'Jayanagar', 'lat': 12.9279, 'lng': 77.5803, 'photo': px(34515496), 'phone': '+91 97712 34567', 'note': 'She is usually home all day. Loves traditional Samaj sweets — bring chirote.', 'estimatedVisit': '30 min'},
  {'id': 'if3', 'name': 'Narayana Revankar', 'relation': 'Elder · Retired IAS Officer', 'address': '8, Margosa Road, Malleswaram, Bengaluru — 560003', 'area': 'Malleswaram', 'lat': 13.0037, 'lng': 77.5662, 'photo': px(4053536), 'phone': '+91 99001 56789', 'note': "Senior member. Keep visit under 1 hour. He's part of the invitation committee.", 'estimatedVisit': '60 min'},
  {'id': 'if4', 'name': 'Suresh Haldankar', 'relation': 'Father · Kashyap Gotra', 'address': '22, 80 Feet Road, Indiranagar 1st Stage, Bengaluru — 560038', 'area': 'Indiranagar', 'lat': 12.9784, 'lng': 77.6408, 'photo': px(5746790), 'phone': '+91 98443 12345', 'note': 'Weekday evenings or weekends best. Confirm one day before visiting.', 'estimatedVisit': '40 min'},
  {'id': 'if5', 'name': 'Kavitha Pednekar', 'relation': 'Community Member · Vasishtha Gotra', 'address': '16, 7th Cross, Banashankari 2nd Stage, Bengaluru — 560070', 'area': 'Banashankari', 'lat': 12.9243, 'lng': 77.5455, 'photo': px(30004176), 'phone': '+91 94496 67890', 'note': 'Schoolteacher — best reached on weekends. Family of 5 will attend the function.', 'estimatedVisit': '35 min'},
  {'id': 'if6', 'name': 'Rajesh Bidnolikar', 'relation': 'Community Member · Atreya Gotra', 'address': '45, Jyoti Nivas College Road, Koramangala 5th Block, Bengaluru — 560095', 'area': 'Koramangala', 'lat': 12.9352, 'lng': 77.6245, 'photo': px(1856477), 'phone': '+91 90081 34567', 'note': 'Entrepreneur — flexible timings. Family of 4. Has offered car-pooling for elders.', 'estimatedVisit': '25 min'},
  {'id': 'if7', 'name': 'Priya Haldankar', 'relation': 'Self · Kashyap Gotra', 'address': '18, 6th Main, RT Nagar, Bengaluru — 560032', 'area': 'RT Nagar', 'lat': 13.0228, 'lng': 77.5978, 'photo': px(7485047), 'phone': '+91 98765 43210', 'note': 'Starting point. Collect invitations from here before the route.', 'estimatedVisit': '—'},
  {'id': 'if8', 'name': 'Shri Narayanarao Suvarna', 'relation': 'Elder & Admin · Bharadwaja Gotra', 'address': '3, Kumta House Colony, Rajajinagar, Bengaluru — 560010', 'area': 'Rajajinagar', 'lat': 12.9906, 'lng': 77.5512, 'photo': px(17815020), 'phone': '+91 99999 99999', 'note': 'Head of Elder Sub-committee. Must be first on the route — most senior member.', 'estimatedVisit': '60 min'},
];

// Lineage Conflict Cases — for elder conflict resolution portal.
final List<Map<String, dynamic>> kConflictCases = [
  {
    'id': 'ck-1', 'type': 'Duplicate', 'subject': 'Ananth Rao Vernekar', 'born': '1892', 'died': '1954',
    'photo': px(4053536), 'conflictTitle': 'POTENTIAL DUPLICATE DETECTED',
    'conflictDesc': "Profile 'Ananth Rao Vernekar (1892–1954)' appears in both the Mysore and Bangalore branches with conflicting parentage and profession records.",
    'versionA': {
      'label': 'Version A — Mysore Branch', 'backed': true,
      'fields': [
        {'label': 'Father', 'value': 'Ramachandra Rao Vernekar'},
        {'label': 'Profession', 'value': 'Goldsmith & Temple Trustee'},
        {'label': 'Native', 'value': 'Mysore, Karnataka'},
        {'label': 'Source', 'value': 'Official temple records, 1924'},
      ],
      'evidence': ['Temple Trust Document (1924)', 'Family Photo – 1940s'],
      'submittedBy': 'Smt. Vijaya Vernekar (Granddaughter, Mysore Branch)',
      'submittedPhoto': px(11138457), 'votes': 7,
    },
    'versionB': {
      'label': 'Version B — Bangalore Branch', 'backed': false,
      'fields': [
        {'label': 'Father', 'value': 'Govind Rao Vernekar'},
        {'label': 'Profession', 'value': 'Jeweller & Trader'},
        {'label': 'Native', 'value': 'Bengaluru, Karnataka'},
        {'label': 'Source', 'value': 'Oral history — family reunion, 1978'},
      ],
      'evidence': ['Oral History Recording (1978)', 'Ration Card copy'],
      'submittedBy': 'Shri Ramesh Vernekar (Nephew, Bengaluru Branch)',
      'submittedPhoto': px(2601464), 'votes': 3,
    },
    'discussion': [
      {'author': 'Shri Narayanarao Suvarna', 'role': 'Elder', 'text': "I've reviewed both submissions. The temple trust document from 1924 is the stronger evidence — it has Ramachandra Rao as father with witness signatures.", 'time': '2 days ago', 'photo': px(17815020)},
      {'author': 'Smt. Vijaya Vernekar', 'role': 'Member', 'text': 'The Mysore branch has the original family trunk documents. I can bring them to the next Samaj meeting for physical review.', 'time': '1 day ago', 'photo': px(11138457)},
    ],
  },
  {
    'id': 'ck-2', 'type': 'Parentage', 'subject': 'Savitri Bai Suvarna', 'born': '1910', 'died': '1994',
    'photo': px(11138457), 'conflictTitle': 'PARENTAGE CONFLICT',
    'conflictDesc': "Three descendants have provided conflicting accounts of Savitri Bai's biological mother, with differing birth years from oral histories.",
    'versionA': {
      'label': 'Version A — Official Records', 'backed': true,
      'fields': [
        {'label': 'Mother', 'value': 'Amala Devi Suvarna'},
        {'label': 'Birth Year', 'value': '1910 (Official Certificate)'},
        {'label': 'Native', 'value': 'Kundapura, Udupi'},
        {'label': 'Source', 'value': 'Birth certificate & Land deed'},
      ],
      'evidence': ['Birth Certificate (1910)', 'Land Deed – family name listed'],
      'submittedBy': 'Arjun V. Shirodkar (Grandson)',
      'submittedPhoto': px(7345266), 'votes': 5,
    },
    'versionB': {
      'label': 'Version B — Oral History', 'backed': false,
      'fields': [
        {'label': 'Mother', 'value': 'Gauri Amma Suvarna'},
        {'label': 'Birth Year', 'value': '1908 (Oral history)'},
        {'label': 'Native', 'value': 'Kumta, Uttara Kannada'},
        {'label': 'Source', 'value': 'Voice recording – family oral testimony, 1985'},
      ],
      'evidence': ['Voice Recording (1985): "Great-aunt Meena recalls Savitri was born before the Great Flood of 1910..."'],
      'submittedBy': 'Ramesh K. Pednekar (Nephew)',
      'submittedPhoto': px(5746790), 'votes': 2,
    },
    'discussion': [
      {'author': 'Vasudeva Vernekar', 'role': 'Elder, Kumta Branch', 'text': 'The 1985 oral recording is important cultural evidence but birth certificates take precedence in lineage records per our 2019 governance guidelines.', 'time': '3 days ago', 'photo': px(2601464)},
      {'author': 'Arjun Shirodkar', 'role': 'Member', 'text': 'I have the original birth certificate in the family trunk. Amala Devi is clearly listed as mother. I can courier a notarised copy.', 'time': '1 day ago', 'photo': px(7345266)},
    ],
  },
];

/// Landing page headline statistics.
const List<Map<String, dynamic>> kLandingStats = [
  {'value': 1428, 'label': 'Registered Members', 'suffix': '+'},
  {'value': 86, 'label': 'Family Trees', 'suffix': ''},
  {'value': 4250000, 'label': 'Welfare Raised', 'prefix': '₹', 'suffix': '', 'lakh': true},
  {'value': 64, 'label': 'Match Success Rate', 'suffix': '%'},
];
