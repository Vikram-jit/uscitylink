'use client';

import { useEffect, useState } from 'react';
import { toast } from 'react-toastify';



interface Response {
  status: number;
  data: {
    status: boolean;
    message?: string;
  };
}

function useErrorHandler(): [string, (response: Response) => void] {
  const [message, setMessage] = useState<string>('');

  // Method to process the response and extract the message
  const processResponse = (response: Response) => {
    if (response?.data?.message) {
      return response.data.message;
    }
    return '';
  };

  // Method to set the API response and show the error toast
  const setApiResponse = (response: Response) => {
    const msg = processResponse(response);
    setMessage(msg);

    if (msg) {
      toast.error(msg); // Show the error toast if there's a message
    }
  };

  return [message, setApiResponse];
}

export default useErrorHandler;

