import { Group, GroupModel, SingleGroupModel } from '@/redux/models/GroupModel';
import { MessageModel } from '@/redux/models/MessageModel';
import { SetStateAction } from 'react';

export interface User {
  id: string;
  name: string;
  avatar: string;
  status?: 'online' | 'offline' | 'away';
  lastSeen?: string;
  unreadCount?: number;
}

export interface Message {
  id: string | number;
  sender: string;
  text: string;
  time: string;
  status?: 'sent' | 'delivered' | 'read';
}

export interface Chat {
  id: string;
  user: User;
  lastMessage?: Message;
  unreadCount: number;
  messages: Message[];
}

export interface ChatViewProps {
  currentChatId?: string;
  currentUser: SingleGroupModel | undefined;
  messages: MessageModel[];
  currentChat?: Chat;
  onSelectChat: (chatId: string) => void;
  onSendMessage: (message: string) => void;
  isLoading?: boolean;
  error?: string;
  trucks?: GroupModel[];
  hasMoreMessage: boolean;
  loadMoreGroupMessages: () => void;
  messageLoader?: boolean;
  viewMedia: boolean;
  setViewMedia: React.Dispatch<React.SetStateAction<boolean>>;
  handleReset: () => void;
  isBack: boolean;
  viewDetailGroup: boolean;
  setViewDetailGroup: React.Dispatch<SetStateAction<boolean>>;
  setCurrentChatId:React.Dispatch<SetStateAction<string | undefined>>;
  setGroups?: React.Dispatch<SetStateAction<GroupModel[]>>;
  handleFileChangeVedio?: any;
  handleVedioClick?:any;
  selectedTemplate?: { name: string; body: string; url?: string };
  setSelectedTemplate?: React.Dispatch<SetStateAction<{ name: string; body: string; url?: string }>>;
  message: string;
  setMessage: React.Dispatch<SetStateAction<string>>;
    search: string;
    setSearch: React.Dispatch<React.SetStateAction<string>>;
    setSelectedGroup: React.Dispatch<React.SetStateAction<string>>;
     loadMoreMessages: () => void;
        hasMore?: boolean;
        setPage?: React.Dispatch<React.SetStateAction<number>>;
        handleFileChange:any
}
