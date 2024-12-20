
import sgMail from '@sendgrid/mail';
import dotConfig from'dotenv';
dotConfig.config();


export const generateOTP = (length: number): string => {
    const characters = '0123456789';
    let otp = '';
    for (let i = 0; i < length; i++) {
      otp += characters.charAt(Math.floor(Math.random() * characters.length));
    }
    return otp;
  };

  
sgMail.setApiKey(process.env.SEND_GRID as string);

// Define the function to send an email
const sendEmail = async (
  toEmail: string,
  subject: string,
  text: string,
  html?: string
): Promise<void> => {
 
  const msg = {
    to: toEmail, 
    from: process.env.SEND_EMAIL as string, 
    subject: subject, 
    text: text, 
    html: html, 
  };

  try {
    // Send the email using SendGrid
    const response = await sgMail.send(msg);
    console.log('Email sent successfully!', response);
  } catch (error:any) {
    console.error('Error sending email:', error);
    if (error.response) {
      console.error('SendGrid Error Response: ', error.response.body);
    }
  }
};

// Example usage: Send an email with both text and HTML content



export const sendOTPEmail = async (toEmail: string, otp: string): Promise<any> => {
    const msg = {
      to: toEmail,
      from: process.env.SEND_EMAIL as string,  // Your verified SendGrid sender email
      subject: 'Your OTP Code',
      text: `Hello,\n\nPlease use the following OTP (One-Time Password) to complete your action:\n\nOTP: ${otp}\n\nThe OTP is valid for 10 minutes. Please use it soon. If you did not request this OTP, please ignore this email.\n\nThank you for using our service!`,
      html: `
        <html>
          <body>
            <h2>Your OTP Code</h2>
            <p>Hello,</p>
            <p>Please use the following OTP (One-Time Password) to complete your action:</p>
            <p style="font-size: 36px; font-weight: bold; color: #333; text-align: center;">${otp}</p>
            <p>The OTP is valid for 10 minutes. Please use it soon. If you did not request this OTP, please ignore this email.</p>
            <p>Thank you for using our service!</p>
            <p>If you have any questions, feel free to contact our support team.</p>
          </body>
        </html>
      `,
    };
  
    
     const res =  await sgMail.send(msg);
     return res
   
  };
  

  export const sendNewPasswordEmail = async (toEmail: string, newPassword: string): Promise<any> => {
    const msg = {
      to: toEmail,
      from: process.env.SEND_EMAIL as string,  // Your verified SendGrid sender email
      subject: 'Your New Password for ChatBox USCityLink',
      text: `Hello,\n\nWe have successfully generated a new password for your account with  ChatBox USCityLink. Your new password is: ${newPassword}\n\nFor security reasons, we recommend changing your password as soon as you log in.\n\nIf you did not request this password change, please contact our support team immediately.\n\nThank you for using our service!`,
      html: `
        <html>
          <body>
            <h2>Your New Password</h2>
            <p>Hello,</p>
            <p>We have successfully generated a new password for your account with <strong> ChatBox USCityLink</strong>. You can use the following credentials to log in:</p>
            <p style="font-size: 18px; font-weight: bold;">New Password: <span style="font-size: 20px; color: #d32f2f;">${newPassword}</span></p>
            <p>For security reasons, we recommend changing this password as soon as you log in. You can do so by going to your account settings.</p>
            <p>If you did not request a password change, please contact our support team immediately at <a href="mailto:support@example.com">support@example.com</a>.</p>
            <p>Thank you for using our service!</p>
            <p>Best regards, <br> ChatBox USCityLink Team</p>
          </body>
        </html>
      `,
    };
  
    // Sending email using SendGrid
    const res = await sgMail.send(msg);
    console.log(res,toEmail)
    return res;
  };