import moment from "moment";

export function openSidebar() {
  if (typeof window !== 'undefined') {
    document.body.style.overflow = 'hidden';
    document.documentElement.style.setProperty('--SideNavigation-slideIn', '1');
  }
}

export function closeSidebar() {
  if (typeof window !== 'undefined') {
    document.documentElement.style.removeProperty('--SideNavigation-slideIn');
    document.body.style.removeProperty('overflow');
  }
}

export function toggleSidebar() {
  if (typeof window !== 'undefined' && typeof document !== 'undefined') {
    const slideIn = window
      .getComputedStyle(document.documentElement)
      .getPropertyValue('--SideNavigation-slideIn');
    if (slideIn) {
      closeSidebar();
    } else {
      openSidebar();
    }
  }
}

export function openMessagesPane() {
  if (typeof window !== 'undefined') {
    document.body.style.overflow = 'hidden';
    document.documentElement.style.setProperty('--MessagesPane-slideIn', '1');
  }
}

export function closeMessagesPane() {
  if (typeof window !== 'undefined') {
    document.documentElement.style.removeProperty('--MessagesPane-slideIn');
    document.body.style.removeProperty('overflow');
  }
}

export function toggleMessagesPane() {
  if (typeof window !== 'undefined' && typeof document !== 'undefined') {
    const slideIn = window
      .getComputedStyle(document.documentElement)
      .getPropertyValue('--MessagesPane-slideIn');
    if (slideIn) {
      closeMessagesPane();
    } else {
      openMessagesPane();
    }
  }
}

export function formatUtcTime(utcTimeString: string | null): string {

  if (utcTimeString && utcTimeString.trim() !== '') {
      try {

          const utcTime = moment(utcTimeString);


          const localTime = utcTime.local();


          const formattedTime = localTime.format("MM-DD-YYYY HH:mm A");

          return formattedTime;
      } catch (e) {

          return 'Invalid date format';
      }
  }
  return '';
}

export function formatDate(utcTimeString: string | null): string {
  if (utcTimeString && utcTimeString.trim() !== '') {
      try {
          // Parse the input string into a moment object
          const date = moment(utcTimeString);

          // Step 1: Check if the date is today
          if (date.isSame(moment(), 'day')) {
              // If today, show the time (12-hour format with AM/PM)
              return date.format('hh:mm A'); // e.g., '07:17 AM'
          }

          // Step 2: Check if the date was yesterday
          if (date.isSame(moment().subtract(1, 'days'), 'day')) {
              return 'Yesterday'; // Return 'Yesterday' for yesterday's date
          }

          // Step 3: For other dates, format them normally (e.g., YYYY-MM-DD)
          return date.format('MM-DD-YYYY'); // e.g., '2024-11-13'

      } catch (e) {
          // Handle error if the date format is invalid
          return 'Invalid date format';
      }
  }
  return ''; // Return empty string if input is null or empty
}
