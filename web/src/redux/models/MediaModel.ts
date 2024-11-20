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
}
