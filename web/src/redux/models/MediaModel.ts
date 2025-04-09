export interface MediaModel {
  channel:    null;
  media:      Media[];
  page:       number;
  limit:      number;
  totalItems: number;
  totalPages: number;
}

export interface Media {
  id:              string;
  channelId:       string;
  user_profile_id: string;
  groupId:         null;
  file_name:       string;
  file_type:       string;
  file_size:       string;
  mime_type:       string;
  key:             string;
  createdAt:       Date;
  updatedAt:       Date;
  thumbnail:string
}

export interface Welcome {
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

