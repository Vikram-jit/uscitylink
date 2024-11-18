// Sender model interface
export interface SenderModel {
  id: string;
  username: string;
  isOnline:boolean
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

  sender: SenderModel;
}
