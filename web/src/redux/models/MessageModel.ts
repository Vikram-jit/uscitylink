import { User } from "./UserModel";

// Sender model interface
export interface SenderModel {
  id: string;
  username: string;
  isOnline:boolean
  user?:User
}

// Message model interface
export interface MessageModel {
  id: string;
  channelId: string;
  userProfileId: string;
  groupId: string | null;
  body: string;
  messageDirection: 'S' | 'R';
  deliveryStatus: string;
  messageTimestampUtc: string;
  senderId: string;
  isRead: boolean;
  status: string;
  createdAt: Date;
  updatedAt: Date;
  url:string | null
  thumbnail:string | null
  staffPin:string | null
  sender: SenderModel;
  r_message:MessageModel
  url_upload_type:string,
  private_chat_id:string|null,driverPin:string|null
}
