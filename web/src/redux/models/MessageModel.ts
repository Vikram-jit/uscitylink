export interface MessageModel {
  id:                  string;
  channelId:           string;
  userProfileId:       string;
  groupId:             null;
  body:                string;
  messageDirection:    string;
  deliveryStatus:      string;
  messageTimestampUtc: Date;
  senderId:            string;
  isRead:              boolean;
  status:              string;
  createdAt:           Date;
  updatedAt:           Date;
}
