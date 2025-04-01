import { pagination } from './ChannelModel';
import { MessageModel } from './MessageModel';
import { User } from './UserModel';

export interface GroupModel {
  id: string;
  name: string;
  description: string;
  type: string;
  createdAt: Date;
  updatedAt: Date;
  last_message: MessageModel
  message_count:number
  group_channel: group_channel;
}
export interface group_channel {
  id: string;
  groupId: string;
  channelId: string;
  createdAt: string;
  updatedAt: string;
}

export interface SingleGroupModel {
  senderId:string
  group: Group;
  members: Member[];
  messages: MessageModel[];
  pagination:pagination
}

export interface Group {
  id: string;
  name: string;
  description: string;
  type: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface Member {
  id: string;
  groupId: string;
  userProfileId: string;
  status: string;
  createdAt: Date;
  updatedAt: Date;
  UserProfile: UserProfile;
}

export interface UserProfile {
  id: string;
  userId: string;
  username: string;
  profile_pic: null;
  password: string;
  status: string;
  role_id: string;
  last_message_id: null;
  isOnline: boolean;
  device_id: null;
  device_token: string;
  platform: string;
  last_login: Date;
  channelId: null;
  createdAt: Date;
  updatedAt: Date;
  user: User;
}
