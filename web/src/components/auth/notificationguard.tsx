'use client'; // Ensures this is only run on the client

import { useState, useEffect } from 'react';
import { message } from '../../../firebase';
import { getToken } from 'firebase/messaging';
import { useUpdateDeviceTokenMutation } from '@/redux/UserApiSlice';


const NotificationGuard = ({ children }: { children: React.ReactNode }) => {
  const [updateDeviceToken,{isLoading}] = useUpdateDeviceTokenMutation();
  const [permissionGranted, setPermissionGranted] = useState(false);
  const checkUserAndRequestPermission = async () => {
    try {
      const permission = await Notification.requestPermission();
      if (permission === 'granted') {
        setPermissionGranted(true);
        // If permission is granted, get the FCM token
        const messages = await message()
        if(messages){
          const token = await getToken(messages,{
            vapidKey: 'BDZMkcVLdoIBDTOoupaI0DZ_HEBwpyJG94l12sYN8iPuKeKHsAlB_nfvHyq_EgrhgAv69f3efuhccroyxQD1lxs',
          });
          await updateDeviceToken({device_token:token,platform:"web"})

        }



      }
    } catch (err) {

      console.error(err);
    } finally {

    }
  };
  useEffect(() => {


    checkUserAndRequestPermission();
  }, []);

  if (isLoading) {
    return <div>Loading...</div>;
  }


  // If permission is granted, render the children components
  return <div>
 
  {!permissionGranted && (
    <button onClick={checkUserAndRequestPermission}>Enable Notifications</button>
  )}
  {children}
</div>
};

export default NotificationGuard;
