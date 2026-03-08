import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { Role } from '@prisma/client';
import { env } from '../config/env';
import { IUserRepository } from '../repositories/user.repository';
import { IVendorRepository } from '../repositories/vendor.repository';
import { IStudentRepository } from '../repositories/student.repository';
import { JwtPayload } from '../types';
import { AppError } from '../middleware';

interface RegisterInput {
  email: string;
  password: string;
  role: Role;
  name?: string;
  restaurantName?: string;
  description?: string;
}

interface LoginInput {
  email: string;
  password: string;
}

interface AuthResult {
  token: string;
  user: { id: string; email: string; role: Role };
}

export interface IAuthService {
  register(input: RegisterInput): Promise<AuthResult>;
  login(input: LoginInput): Promise<AuthResult>;
  getProfile(userId: string): Promise<Record<string, unknown>>;
}

export class AuthService implements IAuthService {
  constructor(
    private userRepo: IUserRepository,
    private vendorRepo: IVendorRepository,
    private studentRepo: IStudentRepository,
  ) {}

  async register(input: RegisterInput): Promise<AuthResult> {
    const existing = await this.userRepo.findByEmail(input.email);
    if (existing) {
      throw new AppError(409, 'Email already registered');
    }

    if (input.role === Role.VENDOR && !input.restaurantName) {
      throw new AppError(400, 'Restaurant name is required for vendor registration');
    }
    if (input.role === Role.STUDENT && !input.name) {
      throw new AppError(400, 'Name is required for student registration');
    }

    const passwordHash = await bcrypt.hash(input.password, 12);
    const user = await this.userRepo.create({
      email: input.email,
      passwordHash,
      role: input.role,
    });

    if (input.role === Role.VENDOR) {
      await this.vendorRepo.create({
        userId: user.id,
        restaurantName: input.restaurantName!,
        description: input.description,
      });
    } else {
      await this.studentRepo.create({
        userId: user.id,
        name: input.name!,
      });
    }

    const token = this.generateToken(user.id, user.role);
    return { token, user: { id: user.id, email: user.email, role: user.role } };
  }

  async login(input: LoginInput): Promise<AuthResult> {
    const user = await this.userRepo.findByEmail(input.email);
    if (!user) {
      throw new AppError(401, 'Invalid email or password');
    }

    const isValid = await bcrypt.compare(input.password, user.passwordHash);
    if (!isValid) {
      throw new AppError(401, 'Invalid email or password');
    }

    const token = this.generateToken(user.id, user.role);
    return { token, user: { id: user.id, email: user.email, role: user.role } };
  }

  async getProfile(userId: string): Promise<Record<string, unknown>> {
    const user = await this.userRepo.findById(userId);
    if (!user) throw new AppError(404, 'User not found');

    const base = { id: user.id, email: user.email, role: user.role, createdAt: user.createdAt };

    if (user.role === Role.VENDOR) {
      const vendor = await this.vendorRepo.findByUserId(userId);
      return { ...base, vendor };
    }

    const student = await this.studentRepo.findByUserId(userId);
    return { ...base, student };
  }

  private generateToken(userId: string, role: Role): string {
    const payload: JwtPayload = { userId, role };
    return jwt.sign(payload, env.JWT_SECRET, { expiresIn: env.JWT_EXPIRES_IN } as jwt.SignOptions);
  }
}
