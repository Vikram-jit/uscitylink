import { MessageModel } from "./MessageModel"

export interface StaffChatModel {
    id: string
    username: string
    chat_id: string
    senderCount: number
    reciverCount: number
    last_message?:MessageModel
    isCreatedBy?:boolean
  }