import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const String _termsText = '''EV RADAR — TERMS OF SERVICE & PRIVACY POLICY

Effective Date: 4th September 2026
Last Updated: 2nd August 2026

1. Introduction and Acceptance

EV Radar is a smart electric-vehicle tracking and charging application designed to help EV drivers, station operators, installation technicians, and administrators manage charging stations, plan routes, book charging slots, and coordinate EV wallbox installations in Kenya.

By downloading, installing, registering for, or otherwise using EV Radar, you agree to be bound by these Terms of Service and Privacy Policy. If you do not agree to these Terms, you must immediately discontinue use of the App.

These Terms apply to all users of the App, regardless of role: EV drivers (fleet members), charging station operators, certified technicians, and platform administrators.

2. Eligibility

You must be at least 18 years of age to create an account and use EV Radar. By registering, you represent and warrant that you meet this age requirement and that all information you provide during registration is accurate, current, and complete. You are responsible for maintaining the confidentiality of your account credentials and for all activity that occurs under your account.

3. User Accounts and Roles

EV Radar supports multiple role-based accounts:
• EV Driver / Fleet Member — may search charging stations, plan routes, book charging slots, and book installation services.
• Station Operator — may register and manage charging stations, update availability status, and view bookings for their stations.
• Certified Technician — may receive installation assignments, update job status, and manage assigned installations.
• Administrator — manages platform users, approves station and technician applications, and moderates content.

You may not misrepresent your role. Registering as an operator or technician is subject to approval by EV Radar administrators. Applications that are rejected, suspended, or found to contain false information will result in account restriction or termination.

4. Location Data and Permissions

EV Radar requires access to your device’s GPS location to deliver its core functionality, including:
• Displaying charging stations near your current position
• Calculating distance and route from your location to stations and destinations
• Tracking trip progress during active navigation
• Recording energy consumption (battery drain per distance) while tracking is enabled
• Auto-filling installation site coordinates for booking requests

Location data is processed on your device and, when you are signed in, stored in association with your account in our secure database. We do not sell, share, or rent your precise location to third parties except to the extent necessary to serve mapping and routing (e.g., Google Maps). You may revoke location permissions at any time via your device settings, though this will disable map, navigation, and distance-based features.

5. Charging Station Data

Charging station details (name, location, connector type, power output, tariff, availability status, amenities) are provided by station operators and administrators and are refreshed periodically. While we strive for accuracy, EV Radar does not guarantee that a station will be operational, available, or priced as displayed at the moment you arrive. You acknowledge that:
• Availability status (“Operational”, “Busy”) is maintained by the operator and may lag behind real-world conditions.
• Tariffs (KSh/kWh) are set by the operator and may change without notice.
• The App is not a substitute for confirming charger availability with the operator directly.

EV Radar is not liable for any costs, delays, or damages arising from inaccurate station information.

6. Slot Booking Terms

For users booking charging slots:
• Bookings are reserved for a specific time window on a specific station.
• Booking is free of charge unless stated otherwise on the station or in-app.
• You are expected to arrive within your reserved window. Missed bookings may be marked “Expired” automatically.
• You may cancel your booking at any time before the slot begins using the Cancel action in My Bookings → Charging.
• Cancelling a booking may notify the station operator.
• Operators reserve the right to override a booking if the station becomes unavailable due to equipment failure.

Abuse of the booking system (e.g., mass reservation of slots without intent to use) may result in restricted booking privileges.

7. Installation Services Terms

For users booking wallbox installations:
• Booking Fee (KSh 2,500 refundable) is charged to reserve a technician for a site survey. This fee is credited towards your final installation invoice upon completion, or refunded if the survey is cancelled.
• The final Installation Package Fee (starting from KSh 74,900 depending on hardware and site conditions) covers the equipment, certified EPRA technician labor, permits, and workmanship as detailed in the App.
• Installation timelines, panel upgrade requirements, and county permits are subject to site assessment.
• Cancellations made after a technician has been assigned and dispatched may forfeit the booking fee to cover the technician’s time.
• You agree to provide accurate site coordinates and address information so the technician can locate the property.

Technician Warranties. EV Radar-certified technicians provide a 1-year workmanship warranty on completed installations. Equipment warranties are governed by the device manufacturer.

8. Ratings and Reviews

Users may rate their assigned technician after an installation is marked “Completed.” Ratings are aggregated to compute each technician’s average score, visible to users when selecting a technician. You agree that:
• Ratings must reflect your genuine experience.
• You may not manipulate ratings, create fake accounts to inflate scores, or coerce other users into leaving reviews.
• EV Radar may remove ratings that violate these terms.

9. Payments and Fees

EV Radar itself does not process payments. Any fees displayed in the App are paid directly to the operator or installation service through the channels specified in-app. We are not responsible for disputes between users and operators or technicians.

10. Acceptable Use

You agree not to:
• Use the App for any unlawful purpose or in violation of Kenyan law.
• Attempt to access, scrape, reverse-engineer, or interfere with our servers, databases, or APIs.
• Upload or transmit viruses, malware, or any code that disrupts the App.
• Impersonate another user, operator, technician, or administrator.
• Post or share content that is defamatory, obscene, hateful, or infringing.
• Bypass suspension, ban, or access control mechanisms.
• Use automated bots, scrapers, or crawlers against the App without written permission.

Violations may result in immediate suspension or termination of your account, at our sole discretion.

11. Privacy — Information We Collect

When you use EV Radar, we collect:

a) Account Information
• Name, email address, phone number
• Password (securely hashed via Firebase Auth)
• Role (fleet member, operator, technician, admin)
• Profile picture (if provided)

b) Usage Data
• Charging and installation bookings
• Trip history, route plans, active trips
• Battery level, vehicle selection, energy tracking data
• Ratings you submit

c) Location Data
• GPS coordinates at the moment of map display, navigation, or booking
• Live trip progress while navigation is active
• Installation site coordinates you explicitly submit

d) Station Data (Operators)
• Station details, status changes, images, tariffs

e) Device Data
• Push notification token (Firebase Messaging)
• Device platform (Android / iOS)

12. How We Use Your Data

We use your data to:
• Authenticate you and route you to the correct dashboard per role
• Display nearby stations and calculate distances
• Facilitate bookings, cancellations, and installation coordination
• Send push notifications (booking confirmations, status changes, cancellations)
• Compute technician average ratings
• Enforce terms, detect fraud, and respond to support requests

We do not sell your personal data to third parties.

13. Data Sharing

We share your data only with:
• Firebase (Google Cloud) — for authentication, database, and notifications
• Google Maps Platform — for map rendering and route calculation
• OSRM (Open Source Routing Machine) — for turn-by-turn routing
• Station operators — the minimum necessary to fulfill your booking (email, time slot, station)
• Assigned technicians — your name, contact email, and address for scheduled installations

We may disclose data if required by law, court order, or to protect the rights and safety of EV Radar or others.

14. Data Retention

• Account data is retained for as long as your account is active.
• Completed booking and installation records are retained for up to 5 years for legal and warranty purposes.
• Deleting your account removes your profile and personal identifiers, but anonymized booking history may be retained for aggregate statistics.
• You may request deletion of your data by contacting support.

15. Security

We implement industry-standard security measures:
• Firebase Authentication with secure password hashing
• Firestore role-based security rules
• HTTPS-only network traffic
• No plaintext password storage
• Account suspension and admin review workflows

However, no system is 100% secure. You acknowledge that transmission of data over the internet carries inherent risks and that EV Radar cannot guarantee absolute security.

16. Account Suspension and Termination

We may suspend or terminate your account if you:
• Violate these Terms
• Submit false information in applications
• Engage in fraudulent activity
• Abuse the booking or rating system
• Are reported by operators or technicians for abusive behavior

Suspended accounts will see a Suspended screen upon login and lose access to core features. You may appeal via the in-app support form or by contacting our team.

You may delete your account at any time from Profile → Settings.

17. Intellectual Property

All content in EV Radar — including code, design, logos, illustrations, and copy — is owned by EV Radar or its licensors and is protected by copyright. You may not copy, distribute, or create derivative works without written permission.

Station data uploaded by operators remains the property of the operator, licensed to EV Radar for display purposes.

18. Third-Party Services

EV Radar depends on third-party services, including Firebase, Google Maps, and OSRM. Their own terms and privacy policies govern those portions of your experience. We are not responsible for their availability, accuracy, or data handling practices.

19. Disclaimer of Warranties

EV Radar is provided “as is” and “as available” without warranties of any kind, express or implied, including merchantability, fitness for a particular purpose, or non-infringement. We do not guarantee that the App will be uninterrupted, error-free, or that station information will always be accurate.

20. Limitation of Liability

To the maximum extent permitted by Kenyan law, EV Radar shall not be liable for any indirect, incidental, special, or consequential damages arising from:
• Use or inability to use the App
• Inaccurate station information
• Failed bookings or installations
• Loss of data or device damage
• Third-party service outages

Our total liability for any claim shall not exceed KSh 10,000 or the amount you paid to EV Radar in the past 12 months, whichever is higher.

21. Indemnification

You agree to indemnify and hold EV Radar, its team, and its licensors harmless from any claims, damages, or expenses (including legal fees) arising from your violation of these Terms or misuse of the App.

22. Changes to These Terms

We may update these Terms from time to time. When we do, we will update the “Last Updated” date at the top and, for material changes, notify you in-app. Continued use of the App after an update constitutes acceptance of the revised Terms.

23. Governing Law

These Terms are governed by the laws of the Republic of Kenya. Any dispute arising shall be resolved in the courts of Nairobi, Kenya.

24. Contact Us

For questions, concerns, or data deletion requests:

EV Radar Support
Email: i.am.nelvine@gmail.com
WhatsApp: +254725421941
Location: Nairobi, Kenya

By using EV Radar, you acknowledge that you have read, understood, and agree to these Terms of Service and Privacy Policy.''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        elevation: 0,
        title: const Text(
          'Terms & Privacy',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: SelectableText(
          _termsText,
          style: const TextStyle(
            color: Color(0xFFB8C7DA),
            fontSize: 13,
            height: 1.55,
          ),
        ),
      ),
    );
  }
}