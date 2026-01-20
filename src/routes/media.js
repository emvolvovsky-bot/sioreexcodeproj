import express from "express";
import multer from "multer";
import AWS from "aws-sdk";
import sharp from "sharp";
import { requireAuth } from "../middleware/auth.js";

const router = express.Router();

// Normalize paths to fix spaces (e.g., "/ upload" -> "/upload")
router.use((req, res, next) => {
  // Fix paths like "/ upload" that have a space after the slash
  if (req.path && req.path.includes(" ")) {
    const normalized = req.path.replace(/\s+/g, "");
    req.url = req.url.replace(req.path, normalized);
    console.log(`[Media] Normalized path from "${req.path}" to "${normalized}"`);
  }
  next();
});

// Protect all media endpoints
router.use(requireAuth);

// Multer in-memory storage keeps files out of disk and simplifies S3 upload
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB
  },
});

// AWS S3 client
const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION,
});

const buildFileName = (userId, originalName) => {
  const fileExtension = originalName.split(".").pop();
  const timestamp = Date.now();
  const randomString = Math.random().toString(36).substring(7);
  return `${userId}/${timestamp}-${randomString}.${fileExtension}`;
};

const uploadToS3 = async ({ key, body, contentType }) => {
  const params = {
    Bucket: process.env.S3_BUCKET_NAME,
    Key: key,
    Body: body,
    ContentType: contentType,
    // Note: ACL removed - bucket uses bucket policy for public access instead
  };

  const result = await s3.upload(params).promise();
  
  // Return the public URL (assumes bucket has public access policy)
  return {
    ...result,
    Location: `https://${process.env.S3_BUCKET_NAME}.s3.${process.env.AWS_REGION}.amazonaws.com/${key}`
  };
};

const singleUploadHandler = async (req, res) => {
  try {
    console.log("HIT /api/media/upload");

    if (!req.file) {
      return res.status(400).json({ error: "No file provided" });
    }

    const userId = req.user?.userId || req.user?.id;
    if (!userId) {
      return res.status(401).json({ error: "Unauthorized" });
    }
    // #region agent log
    fetch('http://127.0.0.1:7242/ingest/a26ee9fb-9a8b-4833-8f7f-13ddff24387c',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'src/routes/media.js:75',message:'media upload received file',data:{hasFile:!!req.file,fileSize:req.file?.size||0,mimeType:req.file?.mimetype||null},timestamp:Date.now(),sessionId:'debug-session',runId:'pre-fix',hypothesisId:'H4'})}).catch(()=>{});
    // #endregion agent log

    const key = buildFileName(userId, req.file.originalname || "upload.jpg");

    // Upload original file
    const uploadResult = await uploadToS3({
      key,
      body: req.file.buffer,
      contentType: req.file.mimetype,
    });
    // #region agent log
    fetch('http://127.0.0.1:7242/ingest/a26ee9fb-9a8b-4833-8f7f-13ddff24387c',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'src/routes/media.js:84',message:'media upload S3 result',data:{hasLocation:!!uploadResult?.Location,locationPrefix:uploadResult?.Location?uploadResult.Location.slice(0,40):null},timestamp:Date.now(),sessionId:'debug-session',runId:'pre-fix',hypothesisId:'H4'})}).catch(()=>{});
    // #endregion agent log

    // Generate thumbnail for images
    let thumbnailUrl = null;
    if (req.file.mimetype?.startsWith("image/")) {
      try {
        const thumbnailBuffer = await sharp(req.file.buffer)
          .resize(300, 300, { fit: "inside", withoutEnlargement: true })
          .jpeg({ quality: 80 })
          .toBuffer();

        const thumbnailKey = `thumbnails/${key}`;
        const thumbResult = await uploadToS3({
          key: thumbnailKey,
          body: thumbnailBuffer,
          contentType: "image/jpeg",
        });
        thumbnailUrl = thumbResult.Location;
      } catch (thumbErr) {
        console.error("Thumbnail generation error:", thumbErr);
      }
    }

    return res.json({
      url: uploadResult.Location,
      thumbnailUrl: thumbnailUrl || uploadResult.Location,
      fileSize: req.file.size,
      mimeType: req.file.mimetype,
    });
  } catch (err) {
    console.error("Upload error:", err);
    const errorMessage = err.message || "Failed to upload file";
    return res.status(500).json({ error: `Upload failed: ${errorMessage}` });
  }
};

// Primary upload endpoint
router.post("/upload", upload.single("file"), singleUploadHandler);

// Multiple files upload endpoint
router.post("/upload-multiple", upload.array("files", 10), async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ error: "No files provided" });
    }

    const userId = req.user?.userId || req.user?.id;
    if (!userId) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    const results = await Promise.all(
      req.files.map(async (file) => {
        const key = buildFileName(userId, file.originalname || "upload.jpg");
        const uploadResult = await uploadToS3({
          key,
          body: file.buffer,
          contentType: file.mimetype,
        });

        let thumbnailUrl = null;
        if (file.mimetype?.startsWith("image/")) {
          try {
            const thumbnailBuffer = await sharp(file.buffer)
              .resize(300, 300, { fit: "inside", withoutEnlargement: true })
              .jpeg({ quality: 80 })
              .toBuffer();

            const thumbnailKey = `thumbnails/${key}`;
            const thumbResult = await uploadToS3({
              key: thumbnailKey,
              body: thumbnailBuffer,
              contentType: "image/jpeg",
            });
            thumbnailUrl = thumbResult.Location;
          } catch (thumbErr) {
            console.error("Thumbnail generation error (multiple):", thumbErr);
          }
        }

        return {
          url: uploadResult.Location,
          thumbnailUrl: thumbnailUrl || uploadResult.Location,
          fileSize: file.size,
          mimeType: file.mimetype,
        };
      })
    );

    return res.json({ urls: results });
  } catch (err) {
    console.error("Multiple upload error:", err);
    return res.status(500).json({ error: "Failed to upload files" });
  }
});

export default router;




