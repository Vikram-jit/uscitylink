export interface UserModel {
  id:              string;
  userId:          string;
  username:        string;
  profile_pic:     null;
  status:          null;
  role_id:         string;
  last_message_id: null;
  isOnline:        boolean;
  device_id:       null;
  device_token:    null;
  platform:        null;
  last_login:      null;
  createdAt:       Date;
  updatedAt:       Date;
  user:            User;
  role:            Role;
}

export interface Role {
  id:        string;
  name:      string;
  createdAt: Date;
  updatedAt: Date;
}

export interface User {
  id:           string;
  phone_number: null | string;
  email:        string;
  status:       string;
  createdAt:    Date;
  updatedAt:    Date;
  profiles? : UserModel[]
  driver_number:    null | string
}
