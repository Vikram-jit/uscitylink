
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
  