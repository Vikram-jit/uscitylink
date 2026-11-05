import * as React from 'react';
import type { Metadata } from 'next';
import Box from '@mui/material/Box';
import Container from '@mui/material/Container';
import Divider from '@mui/material/Divider';
import Link from '@mui/material/Link';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';

// Public page (no login) linked from Google Play / App Store as the app's Terms of Service.
// TODO before publishing: fill in the company's real contact details and governing-law state.
const COMPANY = 'US City Link Corporation';
const APP = 'USCityLink';
const CONTACT_EMAIL = 'dispatch@uscitylinkcorp.com';
const CONTACT_ADDRESS = '';
const GOVERNING_STATE = 'the State of California';
const LAST_UPDATED = 'November 5, 2026';

export const metadata = { title: `Terms of Service | ${APP}` } satisfies Metadata;

interface Section {
  title: string;
  body: React.ReactNode[];
}

const sections: Section[] = [
  {
    title: '1. About these terms',
    body: [
      `These Terms of Service ("Terms") govern your use of the ${APP} mobile app and the ${APP} web dashboard (together, the "Service"), provided by ${COMPANY} ("we", "us", "our").`,
      'By signing in to or using the Service, you agree to these Terms. If you do not agree, do not use the Service.',
    ],
  },
  {
    title: '2. Who can use the Service',
    body: [
      `The Service is a business tool for ${COMPANY}'s drivers, owner-operators, dispatchers and other staff. Accounts are created by us; the Service is not offered to the general public.`,
      'You must be at least 18 years old and have been given an account by us. Your access ends when your work relationship with us ends or when we disable your account.',
    ],
  },
  {
    title: '3. Your account',
    body: [
      'You sign in with the phone number or email address we have on file. Keep your login codes and passwords private and do not let anyone else use your account.',
      'Tell us right away if you think someone else has accessed your account. You are responsible for activity on your account.',
    ],
  },
  {
    title: '4. Safe and acceptable use',
    body: [
      'Do not read or type messages, look at documents, or handle the app while driving. Use voice calls only where it is legal and safe, and only hands-free where the law requires it.',
      'You agree not to: use the Service for anything unlawful; send harassing, threatening or offensive content; share another person\'s information without permission; try to access accounts or data that are not yours; or interfere with, copy, reverse-engineer or overload the Service.',
    ],
  },
  {
    title: '5. Messages, calls and recordings',
    body: [
      'The Service lets you send messages, photos, documents and voice notes, and make voice and video calls between drivers and dispatch.',
      'Calls made through the Service may be recorded (audio, and video when a staff member turns on video recording) for safety, training, dispute resolution and record-keeping. When a call is being recorded, the call screen shows a recording indicator. By continuing the call, you consent to the recording.',
      'Messages, call history and recordings are business records of the company. Authorized staff may review them.',
    ],
  },
  {
    title: '6. Location, vehicle and trip information',
    body: [
      'Some features use your device location and vehicle information, for example routes, fuel stations, trip and inspection records. You can control location permission in your device settings; some features will not work without it.',
      'You are responsible for making sure that the inspection reports, documents and other information you submit are accurate and truthful.',
    ],
  },
  {
    title: '7. Content you submit',
    body: [
      'You keep any rights you have in content you submit (such as photos and documents). You give us permission to store, process, display and share that content as needed to operate the Service and for our business and legal purposes.',
      'Only submit content you have the right to share.',
    ],
  },
  {
    title: '8. Notifications',
    body: [
      'The app sends notifications for new messages and incoming calls. Staff can mute message and call alerts in the app settings. Turning off notifications in your device settings may cause you to miss messages or calls.',
    ],
  },
  {
    title: '9. Privacy',
    body: [
      'We collect and use personal information (such as your name, phone number, location, messages, call records and recordings) to run the Service and our business. We protect it with reasonable security measures and do not sell it.',
      <>
        For questions about your information, contact us at <Link href={`mailto:${CONTACT_EMAIL}`}>{CONTACT_EMAIL}</Link>.
      </>,
    ],
  },
  {
    title: '10. Fees',
    body: ['The app is free to download and use. Your mobile carrier\'s data and calling charges may apply.'],
  },
  {
    title: '11. Changes and availability',
    body: [
      'We may update, change or stop features of the Service at any time. We try to keep the Service available but do not promise it will always be available, uninterrupted or error-free. Keep the app updated to the latest version.',
    ],
  },
  {
    title: '12. Suspension and termination',
    body: [
      'We may suspend or close your account at any time, including if you break these Terms or are no longer working with us. Sections 5, 7, 13, 14 and 15 continue to apply after your access ends.',
    ],
  },
  {
    title: '13. Disclaimer',
    body: [
      'The Service is provided "as is" and "as available". To the extent allowed by law, we disclaim all warranties, express or implied, including merchantability, fitness for a particular purpose and non-infringement. Information in the Service (such as routes, fuel prices or locations) may not always be complete or accurate.',
    ],
  },
  {
    title: '14. Limitation of liability',
    body: [
      `To the extent allowed by law, ${COMPANY} is not liable for any indirect, incidental, special, consequential or punitive damages, or for lost data or profits, arising from your use of the Service. Nothing in these Terms limits liability that cannot be limited under applicable law, including any rights you have as a consumer.`,
    ],
  },
  {
    title: '15. Governing law',
    body: [
      `These Terms are governed by the laws of ${GOVERNING_STATE}, United States, without regard to conflict-of-law rules, except where the law of your place of residence requires otherwise.`,
    ],
  },
  {
    title: '16. Changes to these Terms',
    body: [
      'We may update these Terms from time to time. When we do, we will change the "Last updated" date above and, for significant changes, let you know in the app. Continuing to use the Service after a change means you accept the updated Terms.',
    ],
  },
];

export default function TermsPage(): React.JSX.Element {
  return (
    <Box component="main" sx={{ bgcolor: 'background.default', minHeight: '100vh', py: { xs: 4, md: 8 } }}>
      <Container maxWidth="md">
        <Stack spacing={1} sx={{ mb: 4 }}>
          <Typography variant="h3">Terms of Service</Typography>
          <Typography color="text.secondary" variant="body2">
            {APP} app by {COMPANY} · Last updated: {LAST_UPDATED}
          </Typography>
        </Stack>
        <Stack divider={<Divider />} spacing={3}>
          {sections.map((section) => (
            <Stack key={section.title} spacing={1.5}>
              <Typography variant="h6">{section.title}</Typography>
              {section.body.map((paragraph, i) => (
                <Typography key={i} color="text.secondary" variant="body1">
                  {paragraph}
                </Typography>
              ))}
            </Stack>
          ))}
          <Stack spacing={1.5}>
            <Typography variant="h6">17. Contact us</Typography>
            <Typography color="text.secondary" variant="body1">
              {COMPANY}
              {CONTACT_ADDRESS ? (
                <>
                  <br />
                  {CONTACT_ADDRESS}
                </>
              ) : null}
              <br />
              Email: <Link href={`mailto:${CONTACT_EMAIL}`}>{CONTACT_EMAIL}</Link>
            </Typography>
          </Stack>
        </Stack>
      </Container>
    </Box>
  );
}
