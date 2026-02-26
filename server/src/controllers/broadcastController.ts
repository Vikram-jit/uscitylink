import { Response, Request } from "express";
import BroadcastMessage from "../models/BroadcastMessage";
import { primarySequelize } from "../sequelize";
import { broadcastMessageToDriver } from "../sockets/messageHandler";
import { getSocketInstance } from "../sockets/socket";

export async function processBroadcastJobs(
  req: Request,
  res: Response
): Promise<any> {
  try {

    // 1️⃣ Prevent overlapping execution
    const processingCount = await BroadcastMessage.count({
      where: { status: "processing" },
    });

    if (processingCount > 0) {
      return res.status(200).json({
        status: true,
        message: "Another batch is already processing",
      });
    }

    // 2️⃣ Lock & fetch pending jobs safely
    const jobs = await primarySequelize.transaction(async (t) => {

      const pendingJobs = await BroadcastMessage.findAll({
        where: { status: "pending" },
        limit: 10,
        order: [["createdAt", "ASC"]],
        lock: true,
        skipLocked: true,
        transaction: t,
      });

      if (pendingJobs.length === 0) return [];

      await BroadcastMessage.update(
        { status: "processing" },
        {
          where: { id: pendingJobs.map((j) => j.id) },
          transaction: t,
        }
      );

      return pendingJobs;
    });

    if (!jobs || jobs.length === 0) {
      return res.status(200).json({
        status: true,
        message: "No pending broadcast jobs",
      });
    }

    const io = getSocketInstance();
    let processedCount = 0;

    // 3️⃣ Process outside transaction
    for (const job of jobs) {
      try {
        await broadcastMessageToDriver(
          io,
          job.sender_id,
          job.user_id,
          job.body,
          job.url
        );

        await job.update({ status: "sent" });
        processedCount++;

      } catch (err) {
        await job.update({ status: "failed" });
        console.error(`Failed job ${job.id}:`, err);
      }
    }

    return res.status(200).json({
      status: true,
      message: "Broadcast batch processed",
      processed: processedCount,
    });

  } catch (error) {
    console.error("Broadcast job error:", error);
    return res.status(500).json({
      status: false,
      message: "Server error",
    });
  }
}
