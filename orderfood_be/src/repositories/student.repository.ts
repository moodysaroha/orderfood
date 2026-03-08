import { PrismaClient, Student } from '@prisma/client';

export interface IStudentRepository {
  findById(id: string): Promise<Student | null>;
  findByUserId(userId: string): Promise<Student | null>;
  create(data: { userId: string; name: string }): Promise<Student>;
}

export class StudentRepository implements IStudentRepository {
  constructor(private prisma: PrismaClient) {}

  async findById(id: string): Promise<Student | null> {
    return this.prisma.student.findUnique({ where: { id } });
  }

  async findByUserId(userId: string): Promise<Student | null> {
    return this.prisma.student.findUnique({ where: { userId } });
  }

  async create(data: { userId: string; name: string }): Promise<Student> {
    return this.prisma.student.create({ data });
  }
}
