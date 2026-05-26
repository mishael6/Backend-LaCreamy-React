import jwt from 'jsonwebtoken';

export const generateUserToken = (userId) => {
  return jwt.sign({ id: userId, role: 'customer' }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });
};

export const generateAdminToken = (adminId) => {
  return jwt.sign({ id: adminId, role: 'admin' }, process.env.JWT_ADMIN_SECRET, {
    expiresIn: process.env.JWT_ADMIN_EXPIRES_IN || '1d',
  });
};

export const verifyUserToken = (token) => {
  return jwt.verify(token, process.env.JWT_SECRET);
};

export const verifyAdminToken = (token) => {
  return jwt.verify(token, process.env.JWT_ADMIN_SECRET);
};

