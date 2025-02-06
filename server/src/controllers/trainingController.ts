import { Request, Response } from "express";
import multer from "multer";
import AWS from "aws-sdk";
import fs from "fs";
import dotenv from "dotenv";
import ffmpeg from "fluent-ffmpeg";
import path from "path";
import { Training } from "../models/Training";
dotenv.config();
import { getVideoDurationInSeconds } from "get-video-duration";
import { Question } from "../models/Question";
import { QuestionOption } from "../models/QuestionOption";
import { TrainingDriver } from "../models/TrainingDriver";
import { UserProfile } from "../models/UserProfile";
import User from "../models/User";
import { Op, where } from "sequelize";
import { TrainingDriverQuestions } from "../models/TrainingDriverQuestion";
import Queue from "bull";
import { sendNotificationToDevice } from "../utils/fcmService";

AWS.config.update({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID || "",
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || "",
  region: "us-west-1",
});

const trainingNotificationQueue = new Queue("trainingNotificationQueue", {
  redis: {
    host: "127.0.0.1", // Redis host
    port: 6379, // Custom Redis port
  },
});

trainingNotificationQueue.process(async (job: any) => {
  const { title, userId, id ,training} = job.data;
console.log("hello Queue");
  const users = await UserProfile.findAll({
    where: {
      id: userId,
      device_token: {
        [Op.ne]: null,
      },
    },
  });
  
  await Promise.all(
    users.map(async (user) => {
      if (user) {
        const deviceToken = user.device_token;
        if (deviceToken) {
       
          // await sendNotificationToDevice(deviceToken, {
          //   title: `Add New Training Video`,
          //   badge: 0,
          //   body: title,
          //   data: {
          //     type: "TRAINING_VIDEO",
          //     title: "Add New Training Video",
          //     // id: id,
          //     // training: training,
          //   },
          // });
        }
      }
    })
  );
});

// Optional: Handle failed jobs
trainingNotificationQueue.on("failed", (job, err) => {
  console.log(`Job failed: ${job.id}, Error: ${err}`);
});

const s3 = new AWS.S3();
const storage = multer.memoryStorage();

const upload = multer({ storage });
const initiateMultipartUpload = async (fileName: string): Promise<string> => {
  const params = {
    Bucket: "ciity-sms",
    Key: fileName,
  };

  const response = await s3.createMultipartUpload(params).promise();
  return response.UploadId!;
};

const uploadPart = (
  params: AWS.S3.UploadPartRequest,
  partNumber: number,
  chunkSize: number,
  progressCallback: (uploadedBytesInPart: number) => void
): Promise<AWS.S3.CompletedPart> => {
  return new Promise((resolve, reject) => {
    s3.uploadPart(params, (err, data) => {
      if (err) {
        return reject(err);
      }
      progressCallback(chunkSize);
      resolve({ ETag: data.ETag!, PartNumber: partNumber });
    });
  });
};

const completeMultipartUpload = async (
  uploadId: string,
  uploadedParts: AWS.S3.CompletedPart[],
  fileName: string
): Promise<AWS.S3.CompleteMultipartUploadOutput> => {
  const params = {
    Bucket: "ciity-sms",
    Key: fileName,
    UploadId: uploadId,
    MultipartUpload: {
      Parts: uploadedParts,
    },
  };

  const response = await s3.completeMultipartUpload(params).promise();
  return response;
};

export const createTraining = async (
  req: Request,
  res: Response
): Promise<any> => {
  try {
    if (!req.file) {
      throw new Error("No file uploaded");
    }
    let training: any;
    let thumbnail_data: any;
    const file = req.file;
    const fileName = `uscitylink/trainings/${Date.now().toString()}-${
      file.originalname
    }`;
    const fileSize = file.size;
    const chunkSize = 5 * 1024 * 1024; // 5MB chunks
    const totalChunks = Math.ceil(fileSize / chunkSize);

    if (fileSize < 5 * 1024 * 1024) {
      const params = {
        Bucket: "ciity-sms",
        Key: fileName,
        Body: file.buffer,
      };

      const managedUpload = s3.upload(params);

      const result: any = await managedUpload.promise();

      if (result) {
        const nameT = `${Date.now()}_thumbnail.png`;
        const thumbnailPath = path.join(__dirname, "../../", "uploads", nameT);

        const generatedThumbnailPath: any = await generateThumbnail(
          result?.Location,
          thumbnailPath,
          nameT
        );
        // const duration: any = await getVideoDuration(result?.Location);
        const uploadResult = await uploadToS3(
          generatedThumbnailPath,
          "ciity-sms",
          `uscitylink/trainings/${Date.now()}_thumbnail.png`
        );

        thumbnail_data = uploadResult;

        fs.unlinkSync(generatedThumbnailPath);

        training = await Training.create({
          title: req.body.title,
          description: req.body.title,
          file_name: req.file?.originalname,
          file_size: req.file.size,
          mime_type: req.file.mimetype,
          key: result?.key,
          file_type: req.body.type,
          thumbnail: thumbnail_data?.Key,
          duration: 0,
        });
      }
      return res.status(201).json({
        status: true,
        message: "File uploaded successfully",
        data: {
          ...result,
          thumbnail: thumbnail_data?.Key,
          ...training.dataValues,
        },
      });
    }

    // Step 1: Initiate the multipart upload
    const uploadId = await initiateMultipartUpload(fileName);

    const uploadPromises: Promise<AWS.S3.CompletedPart>[] = [];
    let uploadedBytes = 0;

    const updateProgress = (uploadedBytes: number) => {
      const progress = (uploadedBytes / fileSize) * 100;
      let progressPercentage = Math.floor(progress);

      if (progressPercentage > 100) progressPercentage = 100;

      console.log(`Upload progress: ${progressPercentage}%`);
    };

    // Step 2: Split the file into 5MB chunks and upload each part
    for (let chunkIndex = 0; chunkIndex < totalChunks; chunkIndex++) {
      const start = chunkIndex * chunkSize;
      const end = Math.min(start + chunkSize, fileSize);
      const chunkBuffer = file.buffer.slice(start, end);

      const params: AWS.S3.UploadPartRequest = {
        Bucket: "ciity-sms",
        Key: fileName,
        PartNumber: chunkIndex + 1,
        UploadId: uploadId,
        Body: chunkBuffer,
      };

      uploadPromises.push(
        uploadPart(
          params,
          chunkIndex + 1,
          chunkBuffer.length,
          (uploadedBytesInPart) => {
            uploadedBytes += uploadedBytesInPart;
            updateProgress(uploadedBytes);
          }
        )
      );
    }

    const uploadedParts = await Promise.all(uploadPromises);

    const result: any = await completeMultipartUpload(
      uploadId,
      uploadedParts,
      fileName
    );
    if (result) {
      const nameT = `${Date.now()}_thumbnail.png`;
      const thumbnailPath = path.join(__dirname, "../../", "uploads", nameT);

      const generatedThumbnailPath: any = await generateThumbnail(
        result?.Location,
        thumbnailPath,
        nameT
      );
      // const duration: any = await getVideoDuration(result?.Location);

      const uploadResult = await uploadToS3(
        generatedThumbnailPath,
        "ciity-sms",
        `uscitylink/trainings/${Date.now()}_thumbnail.png`
      );

      thumbnail_data = uploadResult;

      fs.unlinkSync(generatedThumbnailPath);

      training = await Training.create({
        title: req.body.title,
        description: req.body.title,
        file_name: req.file?.originalname,
        file_size: req.file.size,
        mime_type: req.file.mimetype,
        key: result?.key,
        file_type: req.body.type,
        thumbnail: thumbnail_data?.Key,
        duration: 0,
      });
    }
    return res.status(201).json({
      status: true,
      message: "File uploaded successfully",
      data: {
        ...result,
        thumbnail: thumbnail_data?.Key,
        ...training.dataValues,
      },
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
};

export const uploadAwsMiddleware = upload.single("file");

function generateThumbnail(
  videoUrl: string,
  thumbnailPath: string,
  nameT: string
) {
  return new Promise((resolve, reject) => {
    ffmpeg(videoUrl)
      .screenshots({
        timestamps: [1],
        filename: nameT,
        folder: path.dirname(thumbnailPath),
        size: "320x240",
      })
      .on("end", () => {
        console.log("Thumbnail generated successfully.");
        resolve(thumbnailPath);
      })
      .on("error", (err) => {
        console.error("Error generating thumbnail:", err);
        reject(new Error("Error generating thumbnail."));
      });
  });
}

function getVideoDuration(videoUrl: string): Promise<number> {
  return new Promise((resolve, reject) => {
    getVideoDurationInSeconds(videoUrl)
      .then((v) => {
        resolve(v);
      })
      .catch(() => {
        reject(new Error("Error getting video metadata."));
      });
  });
}

function uploadToS3(filePath: string, bucketName: string, s3Key: string) {
  return new Promise((resolve, reject) => {
    const fileContent = fs.readFileSync(filePath);
    const params = {
      Bucket: bucketName,
      Key: s3Key,
      Body: fileContent,
      ContentType: "image/png", // Assuming PNG thumbnail
    };

    s3.upload(params, (uploadError: any, uploadResult: any) => {
      if (uploadError) {
        console.error("Error uploading thumbnail to S3:", uploadError);
        reject(new Error("Error uploading thumbnail to S3."));
      } else {
        console.log("Thumbnail uploaded to S3:", uploadResult.Location);
        resolve(uploadResult); // Resolve with the S3 upload result
      }
    });
  });
}

export async function getAllTrainings(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const pageSize = parseInt(req.query.pageSize as string) || 10;

    const search = (req.query.search as string) || "";

    const offset = (page - 1) * pageSize;

    const trainings = await Training.findAndCountAll({
      include: [
        {
          model: Question,
          as: "questions",
          include: [{ model: QuestionOption, as: "options" }],
        },
      ],
      limit: pageSize,
      offset: offset,
    });
    const total = trainings.count;
    const totalPages = Math.ceil(total / pageSize);

    return res.status(200).json({
      status: true,
      message: `Get Training Successfully.`,
      data: {
        data: trainings.rows,
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

export async function getTrainingById(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const user = await Training.findByPk(req.params.id, {
      include: [
        {
          model: Question,
          as: "questions",
          include: [{ model: QuestionOption, as: "options" }],
        },
        { model: TrainingDriver, as: "assgin_drivers" },
      ],
    });
    return res.status(200).json({
      status: true,
      message: `Get Training Successfully.`,
      data: user,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function addQutionsTrainingVideo(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const training = await Training.findByPk(req.params.id, {
      include: [
        {
          model: Question,
          as: "questions",
          include: [{ model: QuestionOption, as: "options" }],
        },
        { model: TrainingDriver, as: "assgin_drivers" },
      ],
    });
    if (training) {
      await Promise.all(
        req.body.questions.map(async (item: any) => {
          if (item?.isDeleted) {
            await QuestionOption.destroy({
              where: {
                questionId: item.id,
              },
            });
            await Question.destroy({
              where: {
                id: item.id,
              },
            });
          } else {
            const isCheck = await Question.findByPk(item.id);
            if (!isCheck) {
              const question = await Question.create({
                tainingId: training.id,
                question: item.text,
              });
              if (question) {
                await Promise.all(
                  item.options.map(async (el: any) => {
                    await QuestionOption.create({
                      questionId: question.id,
                      option: el.text,
                      isCorrect: el.isCorrect,
                    });
                  })
                );
              }
            }
          }
        })
      );

      await Promise.all(
        req.body.removedDrivers.map(async (el: string) => {
          await TrainingDriver.destroy({
            where: {
              tainingId: training.id,
              driverId: el,
            },
          });
        })
      );

      await Promise.all(
        req.body.drivers.map(async (el: string) => {
          const isCheck = await TrainingDriver.findOne({
            where: {
              tainingId: training.id,
              driverId: el,
            },
          });
          console.log(isCheck)
          if (!isCheck) {
            const td = await TrainingDriver.create({
              tainingId: training.id,
              driverId: el,
            });
            const trainingDriver = await TrainingDriver.findByPk(td.id, {
              include: [
                {
                  model: Training,
                  as: "trainings",
                },
              ],
            });
           
            console.log({ id: td.id,
              training: JSON.stringify(trainingDriver?.dataValues),})
           await trainingNotificationQueue.add({
              title: training.dataValues.title,
              userId: el,
              id: td.id,
              training: JSON.stringify(trainingDriver?.dataValues),
            });
          }
        })
      );
    }

    return res.status(200).json({
      status: true,
      message: `Add questions Successfully.`,
      data: training,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function getAssginVideos(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const id = req.user?.id;
    const page = parseInt(req.query.page as string) || 1;
    const pageSize = parseInt(req.query.pageSize as string) || 10;

    const search = (req.query.search as string) || "";

    const offset = (page - 1) * pageSize;

    const trainingDriver = await TrainingDriver.findAndCountAll({
      where: {
        driverId: id,
      },
      include: [
        {
          model: Training,
          as: "trainings",
        },
      ],
      limit: pageSize,
      offset: offset,
    });
    const total = trainingDriver.count;
    const totalPages = Math.ceil(total / pageSize);

    return res.status(200).json({
      status: true,
      message: `Get Assgin Drivers Successfully.`,
      data: {
        data: trainingDriver.rows,
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

export async function getAssginDrivers(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const id = req.params.id;
    const page = parseInt(req.query.page as string) || 1;
    const pageSize = parseInt(req.query.pageSize as string) || 10;

    const search = (req.query.search as string) || "";

    const offset = (page - 1) * pageSize;

    const training = await Training.findByPk(id);

    const trainingDriver = await TrainingDriver.findAndCountAll({
      where: {
        tainingId: id,
      },
      include: [
        {
          model: UserProfile,
          as: "user_profiles",
          include: [
            {
              model: User,
              as: "user",
            },
          ],
        },
      ],
      limit: pageSize,
      offset: offset,
    });
    const total = trainingDriver.count;
    const totalPages = Math.ceil(total / pageSize);

    return res.status(200).json({
      status: true,
      message: `Get Assgin Drivers Successfully.`,
      data: {
        data: { training, drivers: trainingDriver.rows },
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

export async function updateVideoStatusWithDuration(
  req: Request,
  res: Response
): Promise<any> {
  try {
    await TrainingDriver.update(
      {
        view_duration: req.body.view_duration,
        isCompleteWatch: req.body.isCompleteWatch,
      },
      {
        where: {
          id: req.params.id,
        },
      }
    );
    if (req.body.isCompleteWatch) {
      await TrainingDriver.update(
        {
          quiz_status: "pending",
        },
        {
          where: {
            id: req.params.id,
          },
        }
      );
    }

    return res.status(200).json({
      status: true,
      message: `Updated Successfully.`,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function getTrainingQuestions(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const training = await Training.findByPk(req.params.id, {
      include: [
        {
          model: Question,
          as: "questions",
          include: [
            {
              model: QuestionOption,
              as: "options",
            },
          ],
        },
      ],
    });

    return res.status(200).json({
      status: true,
      message: `Get Question Successfully.`,
      data: training,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function quizAnswerSubmit(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const data: Record<string, string[]> = req.body.data;

    const totalQuestion = await Question.count({
      where: {
        tainingId: req.params.id,
      },
    });

    let givenAnswerCount: number = 0;
    let correctAnswerCount: number = 0;
    let quiz_status: string = "";
    for (const [questionId, optionId] of Object.entries(data)) {
      if (optionId.length > 0) {
        const isOldAnswer = await TrainingDriverQuestions.findOne({
          where: {
            tainingId: req.params.id,
            driverId: req.user?.id,
            questionId: questionId,
          },
        });
        if (isOldAnswer) {
          await TrainingDriverQuestions.update(
            {
              selectedOptionId: optionId?.[0],
            },
            {
              where: {
                tainingId: req.params.id,
                driverId: req.user?.id,
                questionId: questionId,
              },
            }
          );
        } else {
          await TrainingDriverQuestions.create({
            tainingId: req.params.id,
            driverId: req.user?.id,
            questionId: questionId,
            selectedOptionId: optionId?.[0],
          });
        }

        const isOption = await QuestionOption.findByPk(optionId?.[0]);

        if (isOption) {
          if (isOption.isCorrect) {
            correctAnswerCount = correctAnswerCount + 1;
          }
        }

        givenAnswerCount = givenAnswerCount + 1;
      }
    }

    if (givenAnswerCount == totalQuestion) {
      await TrainingDriver.update(
        {
          quiz_status: "passed",
        },
        {
          where: {
            tainingId: req.params.id,
            driverId: req.user?.id,
          },
        }
      );
      quiz_status = "passed";
    } else {
      await TrainingDriver.update(
        {
          quiz_status: "failed",
          view_duration: null,
          isCompleteWatch: false,
        },
        {
          where: {
            tainingId: req.params.id,
            driverId: req.user?.id,
          },
        }
      );
      quiz_status = "failed";
    }

    if (givenAnswerCount == correctAnswerCount) {
      await TrainingDriver.update(
        {
          quiz_status: "passed",
        },
        {
          where: {
            tainingId: req.params.id,
            driverId: req.user?.id,
          },
        }
      );
      quiz_status = "passed";
    } else {
      await TrainingDriver.update(
        {
          quiz_status: "failed",
          view_duration: null,
          isCompleteWatch: false,
        },
        {
          where: {
            tainingId: req.params.id,
            driverId: req.user?.id,
          },
        }
      );
      quiz_status = "failed";
    }

    return res.status(200).json({
      status: true,
      message: `Submitted Successfully.`,
      data: quiz_status,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}
