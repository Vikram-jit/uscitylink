import { MessageModel } from "./MessageModel";
import { User } from "./UserModel";

export interface ChannelModel {
  id:          string;
  name:        string;
  description: string;
  createdAt:   Date;
  updatedAt:   Date;
  isActive?:boolean

}

export interface SingleChannelModel {
  id:            string;
  name:          string;
  description:   string;
  createdAt:     Date;
  updatedAt:     Date;
  user_channels: UserChannel[];
  pagination:pagination
}

export interface UserChannel {
  id:            string;
  userProfileId: string;
  channelId:     string;
  createdAt:     Date;
  updatedAt:     Date;
  ChannelId:     string;
  UserProfile:   UserProfile;
  last_message: MessageModel
  recieve_message_count:number
  sent_message_count:number
  status:string
}

export interface UserProfile {
  id:              string;
  userId:          string;
  username:        string;
  profile_pic:     null;
  status:          string;
  role_id:         string;
  last_message_id: null;
  isOnline:        boolean;
  device_id:       null;
  device_token:    null;
  platform:        null;
  last_login:      null;
  channelId:       string;
  createdAt:       Date;
  updatedAt:       Date;
  user: User
}

export interface   pagination{
  currentPage: number,
  pageSize: number,
  total:number,
  totalPages:number,
}
