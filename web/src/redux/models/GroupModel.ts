export interface GroupModel {
  id:          string;
  name:        string;
  description: string;
  type:string
  createdAt:   Date;
  updatedAt:   Date;
}


export interface SingleGroupModel {
  group:    Group;
  members:  Member[];
  messages: any[];
}

export interface Group {
  id:          string;
  name:        string;
  description: string;
  type:        string;
  createdAt:   Date;
  updatedAt:   Date;
}

export interface Member {
  id:            string;
  groupId:       string;
  userProfileId: string;
  createdAt:     Date;
  updatedAt:     Date;
  UserProfile:   UserProfile;
}

export interface UserProfile {
  id:              string;
  userId:          string;
  username:        string;
  profile_pic:     null;
  password:        string;
  status:          string;
  role_id:         string;
  last_message_id: null;
  isOnline:        boolean;
  device_id:       null;
  device_token:    string;
  platform:        string;
  last_login:      Date;
  channelId:       null;
  createdAt:       Date;
  updatedAt:       Date;
}
