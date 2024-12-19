import { Request, Response } from "express";
import { Template } from "../models/Template";
import { Op } from "sequelize";

export async function create(req: Request, res: Response): Promise<any> {
  try {
    const { name, body, url } = req.body;

    await Template.create({
      user_profile_id: req.user?.id,
      channelId: req.activeChannel,
      name: name,
      body: body,
      url: url,
    });

    return res.status(201).json({
      status: true,
      message: `Template Created Successfully.`,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function get(req: Request, res: Response): Promise<any> {
  try {

    const source = req.query.source || "pagination"

    const page = parseInt(req.query.page as string) || 1;
    const pageSize = parseInt(req.query.pageSize as string) || 10;

    const search = (req.query.search as string) || "";

    const offset = (page - 1) * pageSize;

    const result = await Template.findAndCountAll({
      where: {
        channelId: req.activeChannel,
       ...(source == "paginationWithSearch" && {name: {
        [Op.like]: `%${search}%`,
      },}) 
      },

      ...(source == "pagination" && {
        limit: pageSize,
        offset: offset
      })

    });
    const total = result.count;
    const totalPages = Math.ceil(total / pageSize);

    return res.status(200).json({
      status: true,
      message: `Template fetched Successfully.`,
      data: {
        data: result.rows,
        pagination: {
          currentPage: page,
          pageSize: pageSize,
          total,
          totalPages,
        },
      },
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function deleteTemplate(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const { id } = req.params;

    await Template.destroy({
      where: {
        id: id,
      },
    });

    return res.status(201).json({
      status: true,
      message: `Template Created Successfully.`,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function getById(req: Request, res: Response): Promise<any> {
  try {
    const { id } = req.params;
    const result = await Template.findByPk(id);

    return res.status(200).json({
      status: true,
      message: `Template fetched Successfully.`,
      data: result,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function update(req: Request, res: Response): Promise<any> {
  try {

    const { id } = req.params;
    const { name, body, url } = req.body;

    await Template.update({
      name: name,
      body: body,
      url: url,
    }, {
      where: {
        id: id
      }
    });

    return res.status(200).json({
      status: true,
      message: `Template updated Successfully.`,

    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

