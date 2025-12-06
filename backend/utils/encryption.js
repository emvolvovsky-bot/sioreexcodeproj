const crypto = require('crypto');

const algorithm = 'aes-256-gcm';
const key = Buffer.from(process.env.ENCRYPTION_KEY, 'hex');

if (key.length !== 32) {
  console.warn('⚠️  ENCRYPTION_KEY should be 32 bytes (64 hex characters)');
}

function encrypt(text) {
  if (!text) return null;
  
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv(algorithm, key, iv);
  
  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  
  const authTag = cipher.getAuthTag();
  
  // Combine iv, authTag, and encrypted data
  return {
    encrypted,
    iv: iv.toString('hex'),
    authTag: authTag.toString('hex'),
  };
}

function decrypt(encryptedData) {
  if (!encryptedData || !encryptedData.encrypted) return null;
  
  try {
    const decipher = crypto.createDecipheriv(
      algorithm,
      key,
      Buffer.from(encryptedData.iv, 'hex')
    );
    
    decipher.setAuthTag(Buffer.from(encryptedData.authTag, 'hex'));
    
    let decrypted = decipher.update(encryptedData.encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    
    return decrypted;
  } catch (error) {
    console.error('Decryption error:', error);
    return null;
  }
}

// Helper to store encrypted data as JSON string in database
function encryptForStorage(text) {
  const encrypted = encrypt(text);
  return encrypted ? JSON.stringify(encrypted) : null;
}

// Helper to decrypt data from database JSON string
function decryptFromStorage(encryptedJson) {
  if (!encryptedJson) return null;
  try {
    const encrypted = JSON.parse(encryptedJson);
    return decrypt(encrypted);
  } catch (error) {
    return null;
  }
}

module.exports = {
  encrypt,
  decrypt,
  encryptForStorage,
  decryptFromStorage,
};



