const express = require('express');
const multer = require('multer');
const AWS = require('aws-sdk');
const sharp = require('sharp');
const { authenticate } = require('../middleware/auth');

const router = express.Router();
router.use(authenticate);

// Configure multer for memory storage
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB
  },
});

// Configure AWS S3
const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION,
});

// POST /api/media/upload
router.post('/upload', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file provided' });
    }
    
    const file = req.file;
    const userId = req.user.id;
    
    // Generate unique filename
    const fileExtension = file.originalname.split('.').pop();
    const timestamp = Date.now();
    const randomString = Math.random().toString(36).substring(7);
    const fileName = `${userId}/${timestamp}-${randomString}.${fileExtension}`;
    
    // Upload original
    const uploadParams = {
      Bucket: process.env.S3_BUCKET_NAME,
      Key: fileName,
      Body: file.buffer,
      ContentType: file.mimetype,
      ACL: 'public-read',
    };
    
    const uploadResult = await s3.upload(uploadParams).promise();
    
    // Generate thumbnail if image
    let thumbnailUrl = null;
    if (file.mimetype.startsWith('image/')) {
      try {
        const thumbnail = await sharp(file.buffer)
          .resize(300, 300, { fit: 'inside', withoutEnlargement: true })
          .jpeg({ quality: 80 })
          .toBuffer();
        
        const thumbnailKey = `thumbnails/${fileName}`;
        await s3.upload({
          ...uploadParams,
          Key: thumbnailKey,
          Body: thumbnail,
          ContentType: 'image/jpeg',
        }).promise();
        
        thumbnailUrl = `https://${process.env.S3_BUCKET_NAME}.s3.${process.env.AWS_REGION}.amazonaws.com/${thumbnailKey}`;
      } catch (error) {
        console.error('Thumbnail generation error:', error);
        // Continue without thumbnail
      }
    }
    
    res.json({
      url: uploadResult.Location,
      thumbnailUrl: thumbnailUrl || uploadResult.Location,
      fileSize: file.size,
      mimeType: file.mimetype,
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ error: 'Failed to upload file' });
  }
});

// POST /api/media/upload-multiple
router.post('/upload-multiple', upload.array('files', 10), async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ error: 'No files provided' });
    }
    
    const userId = req.user.id;
    const uploadPromises = req.files.map(async (file) => {
      const fileExtension = file.originalname.split('.').pop();
      const timestamp = Date.now();
      const randomString = Math.random().toString(36).substring(7);
      const fileName = `${userId}/${timestamp}-${randomString}.${fileExtension}`;
      
      const uploadParams = {
        Bucket: process.env.S3_BUCKET_NAME,
        Key: fileName,
        Body: file.buffer,
        ContentType: file.mimetype,
        ACL: 'public-read',
      };
      
      const uploadResult = await s3.upload(uploadParams).promise();
      
      let thumbnailUrl = null;
      if (file.mimetype.startsWith('image/')) {
        try {
          const thumbnail = await sharp(file.buffer)
            .resize(300, 300, { fit: 'inside' })
            .jpeg({ quality: 80 })
            .toBuffer();
          
          const thumbnailKey = `thumbnails/${fileName}`;
          await s3.upload({
            ...uploadParams,
            Key: thumbnailKey,
            Body: thumbnail,
            ContentType: 'image/jpeg',
          }).promise();
          
          thumbnailUrl = `https://${process.env.S3_BUCKET_NAME}.s3.${process.env.AWS_REGION}.amazonaws.com/${thumbnailKey}`;
        } catch (error) {
          // Continue without thumbnail
        }
      }
      
      return {
        url: uploadResult.Location,
        thumbnailUrl: thumbnailUrl || uploadResult.Location,
        fileSize: file.size,
        mimeType: file.mimetype,
      };
    });
    
    const results = await Promise.all(uploadPromises);
    
    res.json({ urls: results });
  } catch (error) {
    console.error('Multiple upload error:', error);
    res.status(500).json({ error: 'Failed to upload files' });
  }
});

module.exports = router;



