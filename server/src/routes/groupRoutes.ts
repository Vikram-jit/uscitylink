import { Request, Response, Router } from "express";
import {
  create,
  get,
  getById,
  getMessagesByGroupId,
  groupAddMember,
  groupUpdate,
  groupRemoveMember,
  groupRemove,
  groupStatusMember,
} from "../controllers/groupController";
import { authMiddleware } from "../middleware/authMiddleware";
import { truckGroups } from "../controllers/truckChatController";
import Group from "../models/Group";
import { col, fn, literal, Op } from "sequelize";
import GroupChannel from "../models/GroupChannel";

const router = Router();

import { Message } from "../models/Message";
import { primarySequelize } from "../sequelize";

router.post(
  "/find-duplicate",
  async function (req: Request, res: Response): Promise<any> {
    const transaction = await primarySequelize.transaction();

    try {

      const duplicatesG = await Group.findAll({
        attributes: [
          "name",
          [fn("COUNT", col("name")), "total"],
          [fn("GROUP_CONCAT", col("id")), "group_ids"]
        ],
        group: ["name"],
        having: literal("COUNT(name) > 1"),
        raw: true
      });

      const results = [];

      for (const e of duplicatesG as any[]) {

        const groupIds = e.group_ids.split(",");

        const group_Channel = await GroupChannel.findAll({
          where: {
            groupId: {
              [Op.in]: groupIds
            }
          },
          transaction
        });

        // find valid group (exists in group_channels)
        const validGroupId = group_Channel[0]?.groupId;

        if (!validGroupId) continue;

        // duplicate groups
        const duplicateGroupIds = groupIds.filter(
          (id: string) => id !== validGroupId
        );

        // 1️⃣ move messages
        await Message.update(
          { groupId: validGroupId },
          {
            where: {
              groupId: {
                [Op.in]: duplicateGroupIds
              }
            },
            transaction
          }
        );

        // 2️⃣ delete duplicate groups
        await Group.destroy({
          where: {
            id: {
              [Op.in]: duplicateGroupIds
            }
          },
          transaction
        });

        results.push({
          name: e.name,
          keptGroup: validGroupId,
          removedGroups: duplicateGroupIds
        });
      }

      await transaction.commit();

      return res.json({
        message: "Duplicate groups cleaned",
        results
      });

    } catch (error) {
      await transaction.rollback();
      return res.status(500).json({ error });
    }
  }
);
router.post("/", authMiddleware, create);
router.get("/truck-groups", authMiddleware, truckGroups);
router.put("/:id", authMiddleware, groupUpdate);
router.delete("/:id", authMiddleware, groupRemove);
router.get("/messages/:id", authMiddleware, getMessagesByGroupId);

router.post("/member/:id", authMiddleware, groupAddMember);
router.put("/member/:id", authMiddleware, groupStatusMember);
router.delete("/member/:id", authMiddleware, groupRemoveMember);

router.get("/", authMiddleware, get);
router.get("/:id", authMiddleware, getById);
export default router;
