import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import prisma from '../config/database';
import { JwtPayload, AuthenticatedUser } from '../types';
import { Role } from '@prisma/client';
import { AppError } from './error.middleware';

export async function authenticate(
  req: Request,
  _res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      throw new AppError(401, 'Missing or invalid authorization header');
    }

    const token = authHeader.substring(7);
    const decoded = jwt.verify(token, env.JWT_SECRET) as JwtPayload;

    const user: AuthenticatedUser = {
      userId: decoded.userId,
      role: decoded.role,
    };

    if (decoded.role === Role.VENDOR) {
      const vendor = await prisma.vendor.findUnique({
        where: { userId: decoded.userId },
      });
      if (vendor) user.vendorId = vendor.id;
    } else if (decoded.role === Role.STUDENT) {
      const student = await prisma.student.findUnique({
        where: { userId: decoded.userId },
      });
      if (student) user.studentId = student.id;
    } else if (decoded.role === Role.ADMIN) {
      const admin = await prisma.admin.findUnique({
        where: { userId: decoded.userId },
      });
      if (admin) user.adminId = admin.id;
    }

    req.user = user;
    next();
  } catch (err) {
    if (err instanceof AppError) {
      next(err);
      return;
    }
    next(new AppError(401, 'Invalid or expired token'));
  }
}

export function requireRole(...roles: Role[]) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    if (!req.user) {
      next(new AppError(401, 'Authentication required'));
      return;
    }
    if (!roles.includes(req.user.role)) {
      next(new AppError(403, 'Insufficient permissions'));
      return;
    }
    next();
  };
}
