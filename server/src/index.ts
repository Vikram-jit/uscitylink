import express from "express";
import http from "http";
import cors from "cors";
import helmet from "helmet";
import dotenv from "dotenv";
import { initSocket } from "./sockets/socket";
import authRoutes from "./routes/authRoutes";
import { primarySequelize, secondarySequelize } from "./sequelize";
import { connectRedis } from "./redis";
import User from "./models/User";
import { UserProfile } from "./models/UserProfile";
import Role from "./models/Role";
import userRoutes from "./routes/userRoutes";
import channelRoutes from "./routes/channelRoutes";
import channelStaffRoutes from "./routes/staff/channelRoutes";
import mediaRoutes from "./routes/mediaRoutes";
import yardRoutes from "./routes/yardRoutes";
import trainingRoutes from "./routes/trainingRoutes";
import driverTrainingRoutes from "./routes/driverTrainingRoutes";
import templateRoutes from "./routes/templateRoutes";
import channelMemberRoutes from "./routes/channelMemberRoutes";
import groupRoutes from "./routes/groupRoutes";
import messageRoutes from "./routes/messageRoutes";
import messageV2Routes from "./routes/messageRoutesV2";
import chatRoutes from "./routes/staff/chatRoutes";
import staffChatRoutes from "./routes/staff/staffChatRoutes";
import staffGroupRoutes from "./routes/staff/groupRoutes";
import Channel from "./models/Channel";
import UserChannel from "./models/UserChannel";
import GroupChannel from "./models/GroupChannel";
import Group from "./models/Group";

import { verifyToken } from "./utils/jwt";
import GroupUser from "./models/GroupUser";
import { MessageStaff } from "./models/MessageStaff";
import path from "path";


dotenv.config();

const app = express();
const server = http.createServer(app);
const __root = path.resolve();


app.use(express.static("public"));

// Serve Flutter Web build correctly
app.use(
  "/app",
  express.static(path.join(__root, "public", "build"), {
    setHeaders: (res, path) => {
      if (path.endsWith(".js")) {
        res.setHeader("Content-Type", "application/javascript");
      }
      if (path.endsWith(".json")) {
        res.setHeader("Content-Type", "application/json");
      }
    }
  })
);

// SPA routing (important)
app.get("/app/*", (req, res) => {
  res.sendFile(path.join(__root, "public", "build", "index.html"));
});

app.set("view engine", "ejs");
app.set("views", "./views"); 

initSocket(server);

app.use(cors());
app.use(helmet());
app.use(express.json());
app.use(express.urlencoded({ limit: '100mb', extended: true }));



// Basic route
app.get("/:id", async (req, res) => {
  const decoded: any = verifyToken(req.params.id)
  const user = await UserProfile.findByPk(decoded?.id)
  res.send(user)
});

// Use authentication routes
app.use("/api/v1/auth", authRoutes);
app.use("/api/v1/user", userRoutes);
app.use("/api/v1/channel", channelRoutes);
app.use("/api/v1/group", groupRoutes);
app.use("/api/v1/channel/member", channelMemberRoutes);
app.use("/api/v1/message", messageRoutes);
app.use("/api/v1/messageV2", messageV2Routes);
app.use("/api/v1/media", mediaRoutes);
app.use("/api/v1/yard", yardRoutes);
app.use("/api/v1/trainings", trainingRoutes);
app.use("/api/v1/driver/trainings", driverTrainingRoutes);
app.use("/api/v1/template", templateRoutes);
app.use("/api/v1/staff/channel", channelStaffRoutes);
app.use("/api/v1/staff/chat", chatRoutes);
app.use("/api/v1/staff/groups", staffGroupRoutes);
app.use("/api/v1/staff/private/chat", staffChatRoutes);


// Start server
const PORT = process.env.PORT || 3000;
server.listen(PORT, async () => {
  await primarySequelize.authenticate();
  console.log("Connected to primary database.");

  await secondarySequelize.authenticate();
  console.log("Connected to secondary database.");

  await connectRedis();

  // Sync both databases
  await primarySequelize.sync(); // Use { force: false } to avoid dropping tables


  await secondarySequelize.sync(); // Use { force: false } to avoid dropping tables

  //Manage Relations


  User.associate({ UserProfile });
  UserProfile.associate({ User, Role,UserChannel,Channel,GroupUser,MessageStaff });
  Role.associate({ UserProfile });
  Channel.associate({ UserChannel,GroupChannel });
  UserChannel.associate({ UserProfile, Channel });

  Group.associate({ GroupChannel,GroupUser });
  GroupUser.associate({ UserProfile, Group });
  GroupChannel.associate({ Group, Channel });
  MessageStaff.associate({UserProfile})
  // UserChannel.belongsTo(Message, { foreignKey: 'lastMessageId', as: 'lastMessage' });
  // Message.hasMany(UserChannel, { foreignKey: 'lastMessageId', as: 'userChannels' });

  
  console.log("Secondary database & tables synced!");
  console.log(`Server is running on port ${PORT}`);


  
});
