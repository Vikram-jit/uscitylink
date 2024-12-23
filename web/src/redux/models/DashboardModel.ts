import { MessageModel } from "./MessageModel";
import { User } from "./UserModel";

export interface DashboardModel {
    channelCount:   number;
    messageCount:   number;
    groupCount:     number;
    userUnMessage:  number;
    lastFiveDriver: User[];
    userUnReadMessage:MessageModel[]
}
